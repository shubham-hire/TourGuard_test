import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // For International Tourists
  String? _selectedNationality;
  final List<String> _nationalities = ['USA', 'UK', 'Canada', 'Australia', 'France', 'Germany', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      Provider.of<AuthProvider>(context, listen: false)
          .setSelectedDocument(File(image.path));
    }
  }

  void _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.selectedDocument == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please upload the required document')),
        );
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      final data = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'password': _passwordController.text,
        'userType': authProvider.registrationType,
        'nationality': _selectedNationality,
      };

      final success = await authProvider.register(data);

      if (success) {
        context.push('/otp', extra: _phoneController.text);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error ?? 'Registration Failed')),
        );
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
                          // Custom Back Button & Header
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: Icon(Icons.arrow_back, color: AppColors.navyBlue),
                              onPressed: () => context.pop(),
                            ),
                          ),
                          
                          // Government Header
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'GOVERNMENT OF INDIA',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold, // changed to bold
                                    color: AppColors.black,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'MINISTRY OF TOURISM',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold, // changed to bold
                                    color: AppColors.grey,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                SizedBox(height: 24),
                                Image.asset(
                                  'assets/images/icon.png',
                                  height: 60,
                                  width: 60,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.navyBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 32),

                          Consumer<AuthProvider>(
                            builder: (context, auth, child) {
                              return Column(
                                children: [
                                  // User Type Toggle
                                  Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightGrey,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.grey.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => auth.setRegistrationType('domestic'),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(
                                                color: auth.registrationType == 'domestic'
                                                    ? AppColors.white
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: auth.registrationType == 'domestic'
                                                    ? [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.05),
                                                          blurRadius: 4,
                                                          offset: Offset(0, 2),
                                                        )
                                                      ]
                                                    : [],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Domestic',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: auth.registrationType == 'domestic'
                                                        ? AppColors.primaryBlue
                                                        : AppColors.grey,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => auth.setRegistrationType('international'),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(
                                                color: auth.registrationType == 'international'
                                                    ? AppColors.white
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: auth.registrationType == 'international'
                                                    ? [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.05),
                                                          blurRadius: 4,
                                                          offset: Offset(0, 2),
                                                        )
                                                      ]
                                                    : [],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'International',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: auth.registrationType == 'international'
                                                        ? AppColors.primaryBlue
                                                        : AppColors.grey,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 24),

                                  CustomTextField(
                                    label: 'Full Name',
                                    hint: 'As per official ID',
                                    controller: _nameController,
                                    validator: (v) => Validators.validateRequired(v, 'Name'),
                                    prefixIcon: Icons.badge_outlined,
                                  ),
                                  SizedBox(height: 16),
                                  
                                  CustomTextField(
                                    label: 'Email',
                                    hint: 'Enter your email',
                                    controller: _emailController,
                                    validator: Validators.validateEmail,
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.email_outlined,
                                  ),
                                  SizedBox(height: 16),

                                  CustomTextField(
                                    label: 'Phone Number',
                                    hint: 'Enter your phone number',
                                    controller: _phoneController,
                                    validator: Validators.validatePhone,
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: Icons.phone_outlined,
                                  ),
                                  SizedBox(height: 16),

                                  if (auth.registrationType == 'international') ...[
                                      DropdownButtonFormField<String>(
                                        value: _selectedNationality,
                                        decoration: InputDecoration(
                                          labelText: 'Nationality',
                                          prefixIcon: Icon(Icons.public, color: AppColors.grey),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: AppColors.grey.withOpacity(0.3)),
                                          ),
                                          filled: true,
                                          fillColor: AppColors.white,
                                        ),
                                        items: _nationalities.map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        onChanged: (newValue) {
                                          setState(() {
                                            _selectedNationality = newValue;
                                          });
                                        },
                                        validator: (v) => v == null ? 'Please select nationality' : null,
                                      ),
                                      SizedBox(height: 16),
                                  ],

                                  CustomTextField(
                                    label: 'Password',
                                    hint: 'Create a password',
                                    controller: _passwordController,
                                    isPassword: true,
                                    validator: Validators.validatePassword,
                                    prefixIcon: Icons.lock_outline,
                                  ),
                                  SizedBox(height: 16),

                                  CustomTextField(
                                    label: 'Confirm Password',
                                    hint: 'Confirm your password',
                                    controller: _confirmPasswordController,
                                    isPassword: true,
                                    validator: (val) {
                                      if (val != _passwordController.text) return 'Passwords do not match';
                                      return null;
                                    },
                                    prefixIcon: Icons.lock_reset_outlined,
                                  ),
                                  SizedBox(height: 24),

                                  // Document Upload
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceWhite,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.grey.withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          auth.registrationType == 'domestic' 
                                              ? 'Upload Aadhaar Card (Required)' 
                                              : 'Upload Passport Photo (Required)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.navyBlue,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        GestureDetector(
                                          onTap: () => _pickImage(context),
                                          child: Container(
                                            height: 140,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppColors.primaryBlue.withOpacity(0.3),
                                                style: BorderStyle.solid,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: auth.selectedDocument != null
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.file(
                                                      auth.selectedDocument!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.cloud_upload_outlined,
                                                        size: 32,
                                                        color: AppColors.primaryBlue,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        'Tap to browse',
                                                        style: TextStyle(
                                                          color: AppColors.primaryBlue,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 32),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: auth.isLoading ? null : _handleRegistration,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryBlue,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
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
                                              'COMPLETE REGISTRATION',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(height: 30),
                                ],
                              );
                            },
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
