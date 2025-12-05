import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/config.dart';
import 'package:projectx/views/pages/business_details_page.dart';
import 'package:projectx/views/pages/login_page.dart';
import 'package:projectx/views/widgets/button_tile.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationPage extends StatefulWidget {
  final String phoneNumber;

  const RegistrationPage({super.key, required this.phoneNumber});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessPhoneController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _backendMessage;
  

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      setState(() {
        _backendMessage = "Passwords do not match.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _backendMessage = null;
    });
    final urlBackend = AppConfig.backendUrl;
    final Uri url = Uri.parse('$urlBackend/api/v1/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ownerName': _nameController.text.trim(),
          'businessName': _businessNameController.text.trim(),
          'userName': widget.phoneNumber,
          'userPhoneNo': widget.phoneNumber,
          'phoneNo': _businessPhoneController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final json = jsonDecode(response.body);
      if (json['status'] == 'success') {
        setState(() {
          _backendMessage = json['message'] ?? "Registration successful!";
        });
        await saveToken(json['data']);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(
              businessName: _businessNameController.text.trim(),
              businessPhone: _businessPhoneController.text.trim(),
              email: _emailController.text.trim(),
            ),
          ),
        );
      } else {
        setState(() {
          _backendMessage = json['message'] ?? "Registration failed.";
        });
      }
    } catch (e) {
      setState(() {
        _backendMessage = "Network error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.blue.shade400,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 30),
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade800,
                    offset: const Offset(0, 3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Complete Registration",
                        style: TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Register your Business",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 30),

                      TextFormField(
                        controller: _businessNameController,
                        decoration: const InputDecoration(
                          labelText: "Business Name",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your Business Name'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your Full Name'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        initialValue: widget.phoneNumber,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _businessPhoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          labelText: "Business Contact Number",
                          hintText: "Enter your business phone number",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a phone number';
                          }
                          if (value.length != 10) {
                            return 'Phone number must be 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your Email'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.length < 6
                            ? 'Password must be at least 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Confirm Password",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please confirm your password'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        ButtonTile(
                          label: "Register Business",
                          onTap: _submitRegistration,
                          icon: Icons.check_circle,
                          bgColor: Colors.green,
                          textColor: Colors.white,
                        ),

                      if (_backendMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _backendMessage!,
                            style: TextStyle(
                              color:
                                  _backendMessage!.toLowerCase().contains(
                                    'success',
                                  )
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
