import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/services/user_profile_service.dart';

class UserByline extends StatelessWidget {
  const UserByline({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfileMini?>(
      future: UserProfileService.fetch(userId),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
        final profile = snap.data!;
        final name = '${profile.firstName} ${profile.lastName}'.trim();
        if (name.isEmpty) return const SizedBox.shrink();

        const double avatarSize = 16.0;
        final String? avatarUrl = profile.avatarUrl;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: avatarSize / 2,
              backgroundColor: AppColors.cardBackground,
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl, maxWidth: 60, maxHeight: 60)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      profile.firstName.isNotEmpty
                          ? profile.firstName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: avatarSize * 0.55,
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 4),
            Text(
              'By $name',
              style: AppTextStyles.bodySecondary(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }
}
