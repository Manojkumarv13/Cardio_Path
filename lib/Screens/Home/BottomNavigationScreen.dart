import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Constants/Lists.dart';
import '../../Splash_Screen.dart';
import '../Constants/AppConstants.dart';
import '../Profile/MyProfilePage.dart';
import 'DoDontsTabsPage.dart';
import 'ExerciseTabsPage.dart';

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
  int _currentIndex = 0;
  String _selectedLanguage = 'English';
  String userName = "User";
  String profileImage = "${AppConstants.baseUrl}/uploads/profile.png";
  String? userId;
  String? token;
  Map<String, dynamic>? userDetails;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
    _loadUserData();
    _fetchExercises();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// ✅ Load saved language from SharedPreferences
  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('language') ?? 'English';
    setState(() => _selectedLanguage = savedLang);
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userID");
    token = prefs.getString("token");

    if (token != null && token!.isNotEmpty) {
      await _fetchUserDetails();
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (mounted && token != null && token!.isNotEmpty) {
        await _fetchUserDetails();
        await _fetchExercises();
      }
    });
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text("Select Language",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text("English"),
              value: "English",
              groupValue: _selectedLanguage,
              onChanged: (value) async {
                if (value != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('language', value);
                  setState(() => _selectedLanguage = value);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Language changed to English"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            RadioListTile<String>(
              title: const Text("தமிழ் (Tamil)"),
              value: "Tamil",
              groupValue: _selectedLanguage,
              onChanged: (value) async {
                if (value != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('language', value);
                  setState(() => _selectedLanguage = value);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("மொழி தமிழாக மாற்றப்பட்டது"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Fetch user details
  Future<void> _fetchUserDetails() async {
    try {
      if (token == null || userId == null) return;

      final response = await http.post(
        Uri.parse("${AppConstants.baseUrl}/getuserdetails.php"),
        body: {"userid": userId, "token": token},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data["status"] == "success") {
          setState(() {
            final user = data["user"];
            userName = user["name"] ?? "User";
            profileImage = user["profile_image"] ??
                "${AppConstants.baseUrl}/uploads/profile.png";
            userDetails = user;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching user details: $e");
    }
  }

  /// ✅ Main content builder
  Widget _getCurrentPage() {
    if (userDetails == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // ✅ Show loader until exercises are available
    if (MyLists.WarmUpExercises.isEmpty &&
        MyLists.MainExercises.isEmpty &&
        MyLists.CoolDownExercises.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final pages = [
      ExerciseTabsPage(key: ValueKey(_selectedLanguage),selectedLanguage: _selectedLanguage),
      const DoDontsTabsPage(),
      //DoDontsTabsPage(selectedLanguage: _selectedLanguage),
      MyProfilePage(
        userData: userDetails,
        onProfileUpdated: _startAutoRefresh,
      ),
    ];

    return pages[_currentIndex];
  }


  /// ✅ Fetch exercises
  Future<void> _fetchExercises() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/getExercises.php'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          List allExercises = data['data'] ?? [];

          setState(() {
            MyLists.WarmUpExercises = allExercises
                .where((e) => (e['EXERCISETYPE'] ?? '').toLowerCase() == 'warm up')
                .map((e) => _mapExercise(e))
                .toList();

            MyLists.MainExercises = allExercises
                .where((e) => (e['EXERCISETYPE'] ?? '').toLowerCase() == 'main')
                .map((e) => _mapExercise(e))
                .toList();

            MyLists.CoolDownExercises = allExercises
                .where((e) => (e['EXERCISETYPE'] ?? '').toLowerCase() == 'cool down')
                .map((e) => _mapExercise(e))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('🚨 Error fetching exercises: $e');
    }
  }


  Map<String, dynamic> _mapExercise(Map e) => {
    'name': e['EXERCISENAME'] ?? '',
    'nametamil': e['EXERCISENAMETAMIL'] ?? '',
    'duration': '${e['EXERCISEHOURS'] ?? '0'} mins',
    'procedure': e['EXERCISEPROCEDURE'] ?? '',
    'proceduretamil': e['EXERCISEPROCEDURETAMIL'] ?? '',
    'gif': e['EXERCISEGIF'] ?? 'assets/default_exercise.gif',
  };

  Future<void> logoutUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: _getCurrentPage(),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blueAccent,
      title: Text("CK Healthy Heart",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blueAccent),
            child: Row(
              children: [
                CircleAvatar(radius: 32, backgroundImage: NetworkImage(profileImage)),
                const SizedBox(width: 12),
                Text("Hello, $userName",
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Change Language"),
            onTap: _showLanguageDialog,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout"),
            onTap: () => _showLogoutDialog(),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              logoutUser(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      onTap: (i) => setState(() => _currentIndex = i),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: "Exercises"),
        BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: "Do's & Don'ts"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
      ],
    );
  }
}
