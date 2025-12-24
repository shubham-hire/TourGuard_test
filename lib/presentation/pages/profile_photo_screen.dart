import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../services/backend_service.dart';
import '../widgets/custom_button.dart';

class ProfilePhotoScreen extends StatefulWidget {
  final String hashId;
  final String userName;
  final String phone;

  const ProfilePhotoScreen({
    Key? key,
    required this.hashId,
    required this.userName,
    required this.phone,
  }) : super(key: key);

  @override
  _ProfilePhotoScreenState createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  File? _capturedPhoto;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _capturedPhoto = File(photo.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    }
  }

  Future<void> _uploadAndContinue() async {
    if (_capturedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please capture a photo first')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await BackendService.uploadProfilePhoto(
        filePath: _capturedPhoto!.path,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile photo uploaded!')),
      );

      // Navigate to dashboard
      context.go('/dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _skipForNow() {
    // Navigate to dashboard without uploading photo
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profile Photo',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),

              // Hash ID Display
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryBlue),
                ),
                child: Column(
                  children: [
                    Text(
                      '🎉 Registration Complete!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Your Unique ID',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    SelectableText(
                      widget.hashId,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Instructions
              Text(
                'Take a Profile Photo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _capturedPhoto == null
                    ? 'Capture a clear photo of yourself for your profile'
                    : 'Looking good! You can retake or continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),

              SizedBox(height: 32),

              // Photo Preview
              if (_capturedPhoto != null)
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.primaryBlue, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(97),
                    child: Image.file(
                      _capturedPhoto!,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.grey.withOpacity(0.3), width: 2),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 100,
                    color: AppColors.grey,
                  ),
                ),

              Spacer(),

              // Action Buttons
              if (_capturedPhoto == null)
                CustomButton(
                  text: '📸 Take Photo',
                  onPressed: _capturePhoto,
                )
              else ...[
                CustomButton(
                  text: 'Continue',
                  onPressed: _uploadAndContinue,
                  isLoading: _isUploading,
                ),
                SizedBox(height: 12),
                TextButton(
                  onPressed: _isUploading ? null : _capturePhoto,
                  child: Text(
                    'Retake Photo',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              SizedBox(height: 12),

              TextButton(
                onPressed: _isUploading ? null : _skipForNow,
                child: Text(
                  'Skip for Now',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
