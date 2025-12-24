import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_button.dart';

class SuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 100,
              color: Colors.green,
            ),
            SizedBox(height: 24),
            Text(
              'Registration Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Your account has been created successfully.\nPlease login to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.grey,
              ),
            ),
            SizedBox(height: 40),
            CustomButton(
              text: 'Go to Login',
              onPressed: () {
                // Navigate to Login using GoRouter
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
