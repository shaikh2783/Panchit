// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:snginepro/core/theme/app_colors.dart';
// import 'package:snginepro/core/theme/app_text_styles.dart';
// import 'package:snginepro/core/theme/theme_controller.dart';
// import 'package:snginepro/core/theme/widgets/theme_toggle_button.dart';
// /// Example of using the theme system in the application
// /// This file is for demonstration only and is not used in the app
// class ThemeExamplePage extends StatelessWidget {
//   const ThemeExamplePage({super.key});
//   @override
//   Widget build(BuildContext context) {
//     final ThemeController themeController = Get.find();
//     return Obx(() {
//       final isDark = themeController.isDarkMode;
//       return Scaffold(
//         backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
//         appBar: AppBar(
//           backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
//           title: Text(
//             'Design Examples',
//             style: AppTextStyles.h4(isDark: isDark),
//           ),
//           actions: const [
//             ThemeToggleButton(),
//           ],
//         ),
//         body: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             // Headers Section
//             _buildSection(
//               'Headers',
//               isDark,
//               [
//                 Text('Header H1', style: AppTextStyles.h1(isDark: isDark)),
//                 const SizedBox(height: 8),
//                 Text('Header H2', style: AppTextStyles.h2(isDark: isDark)),
//                 const SizedBox(height: 8),
//                 Text('Header H3', style: AppTextStyles.h3(isDark: isDark)),
//                 const SizedBox(height: 8),
//                 Text('Header H4', style: AppTextStyles.h4(isDark: isDark)),
//                 const SizedBox(height: 8),
//                 Text('Header H5', style: AppTextStyles.h5(isDark: isDark)),
//                 const SizedBox(height: 8),
//                 Text('Header H6', style: AppTextStyles.h6(isDark: isDark)),
//               ],
//             ),
//             const SizedBox(height: 24),
//             // Body Text Section
//             _buildSection(
//               'Body Text',
//               isDark,
//               [
//                 Text('Large text - Large', style: AppTextStyles.bodyLarge(isDark: isDark)),
//                 Text('Medium text - Medium', style: AppTextStyles.bodyMedium(isDark: isDark)),
//                 Text('Small text - Small', style: AppTextStyles.bodySmall(isDark: isDark)),
//               ],
//             ),
//             const SizedBox(height: 24),
//             // Buttons Section
//             _buildSection(
//               'Buttons',
//               isDark,
//               [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () {},
//                         child: const Text('Primary Button'),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () {},
//                         child: const Text('Outlined Button'),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextButton(
//                         onPressed: () {},
//                         child: const Text('Text Button'),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: () {},
//                         icon: const Icon(Icons.add),
//                         label: const Text('With Icon'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             // Cards Section
//             _buildSection(
//               'Cards',
//               isDark,
//               [
//                 Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Card Title',
//                           style: AppTextStyles.h5(isDark: isDark),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'This is a sample text inside the card. It can contain any content.',
//                           style: AppTextStyles.bodyMedium(isDark: isDark),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             // Colors Section
//             _buildSection(
//               'Colors',
//               isDark,
//               [
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: [
//                     _buildColorChip('Primary', AppColors.primary),
//                     _buildColorChip('Secondary', AppColors.secondary),
//                     _buildColorChip('Success', AppColors.success),
//                     _buildColorChip('Error', AppColors.error),
//                     _buildColorChip('Warning', AppColors.warning),
//                     _buildColorChip('Info', AppColors.info),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             // Input Fields Section
//             _buildSection(
//               'Input Fields',
//               isDark,
//               [
//                 TextField(
//                   decoration: InputDecoration(
//                     labelText: 'Name',
//                     hintText: 'Enter your name',
//                     prefixIcon: const Icon(Icons.person),
//                   ),
//                   style: AppTextStyles.input(isDark: isDark),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   decoration: InputDecoration(
//                     labelText: 'Email',
//                     hintText: 'Enter your email',
//                     prefixIcon: const Icon(Icons.email),
//                     errorText: 'Invalid email address',
//                   ),
//                   style: AppTextStyles.input(isDark: isDark),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             // Chips Section
//             _buildSection(
//               'Chips',
//               isDark,
//               [
//                 Wrap(
//                   spacing: 8,
//                   children: [
//                     Chip(
//                       label: const Text('Technology'),
//                       onDeleted: () {},
//                     ),
//                     Chip(
//                       label: const Text('Sports'),
//                       onDeleted: () {},
//                     ),
//                     Chip(
//                       label: const Text('Culture'),
//                       onDeleted: () {},
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             // Switches & Checkboxes Section
//             _buildSection(
//               'Form Controls',
//               isDark,
//               [
//                 SwitchListTile(
//                   title: const Text('Notifications'),
//                   value: true,
//                   onChanged: (value) {},
//                 ),
//                 CheckboxListTile(
//                   title: const Text('Accept Terms & Conditions'),
//                   value: true,
//                   onChanged: (value) {},
//                 ),
//                 RadioListTile(
//                   title: const Text('Option 1'),
//                   value: 1,
//                   groupValue: 1,
//                   onChanged: (value) {},
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             // Post Types Section
//             _buildSection(
//               'Post Type Colors',
//               isDark,
//               [
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: [
//                     _buildPostTypeChip('Text', AppColors.postTypeText),
//                     _buildPostTypeChip('Photo', AppColors.postTypePhoto),
//                     _buildPostTypeChip('Album', AppColors.postTypeAlbum),
//                     _buildPostTypeChip('Video', AppColors.postTypeVideo),
//                     _buildPostTypeChip('Reel', AppColors.postTypeReel),
//                     _buildPostTypeChip('Audio', AppColors.postTypeAudio),
//                     _buildPostTypeChip('File', AppColors.postTypeFile),
//                     _buildPostTypeChip('Poll', AppColors.postTypePoll),
//                     _buildPostTypeChip('Feeling', AppColors.postTypeFeeling),
//                     _buildPostTypeChip('Colored', AppColors.postTypeColored),
//                     _buildPostTypeChip('Offer', AppColors.postTypeOffer),
//                     _buildPostTypeChip('Job', AppColors.postTypeJob),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             // Gradients Section
//             _buildSection(
//               'Gradients',
//               isDark,
//               [
//                 _buildGradientBox('Primary Gradient', AppColors.primaryGradient),
//                 const SizedBox(height: 8),
//                 _buildGradientBox('Secondary Gradient', AppColors.secondaryGradient),
//                 const SizedBox(height: 8),
//                 _buildGradientBox('Story Gradient', AppColors.storyGradient),
//                 const SizedBox(height: 8),
//                 _buildGradientBox('Reel Gradient', AppColors.reelGradient),
//               ],
//             ),
//             const SizedBox(height: 24),
//             // Theme Settings Section
//             _buildSection(
//               'Theme Settings',
//               isDark,
//               [
//                 const ThemeToggleSwitch(),
//                 const Divider(),
//                 const ThemeModeSelector(),
//               ],
//             ),
//             const SizedBox(height: 32),
//           ],
//         ),
//       );
//     });
//   }
//   Widget _buildSection(String title, bool isDark, List<Widget> children) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: isDark ? AppColors.darkShadow : AppColors.lightShadow,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: AppTextStyles.h5(isDark: isDark),
//           ),
//           const SizedBox(height: 16),
//           ...children,
//         ],
//       ),
//     );
//   }
//   Widget _buildColorChip(String label, Color color) {
//     return Chip(
//       label: Text(label),
//       backgroundColor: color,
//       labelStyle: const TextStyle(color: Colors.white),
//     );
//   }
//   Widget _buildPostTypeChip(String label, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: color, width: 1),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 12,
//             height: 12,
//             decoration: BoxDecoration(
//               color: color,
//               shape: BoxShape.circle,
//             ),
//           ),
//           const SizedBox(width: 6),
//           Text(
//             label,
//             style: TextStyle(color: color, fontWeight: FontWeight.w500),
//           ),
//         ],
//       ),
//     );
//   }
//   Widget _buildGradientBox(String label, LinearGradient gradient) {
//     return Container(
//       height: 80,
//       decoration: BoxDecoration(
//         gradient: gradient,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Center(
//         child: Text(
//           label,
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }
