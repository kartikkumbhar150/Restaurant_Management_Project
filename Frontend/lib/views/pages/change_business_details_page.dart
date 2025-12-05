import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:projectx/config.dart';
import 'package:projectx/views/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectx/data/notifiers.dart';
import 'package:projectx/views/widgets/button_tile.dart';

class ChangeBusinessDetailsPage extends StatefulWidget {
  const ChangeBusinessDetailsPage({Key? key}) : super(key: key);

  @override
  State<ChangeBusinessDetailsPage> createState() =>
      _ChangeBusinessDetailsPageState();
}

class _ChangeBusinessDetailsPageState extends State<ChangeBusinessDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _fssaiController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tableCountController = TextEditingController();

  // state
  String? _selectedGstType;
  bool _isLoading = true;
  String? _imageUrl;
  File? _localImageFile;

  Map<String, dynamic> _originalData = {};

  final Map<String, String> gstTypes = {
    "1. Non GST": "1",
    "2. Non-AC Restaurants (Standalone) – 5% GST (No ITC)": "2",
    "3. AC Restaurants (Standalone) – 5% GST (No ITC)": "3",
    "4. Restaurants in Hotels (Room tariff < ₹7,500) – 5% GST (No ITC)": "4",
    "5. Restaurants in Hotels (Room tariff ≥ ₹7,500) – 18% GST (With ITC)": "5",
    "6. Restaurants Serving Alcohol – 5% GST (No ITC)": "6",
    "7. Takeaway & Cloud Kitchens – 5% GST (No ITC)": "7",
    "8. Outdoor Catering Services – 18% GST (With ITC)": "8",
    "9. Composite Scheme Restaurants (Turnover < ₹1.5 crore) - 5% GST(No ITC)": "9"
  };

  

  @override
  void initState() {
    super.initState();
    _fetchBusinessDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _fssaiController.dispose();
    _licenseController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _tableCountController.dispose();
    super.dispose();
  }

  Future<void> _fetchBusinessDetails() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final url = AppConfig.backendUrl;
      final response = await http.get(
        Uri.parse('$url/api/v1/business'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        _showError('Failed to load business (status ${response.statusCode})');
        return;
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (body['status'] == 'success' && body['data'] != null) {
        final data = Map<String, dynamic>.from(body['data']);
        _originalData = Map<String, dynamic>.from(data);

        final name = data['name']?.toString() ?? '';
        businessNameNotifier.value = name;
        _nameController.text = name;
        _gstController.text = data['gstNumber']?.toString() ?? '';
        _addressController.text = data['address']?.toString() ?? '';
        _fssaiController.text = data['fssaiNo']?.toString() ?? '';
        _licenseController.text = data['licenceNo']?.toString() ?? '';
        _phoneController.text = data['phoneNo']?.toString() ?? '';
        _emailController.text = data['email']?.toString() ?? '';
        _tableCountController.text = data['tableCount']?.toString() ?? '';

        final gstTypeValue = data['gstType']?.toString() ?? '1';
        _selectedGstType = gstTypes.entries
            .firstWhere(
              (e) => e.value == gstTypeValue,
              orElse: () => const MapEntry("Type 1", "1"),
            )
            .value;

        final logo = data['logoUrl']?.toString() ?? '';
        _imageUrl = logo.isNotEmpty ? logo : null;

        setState(() => _isLoading = false);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      _showError('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final bytes = await picked.readAsBytes();

      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        _showError('Could not decode image');
        return;
      }

      final gray = img.grayscale(decoded);

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/bw_${DateTime.now().millisecondsSinceEpoch}.png';
      final bwFile = File(filePath);
      await bwFile.writeAsBytes(img.encodePng(gray));

      setState(() {
        _localImageFile = bwFile;
        _imageUrl = null;
      });

      final returnedData = await _uploadLogoToServer(bwFile);
      if (returnedData != null) {
        _originalData = Map<String, dynamic>.from(returnedData);

        setState(() {
          _imageUrl = _originalData['logoUrl']?.toString();
          _nameController.text = _originalData['name']?.toString() ?? _nameController.text;
          _gstController.text = _originalData['gstNumber']?.toString() ?? _gstController.text;
          _addressController.text = _originalData['address']?.toString() ?? _addressController.text;
          _fssaiController.text = _originalData['fssaiNo']?.toString() ?? _fssaiController.text;
          _licenseController.text = _originalData['licenceNo']?.toString() ?? _licenseController.text;
          _phoneController.text = _originalData['phoneNo']?.toString() ?? _phoneController.text;
          _emailController.text = _originalData['email']?.toString() ?? _emailController.text;
          _tableCountController.text = _originalData['tableCount']?.toString() ?? _tableCountController.text;

          final gstTypeValue = _originalData['gstType']?.toString();
          if (gstTypeValue != null) {
            _selectedGstType = gstTypes.entries
                .firstWhere(
                  (e) => e.value == gstTypeValue,
                  orElse: () => const MapEntry("Type 1", "1"),
                )
                .value;
          }
        });
      } else {
        _showError('Failed to upload image');
      }
    } catch (e) {
      _showError('Image processing/upload error: $e');
    }
  }

  Future<Map<String, dynamic>?> _uploadLogoToServer(File file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final url = AppConfig.backendUrl;
      final uri = Uri.parse('$url/api/v1/business/logo');
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] != null) {
          return Map<String, dynamic>.from(body['data']);
        } else {
          debugPrint('Unexpected upload response: ${response.body}');
          return null;
        }
      } else {
        debugPrint('Upload failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Upload exception: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final Map<String, dynamic> payload = Map<String, dynamic>.from(_originalData);

      payload['name'] = _nameController.text.trim();
      payload['gstNumber'] = _gstController.text.trim();
      payload['address'] = _addressController.text.trim();
      payload['fssaiNo'] = _fssaiController.text.trim();
      payload['licenceNo'] = _licenseController.text.trim();
      payload['gstType'] = int.tryParse(_selectedGstType ?? '1') ?? 1;
      payload['phoneNo'] = _phoneController.text.trim();
      payload['email'] = _emailController.text.trim();
      payload['tableCount'] = int.tryParse(_tableCountController.text.trim()) ?? 0;
      payload['logoUrl'] = _imageUrl ?? (payload['logoUrl'] ?? '');

      if (_originalData.containsKey('id')) {
        payload['id'] = _originalData['id'];
      }
      final url = AppConfig.backendUrl;
      final res = await http.put(
        Uri.parse('$url/api/v1/business'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        try {
          final Map<String, dynamic> body = jsonDecode(res.body);
          if (body['status'] == 'success' && body['data'] != null) {
            _originalData = Map<String, dynamic>.from(body['data']);
            setState(() {
              _imageUrl = _originalData['logoUrl']?.toString();
              _tableCountController.text = _originalData['tableCount']?.toString() ?? _tableCountController.text;
              _licenseController.text = _originalData['licenceNo']?.toString() ?? _licenseController.text;
            });
          }
        } catch (_) {}
        businessNameNotifier.value = payload['name']?.toString() ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business updated successfully')),
        );
      } else {
        _showError('Failed to update: ${res.statusCode}\n${res.body}');
      }
    } catch (e) {
      _showError('Error submitting form: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Widget _buildImagePreview() {
    if (_localImageFile != null && _localImageFile!.existsSync()) {
      return Image.file(_localImageFile!, width: 120, height: 120, fit: BoxFit.cover);
    }
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return Image.network(_imageUrl!, width: 120, height: 120, fit: BoxFit.cover);
    }
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.business, size: 48, color: Colors.grey.shade400),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (v) {
          if (v == null || v.isEmpty) return 'This field is required';
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedGstType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
          ),
        ),
        items: gstTypes.entries
            .map((e) =>
                DropdownMenuItem<String>(value: e.value, child: Text(e.key)))
            .toList(),
        onChanged: (v) => setState(() => _selectedGstType = v),
        validator: (v) => v == null ? 'Please select a GST Type' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Change Business Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo Section
                      Text(
                        "Business Logo",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildImagePreview(),
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _pickAndUploadImage,
                              icon: const Icon(Icons.upload_rounded),
                              label: const Text('Change Logo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade500,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),

                      // Basic Information
                      Text(
                        "Basic Information",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildTextField('Business Name', _nameController),
                      _buildTextField('Address', _addressController, maxLines: 2),
                      _buildTextField('Table Count', _tableCountController, keyboardType: TextInputType.number),

                      SizedBox(height: 20),

                      // Contact Information
                      Text(
                        "Contact Information",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildTextField('Phone Number', _phoneController, keyboardType: TextInputType.phone),
                      _buildTextField('Email', _emailController, keyboardType: TextInputType.emailAddress),

                      SizedBox(height: 20),

                      // Tax & Licensing
                      Text(
                        "Tax & Licensing",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildTextField('GST Number', _gstController),
                      _buildDropdownField('GST Type'),
                      _buildTextField('FSSAI Number', _fssaiController),
                      _buildTextField('License Number', _licenseController),

                      SizedBox(height: 12),

                      // Save Button
                      ButtonTile(
                        label: 'Save Changes',
                        onTap: _submitForm,
                        icon: Icons.save_rounded,
                        bgColor: Colors.blue.shade500,
                        textColor: Colors.white,
                      ),

                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}