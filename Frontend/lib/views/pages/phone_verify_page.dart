import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projectx/config.dart';
import 'package:projectx/views/pages/login_page.dart';
import 'package:projectx/views/pages/otp_verification_page.dart';
import 'package:projectx/views/widgets/button_tile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PhoneVerifyPage extends StatefulWidget {
  final bool isReset; // <-- reset flag

  const PhoneVerifyPage({super.key, this.isReset = false});

  @override
  State<PhoneVerifyPage> createState() => _PhoneVerifyPageState();
}

class _PhoneVerifyPageState extends State<PhoneVerifyPage> {
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _backendMessage;

  Future<void> _sendPhoneNumber() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _backendMessage = null;
    });

    final baseUrl = AppConfig.backendUrl;

    final Uri url = widget.isReset
        ? Uri.parse('$baseUrl/api/v1/auth/forgot-password/otp/send')
        : Uri.parse('$baseUrl/api/v1/auth/otp/send');

    final body = {
            "phoneNo": phoneController.text.trim() 
          };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      final json = jsonDecode(response.body);

      if (json['status'] == "success") {
        setState(() {
          _backendMessage = 'OTP sent successfully!';
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationPage(
              phoneNumber: phoneController.text.trim(),
              isReset: widget.isReset, // pass forward
            ),
          ),
        );
      } else {
        setState(() {
          _backendMessage = json['message'] ??
              'Failed to send OTP. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _backendMessage = 'Network error: Unable to reach server.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isReset
        ? "Reset Password – Verify Phone"
        : "Verify Phone Number";

    final buttonText = widget.isReset ? "Send Reset OTP" : "Verify";

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.blue.shade400,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 30),
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade800,
                    offset: const Offset(0, 3),
                    blurRadius: 12,
                  ),
                ],
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 30),

                      Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text("+91", textAlign: TextAlign.right),
                          ),
                          const SizedBox(width: 10),

                          Expanded(
                            child: TextFormField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: const InputDecoration(
                                labelText: "Phone Number",
                                hintText: "Enter your phone number",
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
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _isLoading
                          ? const CircularProgressIndicator()
                          : ButtonTile(
                              label: buttonText,
                              onTap: _sendPhoneNumber,
                              icon: Icons.verified,
                              bgColor: Colors.blue,
                              textColor: Colors.white,
                            ),

                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text("Registered User? Login here"),
                      ),

                      if (_backendMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            _backendMessage!,
                            style: TextStyle(
                              color: _backendMessage!.toLowerCase().contains('success')
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
