import 'dart:io';
import 'package:flutter/material.dart';
import 'package:volunteer_app/core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'available':
        bg = Colors.green.shade50;
        fg = AppTheme.statusGreen;
        icon = Icons.check_circle_outline;
        break;
      case 'in progress':
        bg = Colors.amber.shade50;
        fg = AppTheme.accentAmber;
        icon = Icons.timelapse;
        break;
      case 'completed':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        icon = Icons.task_alt;
        break;
      case 'cancelled':
        bg = Colors.red.shade50;
        fg = AppTheme.alertRed;
        icon = Icons.cancel_outlined;
        break;
      case 'accepted':
        bg = Colors.teal.shade50;
        fg = AppTheme.primaryTeal;
        icon = Icons.how_to_reg;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        icon = Icons.info_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 13 : 16, color: fg),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: isSmall ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class TaskImageThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const TaskImageThumbnail({
    super.key,
    this.imageUrl,
    this.height = 160,
    this.width = double.infinity,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    Widget placeholder() {
      return Container(
        height: height,
        width: width,
        color: Colors.grey.shade200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade500, size: 36),
            const SizedBox(height: 4),
            Text(
              'No image preview',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
      );
    }

    if (url == null || url.isEmpty) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: placeholder(),
      );
    }

    // Check if local file
    final isLocalFile = !url.startsWith('http://') && !url.startsWith('https://');

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: isLocalFile
          ? Image.file(
              File(url),
              height: height,
              width: width,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => placeholder(),
            )
          : Image.network(
              url,
              height: height,
              width: width,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => placeholder(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: height,
                  width: width,
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class VolunteerSpotsBadge extends StatelessWidget {
  final int registered;
  final int required;

  const VolunteerSpotsBadge({
    super.key,
    required this.registered,
    required this.required,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = registered >= required;
    final color = isFull ? AppTheme.alertRed : AppTheme.primaryTeal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_alt_outlined, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$registered/$required Registered',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
