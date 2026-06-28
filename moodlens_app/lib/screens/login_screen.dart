import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final AuthService _authService =
      AuthService();

  bool _loading = false;

  Future<void> _googleLogin() async {
    setState(() {
      _loading = true;
    });

    try {
      await _authService.signInWithGoogle();

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.psychology,
                size: 80,
              ),

              const SizedBox(
                height: 24,
              ),

              const Text(
                "Save Your Mood Journey",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              const Text(
                "Login to sync your mood history across devices and unlock long-term analytics.",
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 40,
              ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _loading
                      ? null
                      : _googleLogin,
                  icon: const Icon(
                    Icons.login,
                  ),
                  label: Text(
                    _loading
                        ? "Signing In..."
                        : "Continue with Google",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}