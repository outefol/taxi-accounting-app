import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _passwordKey = 'login_password';

/// 密码存放到系统安全存储（Android Keystore / iOS Keychain）。
/// 首次使用时自动把旧版本保存在 SharedPreferences 里的明文密码迁移过来。
class PasswordStore {
  static const _storage = FlutterSecureStorage();

  static Future<String?> read() async {
    final secure = await _storage.read(key: _passwordKey);
    if (secure != null && secure.isNotEmpty) {
      return secure;
    }

    final preferences = await SharedPreferences.getInstance();
    final legacy = preferences.getString(_passwordKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _storage.write(key: _passwordKey, value: legacy);
      await preferences.remove(_passwordKey);
      return legacy;
    }
    return null;
  }

  static Future<void> write(String value) =>
      _storage.write(key: _passwordKey, value: value);

  static Future<void> delete() => _storage.delete(key: _passwordKey);
}
