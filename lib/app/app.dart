import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart'
    as GetTransitions;
import 'dart:ui' show Locale;
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snginepro/core/config/app_config.dart';
import 'package:snginepro/core/config/dynamic_app_config_provider.dart';
import 'package:snginepro/core/config/dynamic_app_config_service.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/theme/app_theme.dart';
import 'package:snginepro/core/localization/app_translations.dart';
import 'package:snginepro/core/localization/localization_controller.dart';
import 'package:snginepro/features/auth/application/auth_notifier.dart';
import 'package:snginepro/features/auth/application/bloc/auth_bloc.dart';
import 'package:snginepro/features/auth/application/bloc/auth_events.dart';
import 'package:snginepro/features/auth/data/datasources/auth_api_service.dart';
import 'package:snginepro/features/auth/data/storage/auth_storage.dart';
import 'package:snginepro/features/auth/domain/auth_repository.dart';
import 'package:snginepro/features/auth/presentation/pages/login_page.dart';
import 'package:snginepro/features/auth/presentation/pages/splash_page.dart';
import 'package:snginepro/features/feed/application/posts_notifier.dart';
import 'package:snginepro/features/feed/application/bloc/posts_bloc.dart';
import 'package:snginepro/features/profile/application/bloc/profile_bloc.dart';
import 'package:snginepro/features/profile/application/bloc/profile_posts_bloc.dart';
import 'package:snginepro/features/pages/application/bloc/page_posts_bloc.dart';
import 'package:snginepro/features/feed/data/datasources/posts_api_service.dart';
import 'package:snginepro/features/feed/domain/posts_repository.dart';
import 'package:snginepro/features/feed/presentation/pages/main_navigation_page.dart';
import 'package:snginepro/features/feed/presentation/pages/post_detail_page.dart';
import 'package:snginepro/features/pages/application/pages_notifier.dart';
import 'package:snginepro/features/pages/application/pages_posts_notifier.dart';
import 'package:snginepro/features/pages/data/datasources/pages_api_service.dart';
import 'package:snginepro/features/pages/domain/pages_repository.dart';
import 'package:snginepro/features/stories/application/stories_notifier.dart';
import 'package:snginepro/features/stories/data/datasources/stories_api_service.dart';
import 'package:snginepro/features/stories/domain/stories_repository.dart';
import 'package:snginepro/features/notifications/application/notifications_notifier.dart';
import 'package:snginepro/features/notifications/data/datasources/notifications_api_service.dart';
import 'package:snginepro/features/notifications/domain/notifications_repository.dart';
import 'package:snginepro/features/comments/application/comments_notifier.dart';
import 'package:snginepro/features/comments/application/bloc/comments_bloc.dart';
import 'package:snginepro/features/notifications/application/bloc/notifications_bloc.dart';
import 'package:snginepro/features/stories/application/bloc/stories_bloc.dart';
import 'package:snginepro/features/pages/application/bloc/pages_bloc.dart';
import 'package:snginepro/features/comments/application/replies_notifier.dart';
import 'package:snginepro/features/comments/data/datasources/comments_api_service.dart';
import 'package:snginepro/features/comments/domain/comments_repository.dart';
import 'package:snginepro/features/profile/data/services/profile_api_service.dart';
import 'package:snginepro/features/reels/application/reels_notifier.dart';
import 'package:snginepro/features/reels/application/bloc/reels_bloc.dart';
import 'package:snginepro/features/reels/data/datasources/reels_api_service.dart';
import 'package:snginepro/features/reels/domain/reels_repository.dart';
import 'package:snginepro/features/groups/application/bloc/groups_bloc.dart';
import 'package:snginepro/features/groups/application/bloc/group_invitations_bloc.dart';
import 'package:snginepro/features/groups/data/datasources/groups_api_service.dart';
import 'package:snginepro/features/groups/data/datasources/groups_management_service.dart';
import 'package:snginepro/features/groups/data/services/group_invitations_service.dart';
import 'package:snginepro/features/groups/domain/groups_repository.dart';
import 'package:snginepro/features/events/application/bloc/events_bloc.dart';
import 'package:snginepro/features/events/data/services/events_service.dart';
import 'package:snginepro/features/market/data/services/market_api_service.dart';
import 'package:snginepro/features/market/domain/market_repository.dart';
import 'package:snginepro/features/market/application/bloc/cart/cart_bloc.dart';
import 'package:snginepro/features/blog/data/services/blog_api_service.dart';
import 'package:snginepro/features/jobs/data/services/jobs_api_service.dart';
import 'package:snginepro/features/jobs/domain/jobs_repository.dart';
import 'package:snginepro/features/blog/domain/blog_repository.dart';
import 'package:snginepro/features/funding/data/services/funding_api_service.dart';
import 'package:snginepro/features/funding/domain/funding_repository.dart';
import 'package:snginepro/features/offers/data/services/offers_api_service.dart';
import 'package:snginepro/features/offers/domain/offers_repository.dart';
import 'package:snginepro/features/wallet/data/services/wallet_api_service.dart';
import 'package:snginepro/features/wallet/domain/wallet_repository.dart';
import 'package:snginepro/features/ads/data/services/ads_api_service.dart';
import 'package:snginepro/features/ads/domain/ads_repository.dart';
import 'package:snginepro/features/ads/presentation/pages/ads_campaigns_page.dart';
import 'package:snginepro/features/ads/presentation/pages/create_campaign_page.dart';
import 'package:snginepro/features/boost/data/services/boost_api_service.dart';
import 'package:snginepro/features/boost/domain/boost_repository.dart';
class App extends StatelessWidget {
  const App({super.key, required this.sharedPreferences});
  final SharedPreferences sharedPreferences;
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: appConfig),
        Provider<SharedPreferences>.value(value: sharedPreferences),
        Provider<ApiClient>(
          create: (context) => ApiClient(config: context.read<AppConfig>()),
          dispose: (_, client) => client.dispose(),
        ),
        Provider<AuthStorage>(
          create: (context) => AuthStorage(context.read<SharedPreferences>()),
        ),
        Provider<AuthApiService>(
          create: (context) => AuthApiService(context.read<ApiClient>()),
        ),
        Provider<AuthRepository>(
          create: (context) => AuthRepository(context.read<AuthApiService>()),
        ),
        Provider<PostsApiService>(
          create: (context) => PostsApiService(context.read<ApiClient>()),
        ),
        Provider<PostsRepository>(
          create: (context) => PostsRepository(context.read<PostsApiService>()),
        ),
        Provider<StoriesApiService>(
          create: (context) => StoriesApiService(context.read<ApiClient>()),
        ),
        Provider<StoriesRepository>(
          create: (context) =>
              StoriesRepository(context.read<StoriesApiService>()),
        ),
        Provider<PagesApiService>(
          create: (context) => PagesApiService(context.read<ApiClient>()),
        ),
        Provider<PagesRepository>(
          create: (context) => PagesRepository(context.read<PagesApiService>()),
        ),
        Provider<NotificationsApiService>(
          create: (context) =>
              NotificationsApiService(context.read<ApiClient>()),
        ),
        Provider<NotificationsRepository>(
          create: (context) =>
              NotificationsRepository(context.read<NotificationsApiService>()),
        ),
        Provider<CommentsApiService>(
          create: (context) => CommentsApiService(context.read<ApiClient>()),
        ),
        Provider<CommentsRepository>(
          create: (context) =>
              CommentsRepository(context.read<CommentsApiService>()),
        ),
        Provider<ProfileApiService>(
          create: (context) => ProfileApiService(context.read<ApiClient>()),
        ),
        Provider<ReelsApiService>(
          create: (context) => ReelsApiService(context.read<ApiClient>()),
        ),
        Provider<ReelsRepository>(
          create: (context) => ReelsRepository(context.read<ReelsApiService>()),
        ),
        Provider<GroupsApiService>(
          create: (context) => GroupsApiService(context.read<ApiClient>()),
        ),
        Provider<GroupsManagementService>(
          create: (context) =>
              GroupsManagementService(context.read<ApiClient>()),
        ),
        Provider<GroupsRepository>(
          create: (context) => GroupsRepository(
            context.read<GroupsApiService>(),
            context.read<GroupsManagementService>(),
          ),
        ),
        Provider<GroupInvitationsService>(
          create: (context) =>
              GroupInvitationsService(context.read<ApiClient>()),
        ),
        // Events Service
        Provider<EventsService>(
          create: (context) => EventsService(context.read<ApiClient>()),
        ),
        // Market Service & Repository
        Provider<MarketApiService>(
          create: (context) => MarketApiService(context.read<ApiClient>()),
        ),
        Provider<MarketRepository>(
          create: (context) =>
              MarketRepository(context.read<MarketApiService>()),
        ),
        // Blog Service & Repository
        Provider<BlogApiService>(
          create: (context) => BlogApiService(context.read<ApiClient>()),
        ),
        Provider<BlogRepository>(
          create: (context) => BlogRepository(context.read<BlogApiService>()),
        ),
        // Jobs
        Provider<JobsApiService>(
          create: (context) => JobsApiService(context.read<ApiClient>()),
        ),
        Provider<JobsRepository>(
          create: (context) => JobsRepository(context.read<JobsApiService>()),
        ),
        // Funding
        Provider<FundingApiService>(
          create: (context) => FundingApiService(context.read<ApiClient>()),
        ),
        Provider<FundingRepository>(
          create: (context) =>
              FundingRepository(context.read<FundingApiService>()),
        ),
        // Offers
        Provider<OffersApiService>(
          create: (context) => OffersApiService(context.read<ApiClient>()),
        ),
        Provider<OffersRepository>(
          create: (context) =>
              OffersRepository(context.read<OffersApiService>()),
        ),
        // Wallet
        Provider<WalletApiService>(
          create: (context) => WalletApiService(context.read<ApiClient>()),
        ),
        Provider<WalletRepository>(
          create: (context) =>
              WalletRepository(context.read<WalletApiService>()),
        ),
        // Ads / Campaigns
        Provider<AdsApiService>(
          create: (context) => AdsApiService(context.read<ApiClient>()),
        ),
        Provider<AdsRepository>(
          create: (context) => AdsRepository(context.read<AdsApiService>()),
        ),
        // Boost
        Provider<BoostApiService>(
          create: (context) => BoostApiService(context.read<ApiClient>()),
        ),
        Provider<BoostRepository>(
          create: (context) => BoostRepository(context.read<BoostApiService>()),
        ),
        // Dynamic App Config Service
        Provider<DynamicAppConfigService>(
          create: (context) =>
              DynamicAppConfigService(context.read<ApiClient>()),
        ),
        // Keep existing ChangeNotifier providers for gradual migration
        ChangeNotifierProvider<AuthNotifier>(
          create: (context) {
            final notifier = AuthNotifier(
              context.read<AuthRepository>(),
              context.read<AuthStorage>(),
              context.read<ApiClient>(),
            );
            notifier.restoreSession();
            return notifier;
          },
        ),
        ChangeNotifierProvider<PostsNotifier>(
          create: (context) => PostsNotifier(context.read<PostsRepository>()),
        ),
        ChangeNotifierProvider<PagesNotifier>(
          create: (context) => PagesNotifier(context.read<PagesRepository>()),
        ),
        ChangeNotifierProvider<PagesPostsNotifier>(
          create: (context) =>
              PagesPostsNotifier(context.read<PagesRepository>()),
        ),
        ChangeNotifierProvider<StoriesNotifier>(
          create: (context) =>
              StoriesNotifier(context.read<StoriesRepository>()),
        ),
        ChangeNotifierProvider<NotificationsNotifier>(
          create: (context) =>
              NotificationsNotifier(context.read<NotificationsRepository>()),
        ),
        ChangeNotifierProvider<CommentsNotifier>(
          create: (context) =>
              CommentsNotifier(context.read<CommentsRepository>()),
        ),
        ChangeNotifierProvider<RepliesNotifier>(
          create: (context) =>
              RepliesNotifier(context.read<CommentsRepository>()),
        ),
        ChangeNotifierProvider<ReelsNotifier>(
          create: (context) => ReelsNotifier(context.read<ReelsRepository>()),
        ),
        // Dynamic App Config Provider
        ChangeNotifierProvider<DynamicAppConfigProvider>(
          create: (context) {
            final provider = DynamicAppConfigProvider(
              context.read<DynamicAppConfigService>(),
            );
            // بدء تحميل الإعدادات في الخلفية
            provider.loadConfig();
            return provider;
          },
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // Auth Bloc
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
              authStorage: context.read<AuthStorage>(),
            )..add(const AuthInitializeEvent()),
          ),
          // Posts Bloc
          BlocProvider<PostsBloc>(
            create: (context) => PostsBloc(context.read<PostsRepository>()),
          ),
          // Profile Bloc
          BlocProvider<ProfileBloc>(
            create: (context) => ProfileBloc(context.read<ProfileApiService>()),
          ),
          // Comments Bloc
          BlocProvider<CommentsBloc>(
            create: (context) =>
                CommentsBloc(context.read<CommentsRepository>()),
          ),
          // Notifications Bloc
          BlocProvider<NotificationsBloc>(
            create: (context) =>
                NotificationsBloc(context.read<NotificationsRepository>()),
          ),
          // Stories Bloc
          BlocProvider<StoriesBloc>(
            create: (context) => StoriesBloc(context.read<StoriesRepository>()),
          ),
          // Pages Bloc
          BlocProvider<PagesBloc>(
            create: (context) => PagesBloc(context.read<PagesRepository>()),
          ),
          // Profile Posts Bloc
          BlocProvider<ProfilePostsBloc>(
            create: (context) =>
                ProfilePostsBloc(context.read<PostsRepository>()),
          ),
          // Page Posts Bloc
          BlocProvider<PagePostsBloc>(
            create: (context) => PagePostsBloc(context.read<PagesRepository>()),
          ),
          // Reels Bloc
          BlocProvider<ReelsBloc>(
            create: (context) => ReelsBloc(context.read<ReelsRepository>()),
          ),
          // Groups Bloc
          BlocProvider<GroupsBloc>(
            create: (context) => GroupsBloc(context.read<GroupsRepository>()),
          ),
          // Group Invitations Bloc
          BlocProvider<GroupInvitationsBloc>(
            create: (context) =>
                GroupInvitationsBloc(context.read<GroupInvitationsService>()),
          ),
          // Events Bloc
          BlocProvider<EventsBloc>(
            create: (context) => EventsBloc(context.read<EventsService>()),
          ),
          // Cart Bloc
          BlocProvider<CartBloc>(
            create: (context) => CartBloc(context.read<MarketRepository>()),
          ),
        ],
        child: GetBuilder<LocalizationController>(
          builder: (localizationController) => GetMaterialApp(
            title: 'Panchit',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const _AuthSwitcher(),
            defaultTransition: GetTransitions.Transition.cupertino,
            transitionDuration: const Duration(milliseconds: 300),
            // GetX Internationalization
            translations: AppTranslations(),
            locale: localizationController.currentLocale,
            fallbackLocale: const Locale('en', 'US'), // English as fallback
            getPages: [
              // Dynamic post viewer route: /post/:id
              GetPage(
                name: '/post/:id',
                page: () {
                  // Prefer path param, fall back to argument, and extract digits safely
                  final idParam =
                      Get.parameters['id'] ??
                      (Get.arguments is Map
                          ? (Get.arguments['id']?.toString())
                          : Get.arguments?.toString());
                  final digits = RegExp(r'\d+').stringMatch(idParam ?? '');
                  final id = int.tryParse(digits ?? '') ?? 0;
                  return PostDetailPage(postId: id);
                },
              ),
              GetPage(
                name: '/ads/campaigns',
                page: () => const AdsCampaignsPage(),
              ),
              GetPage(
                name: '/ads/campaigns/create',
                page: () => const CreateCampaignPage(),
              ),
              GetPage(
                name: '/ads/campaigns/edit',
                page: () {
                  final args = Get.arguments;
                  final map = (args is Map<String, dynamic>) ? args : (args is Map ? Map<String, dynamic>.from(args) : null);
                  return CreateCampaignPage(initialCampaign: map);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _AuthSwitcher extends StatelessWidget {
  const _AuthSwitcher();
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, auth, _) {
        if (!auth.isInitialized) {
          return const SplashPage();
        }
        if (auth.isAuthenticated) {
          return const MainNavigationPage();
        }
        return const LoginPage();
      },
    );
  }
}
