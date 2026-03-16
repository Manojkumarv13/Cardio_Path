import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Constants/AppConstants.dart';

class MyProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final void Function()? onProfileUpdated;
  const MyProfilePage({super.key, this.userData, this.onProfileUpdated});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;

  String? _selectedGender;
  DateTime? _selectedDOB;
  String profileImage =
      "https://ckhealthyheart.com/HeavensTech/CKHealthyHeart/myAPI/uploads/profile.png";

  File? _pickedImage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() {
    final user = widget.userData ?? {};
    _nameController = TextEditingController(text: user["name"] ?? "");
    _ageController = TextEditingController(text: "${user["age"] ?? ""}");
    _contactController = TextEditingController(text: user["contact"] ?? "");
    _emailController = TextEditingController(text: user["email"] ?? "");
    _selectedGender = user["gender"];
    if (user["dob"] != null && user["dob"].isNotEmpty) {
      _selectedDOB = DateTime.tryParse(user["dob"]);
    }
    if (user["profile_image"] != null && user["profile_image"].isNotEmpty) {
      profileImage = user["profile_image"];
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      setState(() => isLoading = false);
    });
  }

  Future<void> _pickImage() async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      if (await Permission.photos.isGranted || await Permission.storage.isGranted) {
        status = PermissionStatus.granted;
      } else {
        if (Platform.operatingSystemVersion.contains("Android 13")) {
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }
      }
    } else {
      status = await Permission.photos.request();
    }

    if (!status.isGranted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Permission Required"),
          content: const Text("Please grant gallery access to select a profile picture."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text("Open Settings")),
          ],
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadProfile() async {
    if (!_formKey.currentState!.validate()) return; // ✅ Validate before upload

    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final userid = prefs.getString("userID") ?? "";
    final token = prefs.getString("token") ?? "";

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${AppConstants.baseUrl}/updateuser.php"),
      );

      request.fields['userid'] = userid;
      request.fields['token'] = token;
      request.fields['name'] = _nameController.text.trim();
      request.fields['age'] = _ageController.text.trim();
      request.fields['gender'] = _selectedGender ?? "";
      request.fields['dateofbirth'] = _selectedDOB != null
          ? "${_selectedDOB!.year}-${_selectedDOB!.month.toString().padLeft(2, '0')}-${_selectedDOB!.day.toString().padLeft(2, '0')}"
          : "";
      request.fields['contact'] = _contactController.text.trim();
      request.fields['email'] = _emailController.text.trim();

      if (_pickedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'profile_image',
          _pickedImage!.path,
        ));
      }

      var response = await request.send();
      var respStr = await response.stream.bytesToString();
      var data = json.decode(respStr);

      setState(() => isLoading = false);

      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        widget.onProfileUpdated?.call(); // ✅ Call parent refresh
        Navigator.pop(context);
        // // ✅ Update SharedPreferences and widget.userData
        // prefs.setString("name", _nameController.text.trim());
        // prefs.setString("age", _ageController.text.trim());
        // prefs.setString("gender", _selectedGender ?? "");
        // prefs.setString("dob", _selectedDOB?.toIso8601String() ?? "");
        // prefs.setString("contact", _contactController.text.trim());
        // prefs.setString("email", _emailController.text.trim());
        // prefs.setString("profile_image", data["profile_image"] ?? profileImage);

        setState(() {
          profileImage = data["profile_image"] ?? profileImage;
          widget.userData?.addAll({
            "name": _nameController.text.trim(),
            "age": _ageController.text.trim(),
            "gender": _selectedGender ?? "",
            "dob": _selectedDOB?.toIso8601String() ?? "",
            "contact": _contactController.text.trim(),
            "email": _emailController.text.trim(),
            "profile_image": data["profile_image"] ?? profileImage,
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Update failed")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _showUpdateDialog() {
    if (!_formKey.currentState!.validate()) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.blueAccent,
        title: Text("Confirm Update",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.white)),
        content: Text("Are you sure you want to update your profile?",
            style: GoogleFonts.poppins(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel",
                  style: GoogleFonts.poppins(color: Colors.white))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadProfile();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: Text("Update",
                style: GoogleFonts.poppins(
                    color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : NetworkImage(profileImage) as ImageProvider,
                        backgroundColor: Colors.grey.shade200,
                      ),
                      Positioned(
                        bottom: 6,
                        right: 8,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text("My Profile",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueAccent.shade700,
                    )),
                const SizedBox(height: 26),
                _buildTextField("Name", _nameController, Icons.person,
                    validator: (v) =>
                    v!.trim().isEmpty ? "Enter your name" : null),
                _buildTextField("Age", _ageController, Icons.cake_outlined,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Enter age";
                      final age = int.tryParse(v);
                      if (age == null || age <= 0 || age > 120) {
                        return "Enter a valid age";
                      }
                      return null;
                    }),
                _buildGenderDropdown(),
                _buildDOBPicker(),
                _buildTextField("Contact Number", _contactController,
                    Icons.phone, validator: (v) {
                      if (v == null || v.isEmpty) return "Enter contact number";
                      if (v.length < 10) return "Enter valid number";
                      return null;
                    }),
                _buildTextField("Mail ID", _emailController, Icons.email,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Enter email";
                      if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v)) {
                        return "Enter valid email";
                      }
                      return null;
                    }),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showUpdateDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: Text("UPDATE PROFILE",
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      IconData icon,
      {String? Function(String?)? validator}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.black54),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.wc, color: Colors.blueAccent),
          labelText: "Gender",
        ),
        items: ["Male", "Female", "Other"]
            .map((g) =>
            DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (value) => setState(() => _selectedGender = value),
        validator: (v) => v == null ? "Select gender" : null,
      ),
    );
  }

  Widget _buildDOBPicker() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        readOnly: true,
        controller: TextEditingController(
          text: _selectedDOB != null
              ? "${_selectedDOB!.year}-${_selectedDOB!.month.toString().padLeft(2, '0')}-${_selectedDOB!.day.toString().padLeft(2, '0')}"
              : "",
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.calendar_month, color: Colors.blueAccent),
          labelText: "Date of Birth",
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (_) => _selectedDOB == null ? "Select DOB" : null,
        onTap: () async {
          DateTime initialDate = _selectedDOB ?? DateTime(2000);
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) setState(() => _selectedDOB = picked);
        },
      ),
    );
  }
}
