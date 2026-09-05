import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../feed/data/models/post.dart';
import '../../../feed/presentation/widgets/course_card.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../data/services/courses_api_service.dart';
import 'course_create_page.dart';

/// صفحة الدورات الخاصة بي (My Courses)
class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CoursesApiService _coursesService;

  List<Post> _enrolledCourses = [];
  List<Post> _createdCourses = [];

  bool _isLoadingEnrolled = false;
  bool _isLoadingCreated = false;

  String? _enrolledError;
  String? _createdError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _coursesService = CoursesApiService(context.read<ApiClient>());
    _loadCourses();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
    if (_tabController.index == 0 &&
        _enrolledCourses.isEmpty &&
        !_isLoadingEnrolled) {
      _loadEnrolledCourses();
    } else if (_tabController.index == 1 &&
        _createdCourses.isEmpty &&
        !_isLoadingCreated) {
      _loadCreatedCourses();
    }
  }

  Future<void> _loadCourses() async {
    await _loadEnrolledCourses();
  }

  Future<void> _loadEnrolledCourses() async {
    setState(() {
      _isLoadingEnrolled = true;
      _enrolledError = null;
    });

    try {
      final response = await _coursesService.getCourses();
      final allCourses = response.courses;

      // Filter enrolled courses (courses where user is enrolled but not the creator)
      final enrolled = _filterEnrolled(allCourses);

      if (mounted) {
        setState(() {
          _enrolledCourses = enrolled;
          _isLoadingEnrolled = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _enrolledError = 'my_courses_load_enrolled_error'.tr;
          _isLoadingEnrolled = false;
        });
      }
    }
  }

  Future<void> _loadCreatedCourses() async {
    setState(() {
      _isLoadingCreated = true;
      _createdError = null;
    });

    try {
      final response = await _coursesService.getCourses();
      final allCourses = response.courses;

      // Filter created courses (courses where user is the creator)
      final created = _filterCreated(allCourses);

      if (mounted) {
        setState(() {
          _createdCourses = created;
          _isLoadingCreated = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _createdError = 'my_courses_load_created_error'.tr;
          _isLoadingCreated = false;
        });
      }
    }
  }

  List<Post> _filterEnrolled(List<Post> courses) {
    final auth = context.read<AuthNotifier>();
    final userId = auth.currentUser?['user_id']?.toString();
    if (userId == null) return [];

    // Return courses where user is NOT the creator
    // In a real scenario, you'd check enrollment status from backend
    // For now, we show all courses that are not created by the user
    return courses.where((course) {
      final isCreator =
          course.course?.iOwner == true || course.authorId == userId;
      return !isCreator;
    }).toList();
  }

  List<Post> _filterCreated(List<Post> courses) {
    final auth = context.read<AuthNotifier>();
    final userId = auth.currentUser?['user_id']?.toString();
    if (userId == null) return [];

    // Return courses where user is the creator
    return courses.where((course) {
      return course.course?.iOwner == true || course.authorId == userId;
    }).toList();
  }

  Future<void> _refreshEnrolled() async {
    await _loadEnrolledCourses();
  }

  Future<void> _refreshCreated() async {
    await _loadCreatedCourses();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'my_courses'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              0,
              Spacing.lg,
              Spacing.sm,
            ),
            child: _buildCoursesTabBar(isDark),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CourseCreatePage()),
              );
              // Refresh list if course was created
              if (result == true && mounted) {
                _loadCreatedCourses();
              }
            },
            icon: const Icon(Iconsax.add_circle),
            tooltip: 'my_courses_create'.tr,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Enrolled Courses Tab
          _buildCoursesList(
            courses: _enrolledCourses,
            isLoading: _isLoadingEnrolled,
            error: _enrolledError,
            emptyMessage: 'my_courses_no_enrolled'.tr,
            emptyIcon: Iconsax.book,
            onRefresh: _refreshEnrolled,
          ),

          // Created Courses Tab
          _buildCoursesList(
            courses: _createdCourses,
            isLoading: _isLoadingCreated,
            error: _createdError,
            emptyMessage: 'my_courses_no_created'.tr,
            emptyIcon: Iconsax.edit,
            onRefresh: _refreshCreated,
          ),
        ],
      ),
    );
  }

  /// Standard scrollable pill tab bar shared across the app.
  Widget _buildCoursesTabBar(bool isDark) {
    final tabs = [
      (icon: Iconsax.book, label: 'my_courses_enrolled'.tr),
      (icon: Iconsax.edit, label: 'my_courses_created'.tr),
    ];
    final unselectedColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);

    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return Row(
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final isSelected = _tabController.index == index;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == tabs.length - 1 ? 0 : Spacing.sm,
                ),
                child: GestureDetector(
                  onTap: () => _tabController.animateTo(index),
                  child: AnimatedContainer(
                    duration: AnimDurations.medium,
                    curve: CurvesToken.standard,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isDark
                                  ? AppColors.dividerDark
                                  : AppColors.dividerLight,
                            ),
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 16,
                          color: isSelected ? Colors.white : unselectedColor,
                        ),
                        const SizedBox(width: Spacing.xs),
                        Flexible(
                          child: Text(
                            tab.label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected ? Colors.white : unselectedColor,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Soft gradient circle backdrop for empty/error state icons — matches
  /// the treatment used across the other market/courses pages.
  Widget _buildStateIcon({
    required IconData icon,
    required Color iconColor,
    required List<Color> colors,
  }) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Icon(icon, size: 48, color: iconColor),
    );
  }

  Widget _buildCoursesList({
    required List<Post> courses,
    required bool isLoading,
    required String? error,
    required String emptyMessage,
    required IconData emptyIcon,
    required Future<void> Function() onRefresh,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (error != null) {
      return Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final mutedColor = isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStateIcon(
                  icon: Iconsax.warning_2,
                  iconColor: AppColors.error,
                  colors: [
                    AppColors.error.withValues(alpha: 0.18),
                    AppColors.error.withValues(alpha: 0.08),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: TextStyle(fontSize: 16, color: mutedColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Iconsax.refresh),
                  label: Text('my_courses_retry'.tr),
                ),
              ],
            ),
          );
        },
      );
    }

    if (courses.isEmpty) {
      return Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final mutedColor = isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStateIcon(
                  icon: emptyIcon,
                  iconColor: AppColors.primary,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    AppColors.secondary.withValues(alpha: 0.10),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: TextStyle(fontSize: 16, color: mutedColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    }

    final mediaResolver = context.read<AppConfig>().mediaAsset;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return CourseCard(post: course, mediaResolver: mediaResolver);
        },
      ),
    );
  }
}
