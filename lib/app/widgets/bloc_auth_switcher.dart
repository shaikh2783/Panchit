import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/features/auth/application/bloc/auth_bloc.dart';
import 'package:snginepro/features/auth/application/bloc/auth_states.dart';
import 'package:snginepro/features/auth/presentation/pages/login_page.dart';
import 'package:snginepro/features/feed/presentation/pages/main_navigation_page.dart';
import 'package:snginepro/features/auth/presentation/pages/splash_page.dart';
import 'package:snginepro/update/update.dart';

class BlocAuthSwitcher extends StatelessWidget {
  const BlocAuthSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final locale = Localizations.localeOf(context);
        final isArabic = locale.languageCode.toLowerCase().startsWith('ar');

        Widget child;

        if (state is AuthInitialState || state is AuthLoadingState) {
          child = const SplashPage();
        } else if (state is AuthAuthenticatedState) {
          child = const MainNavigationPage();
        } else if (state is AuthUnauthenticatedState || state is AuthErrorState) {
          child = const LoginPage();
        } else {
          child = const SplashPage();
        }

        return AutoUpdateChecker(
          isArabic: isArabic,
          child: child,
        );
      },
    );
  }
}
