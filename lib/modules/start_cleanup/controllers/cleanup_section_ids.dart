import 'package:we_monitor/shared/constants/app_strings.dart';

/// Stable, language-independent section ids. The values equal the original
/// English titles so drafts that stored `expandedSection` keep working.
/// Never compare against translated text; show [displayTitle] in the UI.
class CleanupSectionIds {
  CleanupSectionIds._();

  static const String basicInformation = 'Basic Information';
  static const String trashCollected = 'Trash Collected';
  static const String photosVideosOptional = 'Photos & Videos (Optional)';

  static String displayTitle(String id) {
    switch (id) {
      case basicInformation:
        return AppStrings.basicInformation;
      case trashCollected:
        return AppStrings.trashCollected;
      case photosVideosOptional:
        return AppStrings.photosVideosOptional;
      default:
        return id;
    }
  }
}
