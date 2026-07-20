import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

import '../config/api_config.dart';
import '../models/claim_result.dart';
import '../models/customer.dart';
import '../models/principal.dart';
import '../models/review.dart';
import '../models/shop.dart';
import '../models/shop_detail.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);

  @override
  String toString() => message;
}

/// Thin wrapper around the StorePass FastAPI backend. Auth is a signed,
/// httpOnly session cookie (no JWT) — [CookieManager] persists it to disk via
/// [PersistCookieJar] so a login survives an app restart, mirroring the
/// browser's `credentials: include` behavior on the React frontend.
class ApiClient {
  final ApiConfig config;
  // Without explicit timeouts, an unreachable backend (wrong URL, server
  // down, no network) hangs the request forever — during app startup that
  // means the splash screen never resolves. Bounded timeouts guarantee
  // restore() always finishes one way or another.
  //
  // These are deliberately generous: the backend is a Vercel serverless
  // function backed by a Neon database that both suspend after a period of
  // inactivity, so the very first request after the app has been closed for
  // a while can be a genuine cold start (function cold boot + database
  // resume) on top of normal mobile network latency — tighter timeouts were
  // flagging that as "unreachable" when it just needed a few more seconds.
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 20),
    ),
  );
  PersistCookieJar? _cookieJar;
  late final AdminApi admin;

  /// Called whenever a request comes back 401. Wired up by [AuthProvider] so
  /// an expired session cookie bounces the whole app back to the login
  /// screen instead of leaving every individual screen to show a raw error.
  void Function()? onUnauthorized;

  ApiClient(this.config) {
    admin = AdminApi._(this);
  }

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    _cookieJar = PersistCookieJar(storage: FileStorage('${dir.path}/cookies'));
    _dio.interceptors.add(CookieManager(_cookieJar!));
  }

  Future<void> clearSession() async {
    await _cookieJar?.deleteAll();
  }

  Uri _uri(String path) => Uri.parse('${config.baseUrl}$path');

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? form,
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.request(
        _uri(path).toString(),
        queryParameters: query,
        data: form == null ? null : _stripNulls(form),
        options: Options(
          method: method,
          contentType: form == null ? null : Headers.formUrlEncodedContentType,
        ),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        onUnauthorized?.call();
      }
      throw _toApiException(e);
    }
  }

  Map<String, dynamic> _stripNulls(Map<String, dynamic> map) {
    final out = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.value != null) out[entry.key] = entry.value;
    }
    return out;
  }

  ApiException _toApiException(DioException e) {
    final response = e.response;
    if (response == null) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          // The backend can be genuinely slow to wake up from a cold start —
          // distinct from "unreachable" so a retry a few seconds later reads
          // as the obvious next step rather than a dead end.
          return ApiException(
            'The StorePass server is taking a while to respond (it may be waking up). Please try again in a few seconds.',
          );
        case DioExceptionType.connectionError:
        case DioExceptionType.unknown:
          return ApiException(
            'Could not reach the StorePass API. Check your internet connection and try again.',
          );
        default:
          return ApiException(
            'Could not reach the StorePass API at ${config.baseUrl}. Is the backend running there?',
          );
      }
    }
    final data = response.data;
    final detail = data is Map ? data['detail'] : null;
    return ApiException(
      detail is String ? detail : 'Something went wrong (${response.statusCode}).',
      response.statusCode,
    );
  }

  // --- Auth -----------------------------------------------------------
  Future<Principal> register({required String name, required String contact, required String password}) async {
    final data = await _send('POST', '/auth/register', form: {'name': name, 'contact': contact, 'password': password});
    return Principal.fromJson(data as Map<String, dynamic>);
  }

  Future<Principal> login({required String contact, required String password}) async {
    final data = await _send('POST', '/auth/login', form: {'contact': contact, 'password': password});
    return Principal.fromJson(data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _send('POST', '/auth/logout');
    await clearSession();
  }

  Future<Principal> loginWithGoogle(String idToken) async {
    final data = await _send('POST', '/auth/google', form: {'id_token': idToken});
    return Principal.fromJson(data as Map<String, dynamic>);
  }

  Future<void> forgotPassword(String contact) async {
    await _send('POST', '/auth/forgot-password', form: {'contact': contact});
  }

  Future<void> resetPassword({required String token, required String password}) async {
    await _send('POST', '/auth/reset-password', form: {'token': token, 'password': password});
  }

  Future<Principal> me() async {
    final data = await _send('GET', '/users/me');
    return Principal.fromJson(data as Map<String, dynamic>);
  }

  Future<Principal> updateMe({String? name, String? password, String? currentPassword}) async {
    final data = await _send(
      'PUT',
      '/users/me',
      form: {'name': name, 'password': password, 'current_password': currentPassword},
    );
    return Principal.fromJson(data as Map<String, dynamic>);
  }

  // --- Shops (customer-facing) -----------------------------------------
  Future<List<Shop>> listShops() async {
    final data = await _send('GET', '/shops') as List<dynamic>;
    return data.map((e) => Shop.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ShopDetail> shopDetail(int id) async {
    final data = await _send('GET', '/shops/$id');
    return ShopDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Review>> shopReviews(int id) async {
    final data = await _send('GET', '/shops/$id/reviews') as List<dynamic>;
    return data.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- Transactions ------------------------------------------------------
  Future<Txn> createTransaction(double amount) async {
    final data = await _send('POST', '/transactions/create', form: {'amount': amount});
    return Txn.fromJson(data as Map<String, dynamic>);
  }

  String qrImageUrl(String token) => '${config.baseUrl}/transactions/qr/$token';

  Future<ClaimResult> claimTransaction(String qrToken) async {
    final data = await _send('POST', '/transactions/claim', form: {'qr_token': qrToken});
    return ClaimResult.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Txn>> myTransactions() async {
    final data = await _send('GET', '/transactions/mine') as List<dynamic>;
    return data.map((e) => Txn.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Txn>> shopTransactions() async {
    final data = await _send('GET', '/transactions/shop-mine') as List<dynamic>;
    return data.map((e) => Txn.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- Reviews -------------------------------------------------------------
  Future<Review> createReview({required int transactionId, required int rating, String? comment}) async {
    final data = await _send('POST', '/reviews', form: {
      'transaction_id': transactionId,
      'rating': rating,
      'comment': comment,
    });
    return Review.fromJson(data as Map<String, dynamic>);
  }

  // --- Wallets ---------------------------------------------------------
  Future<List<Wallet>> myWallets() async {
    final data = await _send('GET', '/wallets/mine') as List<dynamic>;
    return data.map((e) => Wallet.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class AdminApi {
  final ApiClient _client;
  AdminApi._(this._client);

  Future<Shop> createShop({
    required String name,
    required String category,
    required String contact,
    required String password,
    String description = '',
    String? logoUrl,
    String? address,
    String? phone,
    String? hours,
    double? cashbackRate,
  }) async {
    final data = await _client._send('POST', '/admin/shops', form: {
      'name': name,
      'category': category,
      'contact': contact,
      'password': password,
      'description': description,
      'logo_url': logoUrl,
      'address': address,
      'phone': phone,
      'hours': hours,
      'cashback_rate': cashbackRate,
    });
    return Shop.fromJson(data as Map<String, dynamic>);
  }

  Future<Shop> updateShop(
    int id, {
    String? name,
    String? category,
    String? description,
    String? logoUrl,
    String? address,
    String? phone,
    String? hours,
    double? cashbackRate,
    bool? isActive,
  }) async {
    final data = await _client._send('PATCH', '/admin/shops/$id', form: {
      'name': name,
      'category': category,
      'description': description,
      'logo_url': logoUrl,
      'address': address,
      'phone': phone,
      'hours': hours,
      'cashback_rate': cashbackRate,
      'is_active': isActive,
    });
    return Shop.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Shop>> listShops() async {
    final data = await _client._send('GET', '/admin/shops') as List<dynamic>;
    return data.map((e) => Shop.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AdminCustomer>> listCustomers() async {
    final data = await _client._send('GET', '/admin/customers') as List<dynamic>;
    return data.map((e) => AdminCustomer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Txn>> listTransactions({int? shopId}) async {
    final data = await _client
        ._send('GET', '/admin/transactions', query: shopId != null ? {'shop_id': shopId} : null) as List<dynamic>;
    return data.map((e) => Txn.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Review>> listReviews({int? shopId}) async {
    final data = await _client
        ._send('GET', '/admin/reviews', query: shopId != null ? {'shop_id': shopId} : null) as List<dynamic>;
    return data.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteReview(int id) => _client._send('DELETE', '/admin/reviews/$id');
}
