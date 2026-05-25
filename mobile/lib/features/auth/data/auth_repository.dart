import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(secureStorageProvider));
});

class AuthRepository {
  final Dio _dio;
  final SecureStorageService _storage;

  AuthRepository(this._dio, this._storage);

  Future<void> login(String firebaseToken) async {
    final response = await _dio.post(
      ApiConstants.login,
      queryParameters: {'firebase_token': firebaseToken},
    );
    await _saveTokens(response.data);
  }

  Future<void> register({
    required String firebaseToken,
    required String fullName,
    required String gender,
    required DateTime dateOfBirth,
    required TimeOfDay birthTime,
    required String birthPlace,
    String? currentCity,
    required String language,
    required String mobileNumber,
  }) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: {
        'firebase_token': firebaseToken,
        'full_name': fullName,
        'gender': gender,
        'date_of_birth':
            '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}',
        'birth_time':
            '${birthTime.hour.toString().padLeft(2, '0')}:${birthTime.minute.toString().padLeft(2, '0')}:00',
        'birth_place': birthPlace,
        'current_city': currentCity,
        'language_preference': language,
        'mobile_number': mobileNumber.startsWith('+')
            ? mobileNumber
            : '+91$mobileNumber',
        'gdpr_consent': true,
      },
    );
    await _saveTokens(response.data);
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await _storage.saveTokens(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
      userId: data['user']?['id'],
    );
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }
}
