/// App spacing constants - centralized layout measurements
class AppSpacing {
  AppSpacing._(); // Prevent instantiation

  // Base spacing unit (4px)
  static const double unit = 4.0;

  // Standard spacing values
  static const double xs = unit; // 4px
  static const double sm = unit * 2; // 8px
  static const double md = unit * 3; // 12px
  static const double lg = unit * 4; // 16px
  static const double xl = unit * 5; // 20px
  static const double xxl = unit * 6; // 24px
  static const double xxxl = unit * 8; // 32px

  // Specific spacing for common use cases
  static const double screenPadding = lg; // 16px
  static const double cardPadding = lg; // 16px
  static const double listItemPadding = lg; // 16px
  static const double buttonPadding = md; // 12px

  // Vertical spacing
  static const double verticalTiny = xs; // 4px
  static const double verticalSmall = sm; // 8px
  static const double verticalMedium = md; // 12px
  static const double verticalLarge = lg; // 16px
  static const double verticalXLarge = xl; // 20px
  static const double verticalXXLarge = xxl; // 24px
  static const double verticalXXXLarge = xxxl; // 32px

  // Horizontal spacing
  static const double horizontalTiny = xs; // 4px
  static const double horizontalSmall = sm; // 8px
  static const double horizontalMedium = md; // 12px
  static const double horizontalLarge = lg; // 16px
  static const double horizontalXLarge = xl; // 20px
  static const double horizontalXXLarge = xxl; // 24px
  static const double horizontalXXXLarge = xxxl; // 32px

  // Grid spacing
  static const double gridSpacing = md; // 12px
  static const double gridSpacingSmall = sm; // 8px
  static const double gridSpacingLarge = lg; // 16px

  // Section spacing
  static const double sectionSpacing = xxxl; // 32px
  static const double sectionSpacingSmall = xxl; // 24px
  static const double sectionSpacingLarge = unit * 10; // 40px

  // Border radius
  static const double radiusSmall = sm; // 8px
  static const double radiusMedium = md; // 12px
  static const double radiusLarge = lg; // 16px
  static const double radiusXLarge = xl; // 20px
  static const double radiusCircle = 999; // Fully rounded

  // Button dimensions
  static const double buttonHeight = unit * 12; // 48px
  static const double buttonHeightSmall = unit * 10; // 40px
  static const double buttonHeightLarge = unit * 14; // 56px

  // Input field dimensions
  static const double inputHeight = unit * 12; // 48px
  static const double inputHeightSmall = unit * 10; // 40px
  static const double inputHeightLarge = unit * 14; // 56px

  // Icon sizes
  static const double iconSmall = lg; // 16px
  static const double iconMedium = xl; // 20px
  static const double iconLarge = xxl; // 24px
  static const double iconXLarge = unit * 8; // 32px
  static const double iconXXLarge = unit * 10; // 40px

  // Avatar sizes
  static const double avatarSmall = unit * 8; // 32px
  static const double avatarMedium = unit * 10; // 40px
  static const double avatarLarge = unit * 15; // 60px
  static const double avatarXLarge = unit * 20; // 80px

  // Elevation (shadow heights)
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation3 = 4.0;
  static const double elevation4 = 6.0;
  static const double elevation5 = 8.0;

  // Divider thickness
  static const double dividerThin = 0.5;
  static const double dividerThick = 1.0;

  // App bar heights
  static const double appBarHeight = unit * 14; // 56px
  static const double toolbarHeight = unit * 14; // 56px

  // Bottom navigation bar
  static const double bottomNavHeight = unit * 16; // 64px

  // Floating action button
  static const double fabSize = unit * 14; // 56px
  static const double fabSizeSmall = unit * 10; // 40px
  static const double fabSizeLarge = unit * 16; // 64px

  // List tile heights
  static const double listTileHeight = unit * 14; // 56px
  static const double listTileHeightDense = unit * 12; // 48px
  static const double listTileHeightTall = unit * 18; // 72px
}
