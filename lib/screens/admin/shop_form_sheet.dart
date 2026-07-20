import 'package:flutter/material.dart';

import '../../services/api_client.dart';

/// Bottom sheet form for `POST /admin/shops` — creating a new shop account.
/// Returns `true` via Navigator.pop when a shop was created successfully.
Future<bool?> showCreateShopSheet(BuildContext context, {required ApiClient api}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _CreateShopForm(api: api),
    ),
  );
}

class _CreateShopForm extends StatefulWidget {
  final ApiClient api;
  const _CreateShopForm({required this.api});

  @override
  State<_CreateShopForm> createState() => _CreateShopFormState();
}

class _CreateShopFormState extends State<_CreateShopForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _contact = TextEditingController();
  final _password = TextEditingController();
  final _description = TextEditingController();
  final _logoUrl = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _hours = TextEditingController();
  final _rate = TextEditingController(text: '1');
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _contact.dispose();
    _password.dispose();
    _description.dispose();
    _logoUrl.dispose();
    _address.dispose();
    _phone.dispose();
    _hours.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final rate = double.tryParse(_rate.text.trim());
    if (rate == null || rate < 0 || rate > 100) {
      setState(() => _error = 'Cashback rate must be a number between 0 and 100');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.api.admin.createShop(
        name: _name.text.trim(),
        category: _category.text.trim(),
        contact: _contact.text.trim(),
        password: _password.text,
        description: _description.text.trim(),
        logoUrl: _logoUrl.text.trim().isEmpty ? null : _logoUrl.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        hours: _hours.text.trim().isEmpty ? null : _hours.text.trim(),
        cashbackRate: rate / 100,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add shop', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Shop name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Sneakers, clothing, sports gear…',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contact,
                decoration: const InputDecoration(labelText: 'Login contact (email/phone)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Temporary password'),
                validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rate,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Cashback rate (%)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _logoUrl,
                decoration: const InputDecoration(labelText: 'Logo URL (optional)'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Address (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone (optional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hours,
                decoration: const InputDecoration(labelText: 'Hours (optional)', hintText: 'Mon–Fri 9–6'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create shop'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
