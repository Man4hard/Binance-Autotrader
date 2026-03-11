import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants.dart';
import '../../domain/repositories/secure_storage_repository.dart';

class SecureStorageRepositoryImpl implements SecureStorageRepository {
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  const SecureStorageRepositoryImpl();

  FlutterSecureStorage get _storage =>
      const FlutterSecureStorage(aOptions: _androidOptions);

  @override
  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(
      key: AppConstants.apiKeyStorageKey,
      value: apiKey,
    );
  }

  @override
  Future<void> saveSecretKey(String secretKey) async {
    await _storage.write(
      key: AppConstants.secretKeyStorageKey,
      value: secretKey,
    );
  }

  @override
  Future<String?> getApiKey() async {
    return _storage.read(key: AppConstants.apiKeyStorageKey);
  }

  @override
  Future<String?> getSecretKey() async {
    return _storage.read(key: AppConstants.secretKeyStorageKey);
  }

  @override
  Future<void> deleteKeys() async {
    await _storage.delete(key: AppConstants.apiKeyStorageKey);
    await _storage.delete(key: AppConstants.secretKeyStorageKey);
  }

  @override
  Future<bool> hasKeys() async {
    final apiKey = await getApiKey();
    final secret = await getSecretKey();
    return apiKey != null &&
        apiKey.isNotEmpty &&
        secret != null &&
        secret.isNotEmpty;
  }
}
