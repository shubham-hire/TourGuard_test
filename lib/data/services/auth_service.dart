import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  // Placeholder for API base URL (Not used for OTP anymore)
  static const String baseUrl = 'http://10.239.172.40:3000/api/auth';
  
  // In-memory storage for demo purposes (Simulating a database)
  static final Map<String, Map<String, dynamic>> _userDatabase = {};
  
  // Store registration data temporarily during OTP flow
  static Map<String, dynamic>? _tempRegistrationData;
  static String? _currentOtp;

  Future<Map<String, dynamic>> login(String email, String password) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    
    // Check against "Database"
    if (_userDatabase.containsKey(email)) {
      final storedUser = _userDatabase[email]!;
      if (storedUser['password'] == password) {
        return {
          'success': true,
          'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': storedUser['user'],
        };
      } else {
         throw Exception('Incorrect password. Please enter the right password.');
      }
    } else if (email == 'test@example.com' && password == 'password') {
       // Default test user
       return {
        'success': true,
        'token': 'mock_token_test',
        'user': {
          'id': '1',
          'name': 'Test User',
          'email': email,
          'phone': '1234567890',
          'userType': 'indian',
        }
      };
    } else {
      throw Exception('Email not found. Please enter the right email or register.');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data, File? document) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    
    // Store data temporarily
    _tempRegistrationData = {
      ...data,
      'documentPath': document?.path,
    };
    
    // Generate dynamic OTP locally
    final random = Random();
    _currentOtp = (1000 + random.nextInt(9000)).toString();
    
    // Print OTP to Console
    print('----------------------------------------');
    print('🔐 OTP FOR ${data['phone']}: $_currentOtp');
    print('----------------------------------------');
    
    return {
      'success': true,
      'message': 'OTP sent successfully',
    };
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    await Future.delayed(Duration(seconds: 1));
    
    // Verify against local OTP or backdoor
    if (otp == _currentOtp || otp == '1234') {
      // OTP Verified - Create User in "Database"
      if (_tempRegistrationData != null) {
        final newUser = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': _tempRegistrationData!['name'],
          'email': _tempRegistrationData!['email'],
          'phone': _tempRegistrationData!['phone'],
          'userType': _tempRegistrationData!['userType'],
          'nationality': _tempRegistrationData!['nationality'],
        };

        // Save to "Database"
        _userDatabase[_tempRegistrationData!['email']] = {
          'password': _tempRegistrationData!['password'],
          'user': newUser,
        };
        
        // Clear temp data
        _tempRegistrationData = null;
        _currentOtp = null;

        return {
          'success': true,
          'token': 'mock_token_new',
          'user': newUser,
        };
      } else {
        throw Exception('Session expired. Please register again.');
      }
    } else {
      throw Exception('Invalid OTP. Please try again.');
    }
  }

  Future<void> resendOtp(String phone) async {
    await Future.delayed(Duration(seconds: 1));
    final random = Random();
    _currentOtp = (1000 + random.nextInt(9000)).toString();
    
    print('----------------------------------------');
    print('🔐 RESENT OTP FOR $phone: $_currentOtp');
    print('----------------------------------------');
  }
}
