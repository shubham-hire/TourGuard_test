import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Ensure google_fonts is in pubspec.yaml
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text,
        _passwordController.text,
      );

      if (success) {
        if (mounted) context.go('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error ?? 'Login Failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // Prevent background shift on keyboard open
      body: Stack(
        children: [
          // Background Watermark (Ashoka Emblem)
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/images/ashoka_emblem.jpg',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.radio_button_checked, // Fallback
                    size: 300,
                    color: AppColors.grey.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),

          // Top Saffron Strip (Standard Government Header)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 12,
              color: AppColors.saffron,
            ),
          ),

          // Bottom Green Strip
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 12,
              color: AppColors.indiaGreen,
            ),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Government Header (Text)
                      Text(
                        'GOVERNMENT OF INDIA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'MINISTRY OF TOURISM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey,
                          letterSpacing: 1.0,
                        ),
                      ),
                      
                      SizedBox(height: 40),

                      // App Branding
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined, size: 50, color: AppColors.navyBlue),
                          SizedBox(width: 10),
                          Text(
                            'TourGuard',
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyBlue,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Official Tourist Safety Portal',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.black.withOpacity(0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      SizedBox(height: 60),

                      // Login Fields
                      Container(
                        constraints: BoxConstraints(maxWidth: 400),
                        child: Column(
                          children: [
                            CustomTextField(
                              label: 'Email Address',
                              hint: 'Enter your email',
                              controller: _emailController,
                              validator: Validators.validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                            ),
                            SizedBox(height: 20),
                            CustomTextField(
                              label: 'Password',
                              hint: 'Enter your password',
                              controller: _passwordController,
                              isPassword: true,
                              validator: Validators.validatePassword,
                              prefixIcon: Icons.lock_outline,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      // Login Button
                      Consumer<AuthProvider>(
                        builder: (context, auth, child) {
                          return Container(
                            constraints: BoxConstraints(maxWidth: 400),
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0, // Flat official look
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: auth.isLoading
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'LOGIN',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 24),

                      // Actions
                      Container(
                        constraints: BoxConstraints(maxWidth: 400),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: AppColors.navyBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/register'),
                              child: Text(
                                'Create Account',
                                style: TextStyle(
                                  color: AppColors.navyBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 40),

                      // Footer Emblem Branding
                      Column(
                        children: [
                           // Using the asset for the emblem if feasible, else text
                           Padding(
                             padding: const EdgeInsets.only(bottom: 8.0),
                             child: Text(
                              'वसुधैव कुटुम्बकम्', // Hindi text for authenticity
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                           ),
                           Text(
                            'The World Is One Family',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
