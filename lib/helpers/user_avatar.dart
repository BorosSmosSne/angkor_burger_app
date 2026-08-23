import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' as io;

import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/models/user_profile_model.dart';

/// Reusable user avatar widget supporting uploaded local images, memory bytes, assets, network images, and emoji avatars.
class UserAvatar extends StatelessWidget {
  final UserProfileModel profile;
  final double radius;
  final bool showEditBadge;
  final VoidCallback? onEditTap;
  final double borderWidth;
  final Color? borderColor;
  final Color? backgroundColor;
  final double? emojiSize;

  const UserAvatar({
    super.key,
    required this.profile,
    this.radius = 36,
    this.showEditBadge = false,
    this.onEditTap,
    this.borderWidth = 2.0,
    this.borderColor,
    this.backgroundColor,
    this.emojiSize,
  });

  Widget _buildImageContent() {
    // 1. If in-memory image bytes are available (works universally across Web, Mobile, Desktop)
    if (profile.profileImageBytes != null &&
        profile.profileImageBytes!.isNotEmpty) {
      return Image.memory(
        profile.profileImageBytes!,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        errorBuilder: (context, error, stackTrace) => _buildEmojiFallback(),
      );
    }

    final path = profile.profileImagePath;
    if (path == null || path.isEmpty) {
      return _buildEmojiFallback();
    }

    // 2. Network URL, Web Blob URL, or Data URI
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:') ||
        path.startsWith('data:')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        errorBuilder: (context, error, stackTrace) => _buildEmojiFallback(),
      );
    }

    // 3. Bundled Flutter Asset
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        errorBuilder: (context, error, stackTrace) => _buildEmojiFallback(),
      );
    }

    // 4. Flutter Web handling (never invoke dart:io File on Web to avoid Unsupported operation: _Namespace)
    if (kIsWeb) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        errorBuilder: (context, error, stackTrace) => _buildEmojiFallback(),
      );
    }

    // 5. Native platforms (Android, iOS, macOS, Windows, Linux) - File System
    try {
      final file = io.File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          errorBuilder: (context, error, stackTrace) => _buildEmojiFallback(),
        );
      }
    } catch (_) {
      // Fallback if local file access fails
    }

    return _buildEmojiFallback();
  }

  Widget _buildEmojiFallback() {
    return Center(
      child: Text(
        profile.avatarEmoji.isNotEmpty ? profile.avatarEmoji : '👑',
        style: TextStyle(
          fontSize: emojiSize ?? (radius * 0.9),
          height: 1.1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarWidget = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.brandLightRed,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? AppColors.brandRed,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: _buildImageContent(),
      ),
    );

    if (!showEditBadge) {
      return avatarWidget;
    }

    return GestureDetector(
      onTap: onEditTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(radius > 35 ? 6 : 4),
              decoration: BoxDecoration(
                color: AppColors.brandYellow,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt,
                size: radius > 35 ? 15 : 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
