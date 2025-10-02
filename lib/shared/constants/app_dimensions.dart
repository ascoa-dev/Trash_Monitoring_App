class AppDimensions {
  // Padding & Margins
  static const double screenPadding = 24.0;
  static const double verticalPadding = 16.0;
  static const double smallSpacing = 8.0;
  static const double dividerPadding = 12.0;
  // Field & chip spacing
  static const double fieldVerticalSpacing =
      12.0; // spacing between stacked fields
  static const double chipHorizontalPadding =
      4.0; // small chip padding for floating labels
  static const double floatingLabelOffset =
      8.0; // vertical offset for floating label
  static const double socialButtonSpacing = 16.0;
  static const double bottomSpacing = 56.0;

  // Icon Sizes
  static const double socialIconSize = 24.0;

  // Divider
  static const double dividerThickness = 1.0;
  // Short divider side width factor (relative to screen width, ~76px @ 440)
  static const double authDividerSideWidthFactor = 0.173;

  // Screen Height Multipliers
  static const double titleTopSpacing = 0.16;
  static const double titleBottomSpacing = 0.02;
  static const double inputSpacing = 0.01;
  static const double buttonSpacing = 0.03;
  static const double buttonForgotSpacing = 0.002;
  static const double sectionSpacing = 0.02;
  static const double paragraphSpacing = 0.04;
  static const double forgotPasswordIconSize = 0.2;
  static const double halfInputSpacing = 0.003;
  // Forgot Password background image heights (relative to screen height)
  static const double forgotBgTopHeight = 0.235; // ~225px @ 956px ref
  static const double forgotBgBottomHeight = 0.306; // ~293px @ 956px ref
  static const double completeProfileBottomHeight = 0.34;

  // Component Heights
  static const double buttonHeight = 48.0;
  static const double buttonHorizontalPadding = 24.0;
  static const double buttonVerticalPadding = 12.0;

  // Component Shapes
  static const double borderRadius = 10.0;
  static const double smallRadius =
      4.0; // small corner radius (e.g., input chips)

  // Input Field constants
  static const double inputFieldHeight = 56.0;
  static const double inputHorizontalPadding = 16.0;
  // CustomInputField spacing
  static const double inputErrorSpacing = 4.0;
  static const double borderWidth = 3.0;
  static const double boxShadowBlurRadius = 4.0;
  static const double boxShadowOffsetX = 0.0;
  static const double boxShadowOffsetY = 4.0;
  // Standard border widths
  static const double inputBorderWidth = 1.5;
  static const double socialOutlinedBorderWidth = 1.5;
  // Larger blur for prominent elements
  static const double prominentBoxShadowBlur = 8.0;
  // Social button layout
  static const double socialIconContainerSize = 32.0;
  static const double socialContentSpacing = 18.0;
  // Small utility spacings and controls
  static const double tinySpacing = 10.0;
  static const double checkboxSize = 24.0;
  static const double checkboxCornerRadius = 5.0;
  // Status dot (used in password checklist)
  static const double statusDotSize = 14.0;
  static const double statusDotBorderWidth = 2.0;
  static const double statusIconSize = 10.0;
  static const double checklistItemSpacing = 2.0;
  // Navigation bar sizing
  static const double navBarHeight = 64.0;
  static const double navBarHorizontalPadding = 24.0;
  static const double navBarIconContainerSize = 40.0;
  static const double navBarActiveIconContainerSize = 44.0;
  static const double navBarIconSize = 24.0;
  static const double navBarIndicatorSize = 6.0;
  static const double navBarBorderRadius = 32.0;
  // How far the nav bar is lifted above the bottom of the screen (in logical px).
  // Increase this value to move the nav bar further up from the screen edge.
  static const double navBarBottomOffset = 56.0;
  // Center add button sizing (slot 3)
  static const double navBarCenterButtonWidth = 64.0;
  static const double navBarCenterButtonHeight = 52.0;
  static const double navBarCenterButtonRadius = 20.0;
  static const double navBarInnerHorizontalPadding = 4.0;
  static const double navBarShadowBlurLarge = 10.0;
  static const double navBarShadowSpreadLarge = 4.0;
  static const double navBarShadowOffsetYLarge = 6.0;
  static const double navBarShadowBlurSmall = 3.0;
  static const double navBarShadowOffsetYSmall = 2.0;
  // Profile screen measurements
  static const double profileContentMaxWidth = 440.0;
  static const double profileAvatarSize = 98.0;
  static const double profileAvatarAccentSize = 70.0;
  static const double profileAvatarIconSize = 46.0;
  static const double profileHeaderTopGap = 56.0;
  static const double profileNameTopGap = 4.0;
  static const double profileSectionSpacing = 20.0;
  static const double profileSectionSupportSpacing = 16.0;
  static const double profileSectionSignoutSpacing = 40.0;
  static const double profileCardSpacing = 8.0;
  static const double profileCardMinHeight = 72.0;
  static const double profileCardWidth = 360.0;
  static const double profileCardPaddingHorizontal = 16.0;
  static const double profileCardPaddingVertical = 0.0;
  static const double profileCardIconSize = 24.0;
  static const double profileCardContentGap = 16.0;
  static const double profileCardLabelSpacing = 0.0;
  static const double profileCaptionSpacing = 4.0;
  static const double profileSignOutHeight = 56.0;
  static const double profileSignOutHorizontalPadding = 24.0;
  static const double profileSignOutIconGap = 16.0;
  static const double profileTopBackgroundHeightFactor = 0.30;
  static const double profileBottomBackgroundHeightFactor = 0.38;

  // Auth header reference sizes (base measurements, scaled in widget)
  static const double authHeaderBaseWidth = 295.0;
  static const double authHeaderBaseHeight = 127.0;
  static const double authHeaderLogoWidth = 187.0;
  static const double authHeaderLogoHeight = 80.0;
  // Auth header precise offsets (base values from Figma - scaled by widget)
  static const double authHeaderTitleWidthOffset =
      18.0; // title width = baseWidth - offset
  static const double authHeaderLogoLeft = 108.0;
  static const double authHeaderLogoTop = 47.0;
  static const double authHeaderByLeft = 125.0;
  static const double authHeaderByTop = 53.0;
  // Auth header typography base sizes (font size / line height in px)
  static const double authHeaderTitleFontSizeBase = 57.0;
  static const double authHeaderTitleLineHeightBase = 64.0;
  static const double authHeaderByFontSizeBase = 22.0;
  static const double authHeaderByLineHeightBase = 30.0;

  // Auth / Login screen spacing multipliers (relative to screen height)
  static const double authHeaderTopSpacing =
      0.24; // large top gap before header
  static const double authScreenSpacerSmall = 0.025; // small vertical gaps
  static const double authScreenSpacerMedium = 0.03; // medium vertical gaps
  static const double authScreenLargeSpacer = 0.08; // larger vertical gaps
  static const double authScreenXLargeSpacer =
      0.10; // extra-large vertical gaps (used sparingly)
  // Dialog / overlay dimensions
  static const double dialogWidth = 320.0;
  static const double dialogHeight = 300.0;
  static const double dialogRadius = 28.0;
  static const double dialogHorizontalPadding = 24.0;
  static const double dialogTopPadding = 24.0;
  static const double dialogBottomPadding = 20.0;
  // Dialog typography
  static const double dialogTitleFontSize = 28.0;
  static const double dialogTitleLineHeight = 40.0;
  static const double dialogBodyFontSize = 16.0;
  static const double dialogBodyLineHeight = 22.0;
  static const double dialogTitleLetterSpacing = 0.1;
  static const double dialogBodyLetterSpacing = 0.1;
  static const double dialogButtonLetterSpacing = 0.1;
  // Dialog hero
  static const double dialogHeroSize = 80.0;
  // Email verification screen - large icon size
  static const double emailVerificationIconSize = 100.0;
  // Dialog action font size
  static const double dialogActionFontSize = 14.0;
  // Checklist / small helper font sizes
  static const double checklistFontSize = 12.0;
  // Avatar / profile sizes
  static const double avatarDiameter = 110.0;
  static const double avatarIconSize = 58.0;
  static const double avatarEditButtonSize = 32.0;
  static const double avatarEditIconSize = 16.0;
  static const double avatarEditOffsetBottom = 4.0;
  static const double avatarEditOffsetRight = 8.0;
  static const double avatarEditBorderWidth = 1.2;
  // Typography-specific sizes used in a few screens
  static const double heading2FontSize = 28.0;
  static const double subtitleFontSize = 16.0;
  static const double linkFontSize = 13.0;
  // Input-related font sizes
  static const double inputFontSize = 16.0;
  static const double floatingLabelFontSize = 13.0;
  static const double supportTextFontSize = 13.0;
  // Country selector / small controls
  static const double flagEmojiSize = 22.0;
  static const double selectorIconSize = 20.0;
  static const double selectorSmallGap = 6.0;
  // Dialog image defaults (for non-square assets)
  static const double dialogImageWidth = 134.0;
  static const double dialogImageHeight = 94.0;
  // Dialog decorative background (internal, fixed styling)
  static const double dialogDecorativeBgHeight = 224.0; // ~223.5px from Figma
  static const double dialogDecorativeBgOpacity = 0.27; // subtle overlay
  // Input border widths
  static const double inputBorderWidthFocused = 2.4;
  static const double inputBorderWidthError = 2.8;
  // Common icon sizes
  static const double iconBackSize = 40.0;

  // Prevent instantiation
  AppDimensions._();
}
