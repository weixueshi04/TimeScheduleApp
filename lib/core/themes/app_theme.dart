import 'package:flutter/cupertino.dart';

/// FocusLife APP主题配置（iOS风格）
///
/// 提供统一的颜色、字体、间距等设计规范
class AppTheme {
  // ==================== 颜色方案 ====================

  /// 主色调 - 系统蓝色
  static const Color primaryColor = CupertinoColors.systemBlue;

  /// 辅助色 - 系统绿色
  static const Color secondaryColor = CupertinoColors.systemGreen;

  // 功能色
  /// 成功色
  static const Color successColor = CupertinoColors.systemGreen;

  /// 警告色
  static const Color warningColor = CupertinoColors.systemOrange;

  /// 危险/错误色
  static const Color dangerColor = CupertinoColors.systemRed;

  /// 信息色
  static const Color infoColor = CupertinoColors.systemBlue;

  // 背景色
  /// 主背景色
  static const Color backgroundColor = CupertinoColors.systemBackground;

  /// 卡片背景色
  static const Color cardColor = CupertinoColors.secondarySystemBackground;

  /// 分组背景色
  static const Color groupedBackgroundColor = CupertinoColors.systemGroupedBackground;

  // 文字颜色
  /// 主要文字色
  static const Color primaryTextColor = CupertinoColors.label;

  /// 次要文字色
  static const Color secondaryTextColor = CupertinoColors.secondaryLabel;

  /// 三级文字色
  static const Color tertiaryTextColor = CupertinoColors.tertiaryLabel;

  /// 占位符文字色
  static const Color placeholderTextColor = CupertinoColors.placeholderText;

  // 分隔线颜色
  /// 分隔线色
  static const Color separatorColor = CupertinoColors.separator;

  // ==================== 字体大小 ====================

  /// 大标题 - 28pt
  static const double fontSizeTitle = 28.0;

  /// 副标题 - 20pt
  static const double fontSizeSubtitle = 20.0;

  /// 正文 - 16pt
  static const double fontSizeBody = 16.0;

  /// 说明文字 - 14pt
  static const double fontSizeCaption = 14.0;

  /// 小字 - 12pt
  static const double fontSizeSmall = 12.0;

  // ==================== 字体粗细 ====================

  /// 粗体
  static const FontWeight fontWeightBold = FontWeight.w700;

  /// 半粗体
  static const FontWeight fontWeightSemibold = FontWeight.w600;

  /// 中等
  static const FontWeight fontWeightMedium = FontWeight.w500;

  /// 常规
  static const FontWeight fontWeightRegular = FontWeight.w400;

  /// 细体
  static const FontWeight fontWeightLight = FontWeight.w300;

  // ==================== 间距 ====================

  /// 超小间距 - 4px
  static const double spacingXS = 4.0;

  /// 小间距 - 8px
  static const double spacingS = 8.0;

  /// 中间距 - 12px
  static const double spacingM = 12.0;

  /// 大间距 - 16px
  static const double spacingL = 16.0;

  /// 超大间距 - 24px
  static const double spacingXL = 24.0;

  /// 巨大间距 - 32px
  static const double spacingXXL = 32.0;

  // ==================== 圆角 ====================

  /// 小圆角 - 8px
  static const double radiusS = 8.0;

  /// 中圆角 - 12px
  static const double radiusM = 12.0;

  /// 大圆角 - 16px
  static const double radiusL = 16.0;

  /// 圆形
  static const double radiusCircle = 999.0;

  // ==================== 组件尺寸 ====================

  /// 按钮高度（最小点击区域）
  static const double buttonHeight = 44.0;

  /// 输入框高度
  static const double inputHeight = 44.0;

  /// 列表项高度
  static const double listItemHeight = 56.0;

  /// 导航栏高度
  static const double navBarHeight = 44.0;

  /// TabBar高度
  static const double tabBarHeight = 50.0;

  // ==================== 阴影 ====================

  /// 轻微阴影
  static const BoxShadow lightShadow = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 8.0,
    offset: Offset(0, 2),
  );

  /// 中等阴影
  static const BoxShadow mediumShadow = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 12.0,
    offset: Offset(0, 4),
  );

  // ==================== 主题数据 ====================

  /// 浅色主题
  static CupertinoThemeData get lightTheme {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      primaryContrastingColor: CupertinoColors.white,
      scaffoldBackgroundColor: backgroundColor,
      barBackgroundColor: cardColor,
      textTheme: CupertinoTextThemeData(
        primaryColor: primaryTextColor,
        textStyle: TextStyle(
          fontSize: fontSizeBody,
          color: primaryTextColor,
          fontWeight: fontWeightRegular,
        ),
        actionTextStyle: TextStyle(
          fontSize: fontSizeBody,
          color: primaryColor,
          fontWeight: fontWeightMedium,
        ),
        navTitleTextStyle: TextStyle(
          fontSize: fontSizeSubtitle,
          color: primaryTextColor,
          fontWeight: fontWeightSemibold,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontSize: fontSizeTitle,
          color: primaryTextColor,
          fontWeight: fontWeightBold,
        ),
      ),
    );
  }

  /// 深色主题（暂时使用浅色主题，后续可扩展）
  static CupertinoThemeData get darkTheme {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      primaryContrastingColor: CupertinoColors.black,
      scaffoldBackgroundColor: CupertinoColors.black,
      barBackgroundColor: CupertinoColors.darkBackgroundGray,
      textTheme: CupertinoTextThemeData(
        primaryColor: CupertinoColors.white,
        textStyle: TextStyle(
          fontSize: fontSizeBody,
          color: CupertinoColors.white,
          fontWeight: fontWeightRegular,
        ),
      ),
    );
  }

  // ==================== 常用文本样式 ====================

  /// 大标题样式
  static const TextStyle titleStyle = TextStyle(
    fontSize: fontSizeTitle,
    fontWeight: fontWeightBold,
    color: primaryTextColor,
  );

  /// 副标题样式
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: fontSizeSubtitle,
    fontWeight: fontWeightSemibold,
    color: primaryTextColor,
  );

  /// 正文样式
  static const TextStyle bodyStyle = TextStyle(
    fontSize: fontSizeBody,
    fontWeight: fontWeightRegular,
    color: primaryTextColor,
  );

  /// 说明文字样式
  static const TextStyle captionStyle = TextStyle(
    fontSize: fontSizeCaption,
    fontWeight: fontWeightRegular,
    color: secondaryTextColor,
  );

  /// 小字样式
  static const TextStyle smallStyle = TextStyle(
    fontSize: fontSizeSmall,
    fontWeight: fontWeightRegular,
    color: secondaryTextColor,
  );
}
