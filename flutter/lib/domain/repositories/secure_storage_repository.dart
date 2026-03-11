abstract class SecureStorageRepository {
  Future<void> saveApiKey(String apiKey);
  Future<void> saveSecretKey(String secretKey);
  Future<String?> getApiKey();
  Future<String?> getSecretKey();
  Future<void> deleteKeys();
  Future<bool> hasKeys();
}
