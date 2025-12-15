import 'package:flutter/material.dart';
/// Modern stat item widget with icon and gradient
class ModernStatItem extends StatelessWidget {
  const ModernStatItem({
    super.key,
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    required this.isDark,
  });
  final IconData icon;
  final String count;
  final String label;
  final Color color;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
/// Modern button widget with gradient and animations
class ModernButton extends StatelessWidget {
  const ModernButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.color,
    required this.isDark,
  });
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;
  final Color color;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.8),
                    ],
                  )
                : null,
            color: isPrimary
                ? null
                : isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: isPrimary
                ? null
                : Border.all(
                    color: isDark ? Colors.white24 : Colors.black12,
                    width: 1,
                  ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary
                    ? Colors.white
                    : isDark
                        ? Colors.white
                        : Colors.black87,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? Colors.white
                      : isDark
                          ? Colors.white
                          : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/// Posts section header with modern design
class ModernSectionHeader extends StatelessWidget {
  const ModernSectionHeader({
    super.key,
    required this.title,
    required this.isDark,
  });
  final String title;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
