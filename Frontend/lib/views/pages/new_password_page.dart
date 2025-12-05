import 'package:flutter/material.dart';
import 'package:projectx/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:projectx/views/pages/login_page.dart';

class NewPasswordPage extends StatefulWidget {
  final String phoneNumber;

  const NewPasswordPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _backendMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submitNewPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _backendMessage = null;
    });

    final url = AppConfig.backendUrl;
    final Uri endpoint = Uri.parse('$url/api/v1/auth/change-password');

    final body = {
      "userName": widget.phoneNumber,
      "password": _passwordController.text.trim(),
    };

    try {
      final response = await http.put(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      final json = jsonDecode(response.body);

      if (json['status'] == "success") {
        setState(() {
          _backendMessage = json['message'] ?? "Password changed successfully!";
        });

       
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        });
      } else {
        setState(() {
          _backendMessage = json['message'] ?? "Failed to change password.";
        });
      }
    } catch (e) {
      setState(() {
        _backendMessage = "Network error: Could not reach backend.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.blue.shade400,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade800,
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Set New Password",
                      style: TextStyle(fontSize: 22),
                    ),
                    const SizedBox(height: 20),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: "New Password",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter new password";
                        }
                        if (value.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmController,
                      decoration: const InputDecoration(
                        labelText: "Confirm Password",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Confirm your password";
                        }
                        if (value != _passwordController.text.trim()) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: _submitNewPassword,
                            icon: const Icon(Icons.lock_reset),
                            label: const Text("Update Password"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),

                    if (_backendMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _backendMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _backendMessage!.toLowerCase().contains("success")
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
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
