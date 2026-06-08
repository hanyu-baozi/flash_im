class LoginType {
  static const String sms = 'sms';
  static const String password = 'password';

  static bool isValid(String value) => value == sms || value == password;
}