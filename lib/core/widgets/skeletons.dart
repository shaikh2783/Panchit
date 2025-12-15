import 'package:flutter/material.dart';
import 'package:get/get.dart';
class SkeletonBox extends StatelessWidget {
  final double height;
  final double width;
  final double radius;
  const SkeletonBox({super.key, this.height = 16, this.width = double.infinity, this.radius = 8});
  @override
  Widget build(BuildContext context) {
    final base = Get.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
class SkeletonProductCard extends StatelessWidget {
  const SkeletonProductCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            // Image placeholder
            SkeletonBox(height: 120, radius: 10),
            SizedBox(height: 8),
            // Title lines
            SkeletonBox(height: 14, width: 140),
            SizedBox(height: 6),
            SkeletonBox(height: 14, width: 100),
            Spacer(),
            // Price row
            SkeletonBox(height: 16, width: 80),
            SizedBox(height: 4),
            SkeletonBox(height: 12, width: 60),
          ],
        ),
      ),
    );
  }
}
class SkeletonProductGrid extends StatelessWidget {
  final int itemCount;
  const SkeletonProductGrid({super.key, this.itemCount = 6});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => const SkeletonProductCard(),
    );
  }
}
