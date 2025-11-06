import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SetUserPage extends StatefulWidget {
  const SetUserPage({super.key});

  @override
  State<SetUserPage> createState() => _SetUserPageState();
}

class _SetUserPageState extends State<SetUserPage>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _studentNoController = TextEditingController();
  final _courseSectionController = TextEditingController();

  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  /// Submit user details → save immediately → send verification
  Future<void> submitDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final name = _nameController.text.trim();
    final studentNumber = _studentNoController.text.trim();
    final courseSection = _courseSectionController.text.trim();

    if (name.isEmpty || studentNumber.length != 6 || courseSection.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields correctly.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Save data immediately in Firestore
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "name": name,
        "studentNumber": studentNumber,
        "courseSection": courseSection,
        "email": user.email,
        "createdAt": Timestamp.now(),
        "isVerified": false,
      });

      // ✅ Send email verification
      await user.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Verification email sent! Check your BISU inbox to continue."),
        ),
      );

      // Optional: redirect to login page
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _studentNoController.dispose();
    _courseSectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff2E3192), Color(0xff1BFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Student Information",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Name
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputStyle("Full Name"),
                        ),
                        const SizedBox(height: 18),

                        // Student Number
                        TextField(
                          controller: _studentNoController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputStyle("6-digit Student Number"),
                        ),
                        const SizedBox(height: 18),

                        // Course & Section
                        TextField(
                          controller: _courseSectionController,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                              _inputStyle("Course & Section (e.g., BSIT 3A)"),
                        ),
                        const SizedBox(height: 40),

                        // Submit Button
                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: submitDetails,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    "Submit & Verify Email",
                                    style: TextStyle(
                                        fontFamily: "Poppins",
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
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
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white70),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white),
      ),
      counterText: "",
    );
  }
}
