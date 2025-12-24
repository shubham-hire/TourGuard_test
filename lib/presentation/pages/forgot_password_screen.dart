import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.forgotPassword(_phoneController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent! Check backend console for code.'),
            backgroundColor: Colors.green,
          ),
        );
        context.push('/reset-password', extra: _phoneController.text);
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
      resizeToAvoidBottomInset: false,
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
                          
                          SizedBox(height: 20),

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
                          
                          SizedBox(height: 40),

                          // Lock Icon
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_reset_outlined,
                              size: 64,
                              color: AppColors.navyBlue,
                            ),
                          ),
                          
                          SizedBox(height: 24),

                          Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyBlue,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Enter your registered phone number.\nWe\'ll send you a verification code.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.grey,
                              height: 1.5,
                            ),
                          ),
                          
                          SizedBox(height: 40),

                          // Phone Input
                          Container(
                            constraints: BoxConstraints(maxWidth: 400),
                            child: CustomTextField(
                              label: 'Phone Number',
                              hint: 'Enter your registered phone',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                if (value.length < 10) {
                                  return 'Enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                          ),

                          SizedBox(height: 30),

                          // Send OTP Button
                          Container(
                            constraints: BoxConstraints(maxWidth: 400),
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
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
                                      'SEND VERIFICATION CODE',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                            ),
                          ),

                          SizedBox(height: 24),

                          // Back to Login
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text(
                              'Back to Login',
                              style: TextStyle(
                                color: AppColors.navyBlue,
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
