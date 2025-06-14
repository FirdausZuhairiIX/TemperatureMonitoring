import 'package:flutter/material.dart';
import 'dart:async';
import 'package:monitoringtemp/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _userNameController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _toddlerNameController = TextEditingController();
  final _toddlerAgeController = TextEditingController();

  String? _firstToddlerId;
  bool _isLoading = true;

  late final DatabaseService _databaseService;
  StreamSubscription? _userDataSub;
  StreamSubscription? _toddlerDataSub;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();

    // 1. Attach listeners BEFORE initializing, just like HomeScreen
    _userDataSub = _databaseService.userData.listen((userData) {
      if (mounted) setState(() {
        _userNameController.text = userData['user_name'] ?? '';
        _userEmailController.text = userData['user_email'] ?? '';
        _isLoading = false;
      });
    });

    _toddlerDataSub = _databaseService.toddlerData.listen((toddlerData) {
      if (mounted) setState(() {
        _toddlerNameController.text = toddlerData['toddler_name'] ?? '';
        _toddlerAgeController.text = (toddlerData['toddler_age'] ?? '').toString();
        _firstToddlerId = toddlerData['toddler_id']?.toString();
        _isLoading = false;
      });
    });

    // 2. Now initialize (this will trigger events in the streams above)
    _databaseService.initialize().catchError((e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    });
  }

  @override
  void dispose() {
    _userDataSub?.cancel();
    _toddlerDataSub?.cancel();
    _databaseService.dispose();
    _userNameController.dispose();
    _userEmailController.dispose();
    _toddlerNameController.dispose();
    _toddlerAgeController.dispose();
    super.dispose();
  }

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate() || _firstToddlerId == null) return;
    try {
      await _databaseService.updateUserData(
        name: _userNameController.text,
        email: _userEmailController.text,
      );
      await _databaseService.updateToddlerData(
        toddlerId: _firstToddlerId!,
        name: _toddlerNameController.text,
        age: int.tryParse(_toddlerAgeController.text) ?? 0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF2A54D5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          const CircleAvatar(
                            radius: 33,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, color: Color(0xFF2A54D5), size: 40),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _userNameController.text.isEmpty
                                ? "Your Name"
                                : _userNameController.text,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userEmailController.text.isEmpty
                                ? "Your email"
                                : _userEmailController.text,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'User Information',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _customTextField(
                        controller: _userNameController,
                        label: 'Your Name',
                        icon: Icons.person,
                        validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 14),
                      _customTextField(
                        controller: _userEmailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Please enter email';
                          if (!value!.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Toddler Information',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _customTextField(
                        controller: _toddlerNameController,
                        label: 'Toddler Name',
                        icon: Icons.child_care,
                      ),
                      const SizedBox(height: 14),
                      _customTextField(
                        controller: _toddlerAgeController,
                        label: 'Toddler Age',
                        icon: Icons.cake,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Please enter age';
                          final age = int.tryParse(value!);
                          if (age == null || age <= 0 || age > 10) {
                            return 'Enter valid age (1-10)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 34),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _updateUserData,
                          icon: const Icon(Icons.save_alt_rounded),
                          label: const Text('Save Changes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              )),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2A54D5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
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

  Widget _customTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w400),
        filled: true,
        fillColor: Colors.white.withOpacity(0.09),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white30, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 1.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      ),
      cursorColor: Colors.white,
    );
  }
}