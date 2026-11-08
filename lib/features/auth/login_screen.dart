import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth_scope.dart';
import '../../core/theme/app_tokens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final c = context.colors;
    final isAuthenticating = auth.isAuthenticating;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),
                Center(
                  child: Text(
                    '一切尽在掌握',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 28 / 22,
                      letterSpacing: 6,
                      color: c.brandText,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                _FieldLabel('学号'),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  style: AppText.body.copyWith(color: c.text),
                  decoration: InputDecoration(
                    hintText: '请输入学号',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      size: 20,
                      color: c.textMuted,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入学号';
                    }
                    return null;
                  },
                  enabled: !isAuthenticating,
                ),
                const SizedBox(height: AppSpacing.xl),
                _FieldLabel('密码'),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  style: AppText.body.copyWith(color: c.text),
                  onFieldSubmitted: (_) {
                    if (!isAuthenticating) _handleLogin();
                  },
                  decoration: InputDecoration(
                    hintText: '请输入密码',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: c.textMuted,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: c.textMuted,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    return null;
                  },
                  enabled: !isAuthenticating,
                ),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, size: 16, color: c.danger),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: AppText.caption.copyWith(color: c.danger),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isAuthenticating ? null : _handleLogin,
                    child: isAuthenticating
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Text('登录'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    await AuthScope.of(context).login(username, password);
    if (!mounted) return;
    if (AuthScope.of(context).isAuthenticated) {
      TextInput.finishAutofillContext();
    }
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppText.bodyDense.copyWith(
        color: context.colors.text,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
