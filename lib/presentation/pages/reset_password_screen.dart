import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../widgets/custom_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String phone;

  const ResetPasswordScreen({super.key, required this.phone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(
        widget.phone,
        _otpController.text,
        _passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
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
                    Icons.radio_button_checked,
                    size: 300,
                    color: AppColors.grey.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),

          // Top Saffron Strip
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
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Back Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: Icon(Icons.arrow_back, color: AppColors.navyBlue),
                              onPressed: () => context.pop(),
                            ),
                          ),
                          
                          SizedBox(height: 10),

                          // Government Header
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
                          
                          SizedBox(height: 30),

                          // Key Icon
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.indiaGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.vpn_key_outlined,
                              size: 48,
                              color: AppColors.indiaGreen,
                            ),
                          ),
                          
                          SizedBox(height: 20),

                          Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyBlue,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Enter the OTP sent to ${widget.phone}\nand create a new password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.grey,
                              height: 1.5,
                            ),
                          ),
                          
                          SizedBox(height: 30),

                          // OTP Input
                          Container(
                            constraints: BoxConstraints(maxWidth: 400),
                            child: CustomTextField(
                              label: 'OTP Code',
                              hint: 'Enter 6-digit OTP',
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.pin_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter OTP';
                                }
                                if (value.length < 4) {
                                  return 'Enter a valid OTP';
                                }
                                return null;
                              },
                            ),
                          ),
                          
                          SizedBox(height: 16),

                          // New Password
                          Container(
                            constraints: BoxConstraints(maxWidth: 400),
                            child: CustomTextField(
                              label: 'New Password',
                              hint: 'Create a strong password',
                              controller: _passwordController,
                              isPassword: true,
                              prefixIcon: Icons.lock_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                          
                          SizedBox(height: 16),

                          // Confirm Password
                          Container(
                            constraints: BoxConstraints(maxWidth: 400),
                            child: CustomTextField(
                              label: 'Confirm Password',
                              hint: 'Re-enter your password',
                              controller: _confirmPasswordController,
                              isPassword: true,
                              prefixIcon: Icons.lock_reset_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ),

                          SizedBox(height: 30),

                          // Reset Button
                          Container(
                            constraints: BoxConstraints(maxWidth: 400),
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _resetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.indiaGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'RESET PASSWORD',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                            ),
                          ),

                          SizedBox(height: 20),

                          // Resend OTP
                          TextButton(
                            onPressed: () async {
                              try {
                                await _authService.forgotPassword(widget.phone);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('OTP resent! Check backend logs.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to resend OTP'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer
                Column(
                  children: [
                    Text(
                      'वसुधैव कुटुम्बकम्',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      'The World Is One Family',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
