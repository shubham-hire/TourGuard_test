import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../services/backend_service.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await BackendService.login(email: email, password: password);

    return {
      'success': true,
      'token': data['token'],
      'user': {
        'id': data['id'],
        'name': data['name'] ?? '',
        'email': data['email'] ?? email,
        'phone': data['phone'] ?? '',
        'hashId': data['hashId'],
        'userType': data['userType'],
        'nationality': data['nationality'],
      },
    };
  }

  Future<Map<String, dynamic>> register(
    Map<String, dynamic> data,
    File? document,
  ) async {
    final result = await BackendService.register(
      name: data['name'],
      email: data['email'],
      phone: data['phone'],
      password: data['password'],
    );

    if (document != null) {
      try {
        await BackendService.uploadProfilePhoto(filePath: document.path);
      } catch (e) {
        debugPrint('Profile upload failed: $e');
      }
    }

    await BackendService.sendOtp(phone: data['phone']);

    return {
      'success': true,
      'message': 'OTP sent successfully',
      'data': result,
    };
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final result = await BackendService.verifyOtp(phone: phone, otp: otp);

    return {
      'success': true,
      'hashId': result['hashId'],
      'token': result['token'],
      'user': {
        'id': result['id'],
        'name': result['name'] ?? '',
        'email': result['email'] ?? '',
        'phone': result['phone'] ?? phone,
        'hashId': result['hashId'],
        'userType': result['userType'],
        'nationality': result['nationality'],
      },
    };
  }

  Future<void> resendOtp(String phone) async {
    await BackendService.sendOtp(phone: phone);
  }

  Future<void> forgotPassword(String phone) async {
    await BackendService.requestPasswordReset(phone: phone);
  }

  Future<void> resetPassword(String phone, String otp, String password) async {
    await BackendService.resetPassword(phone: phone, otp: otp, newPassword: password);
  }
}
