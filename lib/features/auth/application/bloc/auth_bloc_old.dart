import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/features/auth/application/bloc/auth_events.dart';
import 'package:snginepro/features/auth/application/bloc/auth_states.dart';
import 'package:snginepro/features/auth/domain/auth_repository.dart';
import 'package:snginepro/features/auth/data/storage/auth_storage.dart';
import 'package:snginepro/features/auth/domain/models/auth_session.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final AuthStorage _authStorage;

  AuthBloc({
    required AuthRepository authRepository,
    required AuthStorage authStorage,
  })  : _authRepository = authRepository,
        _authStorage = authStorage,
        super(const AuthInitialState()) {
    
    // Register event handlers
    on<AuthInitializeEvent>(_onInitialize);
    on<AuthLoginEvent>(_onLogin);
    on<AuthLogoutEvent>(_onLogout);

    // Removed register, forgotPassword, resetPassword as they don't exist in current repository
  }

  // Initialize authentication state
  Future<void> _onInitialize(
    AuthInitializeEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final session = await _authStorage.readSession();

      if (session != null && session.token.isNotEmpty) {
        emit(AuthAuthenticatedState(
          user: session.user ?? {},
          token: session.token,
        ));
      } else {
        emit(const AuthUnauthenticatedState());
      }
    } catch (e) {
      emit(AuthErrorState(
        message: 'Failed to initialize auth: ${e.toString()}',
      ));
    }
  }

  // Handle login
  Future<void> _onLogin(
    AuthLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoginLoadingState());
    
    try {
      final response = await _authRepository.signIn(
        identity: event.email,
        password: event.password,
        deviceType: 'mobile',
      );

      if (response.isSuccess && response.authToken != null) {
        // Save auth session
        final session = AuthSession(
          token: response.authToken!,
          sessionId: null,
          user: response.user,
        );
        await _authStorage.saveSession(session);

        emit(AuthAuthenticatedState(
          user: response.user ?? {},
          token: response.authToken!,
        ));
      } else {
        emit(AuthErrorState(
          message: response.message ?? 'Login failed',
        ));
      }
    } catch (e) {
      emit(AuthErrorState(
        message: 'Login error: ${e.toString()}',
      ));
    }
  }

  // Handle logout
  Future<void> _onLogout(
    AuthLogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLogoutLoadingState());
    
    try {
      // Clear stored auth data (no logout API call needed for now)
      await _authStorage.clearSession();
      
      emit(const AuthUnauthenticatedState());
    } catch (e) {
      // Even if clearing fails, emit unauthenticated state
      emit(const AuthUnauthenticatedState());
    }
  }
}