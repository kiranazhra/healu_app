import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  UserSession._();
  static final UserSession instance = UserSession._();

  String? idUser;
  String? role;

  bool get isLoggedIn => idUser != null && role != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    idUser = prefs.getString('idUser');
    role = prefs.getString('role');
  }

  Future<void> save(String idUser, String role) async {
    this.idUser = idUser;
    this.role = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('idUser', idUser);
    await prefs.setString('role', role);
  }

  Future<void> clear() async {
    idUser = null;
    role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('idUser');
    await prefs.remove('role');
  }
}