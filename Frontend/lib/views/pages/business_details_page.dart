import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projectx/config.dart';
import 'package:projectx/data/notifiers.dart';
import 'package:projectx/main.dart';
import 'package:projectx/views/pages/login_page.dart';
import 'package:projectx/views/widgets/button_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class BusinessDetailsPage extends StatefulWidget {
  final String businessName;
  final String businessPhone;
  final String email;

  const BusinessDetailsPage({
    super.key,
    required this.businessName,
    required this.businessPhone,
    required this.email,
  });

  @override
  State<BusinessDetailsPage> createState() => _BusinessDetailsPageState();

}

class _BusinessDetailsPageState extends State<BusinessDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessPhoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _fssaiController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _tableCountController = TextEditingController();

  bool _isLoading = false;
  int? _selectedGstType;

  @override
  void initState() {
  super.initState();
  _businessNameController.text = widget.businessName;
  _businessPhoneController.text = widget.businessPhone;
  _emailController.text = widget.email;
}

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    setState(() => _isLoading = false);
  }

  Future<void> _submitBusinessDetails() async {
    if (!_formKey.currentState!.validate() || _selectedGstType == null) {
      _showError("Please complete all required fields");
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final data = {
      "name": _businessNameController.text.trim(),
      "businessPhone": _businessPhoneController.text.trim(),
      "email": _emailController.text.trim(),
      "gstNumber": _gstController.text.trim(),
      "address": _addressController.text.trim(),
      "fssaiNo": _fssaiController.text.trim(),
      "licenseNo": _licenseController.text.trim(),
      "gstType": _selectedGstType,
      "tableCount": int.tryParse(_tableCountController.text.trim()) ?? 0,
    };

    try {
      final url = AppConfig.backendUrl;
      final response = await http.post(
        Uri.parse('$url/api/v1/business'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      final resJson = jsonDecode(response.body);

      if (resJson['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Business details submitted successfully")),
        );
        businessNameNotifier.value = _businessNameController.text.trim();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyApp(),));
      } else {
        _showError(resJson['message'] ?? "Failed to submit details");
      }
    } catch (e) {
      _showError("Network Error: $e");
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
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Business Details", style: TextStyle(fontSize: 22)),
                        const SizedBox(height: 16),
                        Text(
                          "Complete your Business Info",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 30),

                        TextFormField(
                          controller: _businessNameController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: "Business Name",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Please enter Business Name' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _businessPhoneController,
                          enabled:false,
                          decoration: const InputDecoration(
                            labelText: "Business Phone",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Please enter Business Phone' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          enabled:false,
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Please enter Email' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _gstController,
                          decoration: const InputDecoration(
                            labelText: "GST Number",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Please enter GST Number' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: "Address",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Please enter Address' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _fssaiController,
                          decoration: const InputDecoration(
                            labelText: "FSSAI Number",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Please enter FSSAI Number' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _licenseController,
                          decoration: const InputDecoration(
                            labelText: "License Number",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Please enter License Number' : null,
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: "GST Type (1 to 4)",
                            border: OutlineInputBorder(),
                          ),
                          items: [1, 2, 3, 4]
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text("Type $e"),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedGstType = value),
                          validator: (value) =>
                              value == null ? 'Please select GST Type' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _tableCountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: "Number of Tables",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter number of tables';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        _isLoading
                            ? const CircularProgressIndicator()
                            : ButtonTile(
                                label: "Save Business Details",
                                onTap: _submitBusinessDetails,
                                icon: Icons.save,
                                bgColor: Colors.blue.shade700,
                                textColor: Colors.white,
                              ),
                      ],
                    ),
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
