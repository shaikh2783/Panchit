import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/features/auth/application/bloc/auth_bloc.dart';
import 'package:snginepro/features/auth/application/bloc/auth_states.dart';
import 'package:snginepro/features/auth/presentation/pages/login_page.dart';
import 'package:snginepro/features/feed/presentation/pages/main_navigation_page.dart';
import 'package:snginepro/features/auth/presentation/pages/splash_page.dart';
class BlocAuthSwitcher extends StatelessWidget {
  const BlocAuthSwitcher({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitialState || state is AuthLoadingState) {
          return const SplashPage();
        }
        if (state is AuthAuthenticatedState) {
          return const MainNavigationPage();
        }
        if (state is AuthUnauthenticatedState || state is AuthErrorState) {
          return const LoginPage();
        }
        return const SplashPage();
      },
    );
  }
}