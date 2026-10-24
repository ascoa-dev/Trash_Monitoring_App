import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:we_monitor/shared/constants/app_colors.dart';
import 'package:we_monitor/shared/constants/app_text_styles.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/services/admin_status.dart';
import 'package:we_monitor/shared/services/user_profile_service.dart';

class UserByline extends StatelessWidget {
  const UserByline({super.key, required this.userId});

  final String userId;

  /// Names are visible only to the owner and admins; everyone else sees an
  /// anonymous byline (no Firestore read, the rules would deny it anyway).
  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser?.uid == userId) return _named();
    return FutureBuilder<bool>(
      future: AdminStatus.isAdmin(),
      builder: (context, snap) =>
          snap.data == true ? _named() : const _AnonymousByline(),
    );
  }

  Widget _named() {
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

class _AnonymousByline extends StatelessWidget {
  const _AnonymousByline();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircleAvatar(
          radius: 8,
          backgroundColor: AppColors.cardBackground,
          child: Icon(Icons.person, size: 11, color: AppColors.accentGreen),
        ),
        const SizedBox(width: 4),
        Text(
          AppStrings.anonymousVolunteer,
          style: AppTextStyles.bodySecondary(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
