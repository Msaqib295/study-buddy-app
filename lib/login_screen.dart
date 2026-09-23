import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  String _friendlyError(String code) {
    switch (code) {
      case 'invalid-email':
        return "That email address doesn't look right.";
      case 'user-not-found':
        return "No account found with that email.";
      case 'wrong-password':
      case 'invalid-credential':
        return "Incorrect email or password.";
      case 'email-already-in-use':
        return "An account already exists with that email.";
      case 'weak-password':
        return "Password should be at least 6 characters.";
      case 'too-many-requests':
        return "Too many attempts. Please try again later.";
      default:
        return "Something went wrong. Please try again.";
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && name.isEmpty)) {
      setState(() {
        _errorMessage = "Please fill in all fields";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        await credential.user?.updateDisplayName(name);
        await credential.user?.reload();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyError(e.code);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Something went wrong. Please try again.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldFillColor = isDark ? Colors.grey[850] : Colors.grey[100];
    final mutedColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final textColor = isDark ? Colors.white : Colors.black87;
    final buttonBgColor = isDark ? Colors.grey[200] : Colors.grey[900];
    final buttonTextColor = isDark ? Colors.black : Colors.white;
    final errorBgColor = isDark
        ? Colors.red[900]!.withValues(alpha: 0.2)
        : Colors.red[50];
    final errorBorderColor = isDark ? Colors.red[700]! : Colors.red[200]!;
    final errorTextColor = isDark ? Colors.red[200] : Colors.red[700];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/icon/app_icon_light.png',
                      width: 56,
                      height: 56,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isLogin ? "Welcome back" : "Create an account",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLogin
                        ? "Sign in to continue studying"
                        : "Get started with your study buddy",
                    style: TextStyle(fontSize: 13, color: mutedColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (!_isLogin) ...[
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: "Name",
                        labelStyle: TextStyle(color: mutedColor),
                        filled: true,
                        fillColor: fieldFillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: mutedColor),
                      filled: true,
                      fillColor: fieldFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(color: mutedColor),
                      filled: true,
                      fillColor: fieldFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: errorBgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: errorBorderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: errorTextColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: errorTextColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonBgColor,
                      foregroundColor: buttonTextColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: buttonTextColor,
                            ),
                          )
                        : Text(_isLogin ? "Sign in" : "Sign up"),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? "Don't have an account? Sign up"
                          : "Already have an account? Sign in",
                      style: TextStyle(color: mutedColor, fontSize: 13),
                    ),
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
