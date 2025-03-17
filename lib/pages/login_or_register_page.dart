import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage>
    with SingleTickerProviderStateMixin {
  // Initially show login page
  bool showLoginPage = true;

  // Animation controller for smooth transitions
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    // Initialize fade animation
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    // Start animation when the page loads
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Toggle between the login and register page
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
      _controller.reset();
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.redAccent, Colors.deepOrangeAccent],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 500),
              child: showLoginPage
                  ? LoginPage(
                      key: ValueKey('LoginPage'),
                      onTap: togglePages,
                    )
                  : RegisterPage(
                      key: ValueKey('RegisterPage'),
                      onTap: togglePages,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}