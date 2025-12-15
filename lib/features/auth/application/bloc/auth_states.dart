import 'package:equatable/equatable.dart';
// Auth States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}
class AuthInitialState extends AuthState {
  const AuthInitialState();
}
class AuthLoadingState extends AuthState {
  const AuthLoadingState();
}
class AuthAuthenticatedState extends AuthState {
  final Map<String, dynamic> user;
  final String token;
  const AuthAuthenticatedState({
    required this.user,
    required this.token,
  });
  @override
  List<Object> get props => [user, token];
  // Helper getters
  String? get userId => user['user_id']?.toString();
  String? get username => user['user_name']?.toString();
  String? get userDisplayName {
    final fullName = user['user_fullname']?.toString();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }
    final firstName = user['user_firstname']?.toString();
    final lastName = user['user_lastname']?.toString();
    final parts = <String>[];
    if (firstName != null && firstName.isNotEmpty) {
      parts.add(firstName);
    }
    if (lastName != null && lastName.isNotEmpty) {
      parts.add(lastName);
    }
    return parts.isNotEmpty ? parts.join(' ') : username;
  }
  String? get userPicture => user['user_picture']?.toString();
  String? get userCover => user['user_cover']?.toString();
  bool get isVerified => user['user_verified'] == true || user['user_verified'] == '1';
}
class AuthUnauthenticatedState extends AuthState {
  const AuthUnauthenticatedState();
}
class AuthErrorState extends AuthState {
  final String message;
  final String? errorCode;
  const AuthErrorState({
    required this.message,
    this.errorCode,
  });
  @override
  List<Object?> get props => [message, errorCode];
}
class AuthRegisterSuccessState extends AuthState {
  final String message;
  const AuthRegisterSuccessState(this.message);
  @override
  List<Object> get props => [message];
}
class AuthPasswordResetRequestedState extends AuthState {
  final String message;
  const AuthPasswordResetRequestedState(this.message);
  @override
  List<Object> get props => [message];
}
class AuthPasswordResetSuccessState extends AuthState {
  final String message;
  const AuthPasswordResetSuccessState(this.message);
  @override
  List<Object> get props => [message];
}
// Loading states for specific actions
class AuthLoginLoadingState extends AuthLoadingState {
  const AuthLoginLoadingState();
}
class AuthRegisterLoadingState extends AuthLoadingState {
  const AuthRegisterLoadingState();
}
class AuthLogoutLoadingState extends AuthLoadingState {
  const AuthLogoutLoadingState();
}
class AuthPasswordResetLoadingState extends AuthLoadingState {
  const AuthPasswordResetLoadingState();
}