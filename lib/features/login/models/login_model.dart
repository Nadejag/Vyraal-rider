class LoginModel {
  const LoginModel({this.phoneNumber = ''});

  final String phoneNumber;

  LoginModel copyWith({String? phoneNumber}) {
    return LoginModel(phoneNumber: phoneNumber ?? this.phoneNumber);
  }
}
