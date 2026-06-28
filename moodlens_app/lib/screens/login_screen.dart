import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/mood_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSignup = false;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      if (_isSignup) {
        await _authService.createAccountWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await _authService.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = _authService.friendlyAuthError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _googleLogin() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      await _authService.signInWithGoogle();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        final message = error.toString().contains('cancelled')
            ? 'Google sign-in was cancelled.'
            : _authService.friendlyAuthError(error);
        _error = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      await _authService.signInAnonymously();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = _authService.friendlyAuthError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    setState(() {
      _error = null;
      _success = null;
    });

    if (!_isValidEmail(email)) {
      setState(() {
        _error = 'Enter your email first, then tap forgot password.';
      });
      return;
    }

    try {
      await _authService.sendPasswordReset(email);

      if (!mounted) return;

      setState(() {
        _success = 'Password reset email sent.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = _authService.friendlyAuthError(error);
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignup = !_isSignup;
      _error = null;
      _success = null;
    });
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email is required.';
    }

    if (!_isValidEmail(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required.';
    }

    if (_isSignup && password.length < 6) {
      return 'Use at least 6 characters.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final moodTheme = MoodThemes.neutral;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 420;

    return Scaffold(
      backgroundColor: moodTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                isCompact ? 18 : 28,
                18,
                isCompact ? 18 : 28,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 42,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: _LoginPanel(
                      moodTheme: moodTheme,
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      isSignup: _isSignup,
                      obscurePassword: _obscurePassword,
                      loading: _loading,
                      error: _error,
                      success: _success,
                      onSubmit: _submit,
                      onGoogleLogin: _googleLogin,
                      onGuest: _continueAsGuest,
                      onForgotPassword: _isSignup ? null : _resetPassword,
                      onToggleMode: _toggleMode,
                      onTogglePassword: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      validateEmail: _validateEmail,
                      validatePassword: _validatePassword,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  final MoodTheme moodTheme;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSignup;
  final bool obscurePassword;
  final bool loading;
  final String? error;
  final String? success;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleLogin;
  final VoidCallback onGuest;
  final VoidCallback? onForgotPassword;
  final VoidCallback onToggleMode;
  final VoidCallback onTogglePassword;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;

  const _LoginPanel({
    required this.moodTheme,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isSignup,
    required this.obscurePassword,
    required this.loading,
    required this.error,
    required this.success,
    required this.onSubmit,
    required this.onGoogleLogin,
    required this.onGuest,
    required this.onForgotPassword,
    required this.onToggleMode,
    required this.onTogglePassword,
    required this.validateEmail,
    required this.validatePassword,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: moodTheme.card.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: moodTheme.border),
            boxShadow: [
              BoxShadow(
                color: moodTheme.accent.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BrandHeader(moodTheme: moodTheme),
                const SizedBox(height: 24),
                Text(
                  isSignup ? 'Create your account' : 'Welcome back',
                  style: TextStyle(
                    color: moodTheme.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isSignup
                      ? 'Save mood history and unlock long-term analytics.'
                      : 'Sign in to sync your mood journey across devices.',
                  style: TextStyle(color: moodTheme.mutedText, height: 1.45),
                ),
                const SizedBox(height: 18),
                if (error != null) ...[
                  _MessageBox(
                    message: error!,
                    moodTheme: moodTheme,
                    isError: true,
                  ),
                  const SizedBox(height: 12),
                ],
                if (success != null) ...[
                  _MessageBox(
                    message: success!,
                    moodTheme: moodTheme,
                    isError: false,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: emailController,
                  enabled: !loading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: validateEmail,
                  autofillHints: const [AutofillHints.email],
                  style: TextStyle(color: moodTheme.text),
                  decoration: _inputDecoration(
                    moodTheme: moodTheme,
                    label: 'Email',
                    icon: Icons.mail_outline,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: passwordController,
                  enabled: !loading,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.done,
                  validator: validatePassword,
                  onFieldSubmitted: (_) {
                    if (!loading) {
                      onSubmit();
                    }
                  },
                  autofillHints: [
                    isSignup
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  style: TextStyle(color: moodTheme.text),
                  decoration: _inputDecoration(
                    moodTheme: moodTheme,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      tooltip: obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: loading ? null : onTogglePassword,
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: moodTheme.mutedText,
                      ),
                    ),
                  ),
                ),
                if (onForgotPassword != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: loading ? null : onForgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  )
                else
                  const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: loading ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: moodTheme.accent,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: moodTheme.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            isSignup ? 'Create Account' : 'Login',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: loading ? null : onGoogleLogin,
                  icon: const Icon(Icons.login),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: moodTheme.text,
                    side: BorderSide(color: moodTheme.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: loading ? null : onGuest,
                  child: const Text('Continue as guest'),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        isSignup
                            ? 'Already have an account?'
                            : 'New to MoodLens?',
                        style: TextStyle(color: moodTheme.mutedText),
                      ),
                    ),
                    TextButton(
                      onPressed: loading ? null : onToggleMode,
                      child: Text(isSignup ? 'Login' : 'Sign up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required MoodTheme moodTheme,
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: moodTheme.background.withValues(alpha: 0.55),
      labelStyle: TextStyle(color: moodTheme.mutedText),
      prefixIconColor: moodTheme.mutedText,
      errorMaxLines: 2,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: moodTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: moodTheme.accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final MoodTheme moodTheme;

  const _BrandHeader({required this.moodTheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: moodTheme.accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: moodTheme.accent.withValues(alpha: 0.35)),
          ),
          child: Icon(Icons.psychology_alt, color: moodTheme.accent, size: 32),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MoodLens AI',
                style: TextStyle(
                  color: moodTheme.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Emotion, sarcasm and mood analysis',
                style: TextStyle(color: moodTheme.mutedText, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String message;
  final MoodTheme moodTheme;
  final bool isError;

  const _MessageBox({
    required this.message,
    required this.moodTheme,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.redAccent : const Color(0xFF74C69D);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? Colors.redAccent.shade100 : color,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
