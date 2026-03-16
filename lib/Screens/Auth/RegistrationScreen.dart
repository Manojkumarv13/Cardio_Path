import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../Constants/AppConstants.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedSex;
  DateTime? _dob;
  int? _age;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _age = DateTime.now().year - picked.year;
      });
    }
  }
  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse(AppConstants.registerUser);
    final data = {
      "username": _nameController.text.trim(),
      "usertype": "User",
      "mobile": _contactController.text.trim(),
      "email": _emailController.text.trim(),
      "dob": _dob != null ? "${_dob!.year}-${_dob!.month}-${_dob!.day}" : "",
      "gender": _selectedSex,
      "age": _age.toString(),
      "password": _passwordController.text.trim(),
      "lat": "0.0", // can replace with actual GPS value
      "lang": "0.0",
      "deviceid": "device-12345", // get from device_info package
      "appusagetime": "0",
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      final result = jsonDecode(response.body);

      if (result["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Registered Successfully")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${result['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: $e")),
      );
    }
  }


  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.blueAccent) : null,
      labelStyle: GoogleFonts.poppins(color: Colors.black54),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // ✅ ensures gradient shows behind AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Register",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF74ABE2), Color(0xFFE3F2FD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              // 🔹 Elegant gradient inside the card
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF8FBFF), Color(0xFFD6EAF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/profile.png",
                              height: 90,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Create Your Account",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueAccent.shade700,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),

                      // 🔸 Name
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration("Full Name",
                            icon: Icons.person_outline),
                        validator: (v) =>
                        v!.isEmpty ? "Please enter your name" : null,
                      ),
                      const SizedBox(height: 15),

                      // 🔸 Sex
                      DropdownButtonFormField<String>(
                        decoration:
                        _inputDecoration("Gender", icon: Icons.people_alt),
                        value: _selectedSex,
                        items: ["Male", "Female"]
                            .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedSex = v),
                        validator: (v) =>
                        v == null ? "Please select your sex" : null,
                      ),
                      const SizedBox(height: 15),

                      // 🔸 DOB + Age row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: _selectDate,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: _inputDecoration("Date of Birth",
                                      icon: Icons.calendar_month),
                                  controller: TextEditingController(
                                    text: _dob == null
                                        ? ''
                                        : "${_dob!.day}-${_dob!.month}-${_dob!.year}",
                                  ),
                                  validator: (_) => _dob == null
                                      ? "Select date of birth"
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              readOnly: true,
                              decoration: _inputDecoration("Age"),
                              controller: TextEditingController(
                                text: _age?.toString() ?? '',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // 🔸 Contact
                      TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration("Contact Number",
                            icon: Icons.phone_android),
                        validator: (v) => v!.length != 10
                            ? "Enter valid 10-digit number"
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // 🔸 Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration("Mail ID",
                            icon: Icons.email_outlined),
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Please enter email";

                          final email = v.trim();

                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

                          if (!emailRegex.hasMatch(email)) {
                            return "Please enter a valid Gmail ID (e.g. example@gmail.com)";
                          }

                          return null;
                        },

                      ),
                      const SizedBox(height: 15),

                      // 🔸 Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: _inputDecoration("Enter Password",
                            icon: Icons.lock_outline),
                        validator: (v) => v!.length < 4
                            ? "Password must be at least 4 characters"
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // 🔸 Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: _inputDecoration("Confirm Password",
                            icon: Icons.lock_person_outlined),
                        validator: (v) => v != _passwordController.text
                            ? "Passwords do not match"
                            : null,
                      ),
                      const SizedBox(height: 25),

                      // 🔸 Register button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 6,
                          ),
                          onPressed: _register,
                          child: Text(
                            "REGISTER",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Back to Login",
                            style: GoogleFonts.poppins(
                              color: Colors.blueAccent.shade700,
                              fontWeight: FontWeight.w500,
                            ),
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
