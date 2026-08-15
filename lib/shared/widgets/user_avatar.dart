import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.email,
    this.size = 36.0,
    this.fontSize = 15.0,
    this.borderWidth = 1.5,
  });

  final String? avatarUrl;
  final String? email;
  final double size;
  final double fontSize;
  final double borderWidth;

  String _getInitial() {
    final effectiveEmail =
        email ?? Supabase.instance.client.auth.currentUser?.email;
    if (effectiveEmail != null && effectiveEmail.isNotEmpty) {
      return effectiveEmail[0].toUpperCase();
    }
    return 'G';
  }

  String? _cleanAvatarUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    return url.trim();
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _getInitial(),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = _cleanAvatarUrl(avatarUrl);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.4),
          width: borderWidth,
        ),
        color: AppColors.surfaceVariant,
      ),
      child: ClipOval(
        child: cleanUrl == null
            ? _buildFallback()
            : Image.network(
                cleanUrl,
                fit: BoxFit.cover,
                headers: kIsWeb
                    ? null
                    : const {
                        'User-Agent':
                            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                      },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildFallback();
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('DEBUG AVATAR: Fallback used for $cleanUrl');
                  return _buildFallback();
                },
              ),
      ),
    );
  }
}
