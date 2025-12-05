import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projectx/config.dart';
import 'package:projectx/views/pages/registeration_page.dart';
import 'package:projectx/views/pages/new_password_page.dart';
import 'package:projectx/views/widgets/button_tile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final bool isReset; // <-- IMPORTANT

  const OtpVerificationPage({
    super.key,
    required this.phoneNumber,
    this.isReset = false,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _backendMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _backendMessage = null;
    });

    final baseUrl = AppConfig.backendUrl;

    final Uri url = widget.isReset
        ? Uri.parse('$baseUrl/api/v1/auth/forgot-password/otp/verify')
        : Uri.parse('$baseUrl/api/v1/auth/otp/verify');

    final body = {
            "phoneNo": widget.phoneNumber,
            "otp": _otpController.text.trim(),
          };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;
      final json = jsonDecode(response.body);

      if (json['status'] == 'success') {
        setState(() {
          _backendMessage = json['message'] ?? "OTP verified successfully!";
        });

        if (widget.isReset) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  NewPasswordPage(phoneNumber: widget.phoneNumber),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RegistrationPage(phoneNumber: widget.phoneNumber),
            ),
          );
        }
      } else {
        setState(() {
          _backendMessage = json['message'] ??
              "OTP verification failed. Status: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _backendMessage = "Network error: Could not connect to backend.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _backendMessage = null;
    });

    final baseUrl = AppConfig.backendUrl;

    
    final Uri url = widget.isReset
        ? Uri.parse('$baseUrl/api/v1/auth/forgot-password/otp/send')
        : Uri.parse('$baseUrl/api/v1/auth/otp/send');

    
    final body = {"phoneNo": widget.phoneNumber};

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body);

      if (json['status'] == 'success') {
        setState(() {
          _backendMessage = json['message'] ?? "OTP resent successfully!";
        });
      } else {
        setState(() {
          _backendMessage = json['message'] ??
              "Failed to resend OTP. Status: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _backendMessage = "Network error: Could not resend OTP.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final title =
        widget.isReset ? "Reset Password – Verify OTP" : "OTP Verification";

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
                    blurRadius: 12,
                    offset: const Offset(0, 3),
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
                      Text(title, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 16),
                      Text(
                        "Enter the 6-digit code sent to ${widget.phoneNumber}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // OTP FIELD
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(
                          labelText: "OTP Code",
                          hintText: "______",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "Please enter OTP";
                          if (value.length != 6)
                            return "OTP must be 6 digits";
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _isLoading
                          ? const CircularProgressIndicator()
                          : ButtonTile(
                              label: "Verify OTP",
                              onTap: _verifyOtp,
                              icon: Icons.check_circle,
                              bgColor: Colors.green,
                              textColor: Colors.white,
                            ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: _isLoading ? null : _resendOtp,
                        child: Text(
                          "Resend OTP",
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ),

                      if (_backendMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _backendMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _backendMessage!.contains("success")
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 14,
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
      ),
    );
  }
}
