import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/google_mark.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'server_settings_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _googleSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(
            contact: _contactController.text.trim(),
            password: _passwordController.text,
          );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _error = null;
      _googleSubmitting = true;
    });
    try {
      // Native Google account picker → Google ID token...
      final account = await GoogleSignIn.instance.authenticate();
      final googleIdToken = account.authentication.idToken;
      if (googleIdToken == null) {
        throw Exception('Google did not return an ID token');
      }
      // ...exchanged for a Firebase ID token (same shape the backend already
      // verifies for the web client) via signInWithCredential.
      final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken = await userCredential.user?.getIdToken();
      if (firebaseIdToken == null) {
        throw Exception('Could not get a Firebase ID token');
      }
      if (!mounted) return;
      await context.read<AuthProvider>().loginWithGoogle(firebaseIdToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      setState(
        () => _error = 'Could not sign in with Google '
            '(${e.code.name}${e.description != null ? ': ${e.description}' : ''})',
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = 'Could not sign in with Google (${e.code}: ${e.message})');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      // Deliberately showing the raw error here (not a generic message) —
      // this is the fallback for whatever we haven't seen yet, and a vague
      // "something went wrong" is useless for actually diagnosing it.
      setState(() => _error = 'Could not sign in with Google (${e.runtimeType}: $e)');
    } finally {
      if (mounted) setState(() => _googleSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandMark()),
                  const SizedBox(height: 16),
                  Text('StorePass', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(
                    'Scan. Earn. Come back.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: (_googleSubmitting || _submitting) ? null : _signInWithGoogle,
                    icon: _googleSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const GoogleMark(),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: Theme.of(context).textTheme.bodySmall),
                      ),
                      Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(labelText: 'Phone or email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    if (_error!.contains('Could not reach')) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
                          ),
                          child: const Text('Check server settings →'),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          )
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    ),
                    child: const Text('Forgot password?'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text("New here? Create a customer account"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
