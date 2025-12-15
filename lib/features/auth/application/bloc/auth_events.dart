import 'package:equatable/equatable.dart';
// Auth Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}
class AuthInitializeEvent extends AuthEvent {
  const AuthInitializeEvent();
}
class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginEvent({
    required this.email,
    required this.password,
  });
  @override
  List<Object> get props => [email, password];
}
class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}
class AuthRegisterEvent extends AuthEvent {
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String password;
  final String? gender;
  const AuthRegisterEvent({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.password,
    this.gender,
  });
  @override
  List<Object?> get props => [
        firstName,
        lastName,
        username,
        email,
        password,
        gender,
      ];
}
class AuthCheckSessionEvent extends AuthEvent {
  const AuthCheckSessionEvent();
}
class AuthUpdateUserEvent extends AuthEvent {
  final Map<String, dynamic> user;
  const AuthUpdateUserEvent(this.user);
  @override
  List<Object> get props => [user];
}
class AuthForgotPasswordEvent extends AuthEvent {
  final String email;
  const AuthForgotPasswordEvent(this.email);
  @override
  List<Object> get props => [email];
}
class AuthResetPasswordEvent extends AuthEvent {
  final String token;
  final String newPassword;
  const AuthResetPasswordEvent({
    required this.token,
    required this.newPassword,
  });
  @override
  List<Object> get props => [token, newPassword];
}