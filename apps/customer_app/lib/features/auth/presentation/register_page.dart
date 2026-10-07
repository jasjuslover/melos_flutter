import 'package:customer_app/features/auth/presentation/auth_controller.dart';
import 'package:customer_app/shared/messages.dart';
import 'package:customer_app/shared/validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(_email.text.trim(), _password.text);
    } catch (e) {
      if (mounted) setState(() => _error = messageOf(e));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        helperText: 'Minimum 8 chars',
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (v) => (v == null || v.length < 8)
                          ? 'Minimum 8 chars'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      decoration: const InputDecoration(
                        labelText: 'Repeat Password',
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) => v != _password.text
                          ? 'Password is not identical'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Register'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
