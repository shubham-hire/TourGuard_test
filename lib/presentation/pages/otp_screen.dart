import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../../services/backend_service.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _start = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void startTimer() {
    setState(() {
      _start = 30;
      _canResend = false;
    });
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
            _canResend = true;
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  void _handleVerify() async {
    if (_otpController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid OTP')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Show loading
    setState(() {});
    
    try {
      // Call backend API to verify OTP
      final result = await BackendService.verifyOtp(
        phone: widget.phoneNumber,
        otp: _otpController.text,
      );

      // Show hash ID in a dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('✅ Registration Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your Unique Hash ID:'),
              SizedBox(height: 10),
              SelectableText(
                result['hashId'] ?? 'N/A',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigate directly to dashboard
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/dashboard',
                  (route) => false,
                );
              },
              child: Text('Continue'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
    }
  }

  void _handleResend() async {
    try {
      await BackendService.sendOtp(phone: widget.phoneNumber);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP sent successfully!')),
      );
      startTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend OTP: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verification',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enter the OTP sent to ${widget.phoneNumber}',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.grey,
                ),
              ),
              SizedBox(height: 40),
              CustomTextField(
                label: 'OTP',
                hint: 'Enter 4-digit OTP',
                controller: _otpController,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  return CustomButton(
                    text: 'Verify',
                    onPressed: _handleVerify,
                    isLoading: auth.isLoading,
                  );
                },
              ),
              SizedBox(height: 20),
              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: _handleResend,
                        child: Text(
                          'Resend OTP',
                          style: TextStyle(color: AppColors.primaryBlue),
                        ),
                      )
                    : Text(
                        'Resend OTP in 00:${_start.toString().padLeft(2, '0')}',
                        style: TextStyle(color: AppColors.grey),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
