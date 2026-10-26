import 'package:flutter/material.dart';

/// 极简主义主题配置
///
/// 所有外观（经典黑白 / 7 个种子配色 / 莫奈取色 / 毛玻璃）都先产出一个
/// [ColorScheme]，再交给同一个 [_buildTheme] 构建，保证亮/暗模式与各配色下
/// 组件细节一致、强调色贯穿全部组件、表面层级统一。
class AppTheme {
  // 中性色板 - 黑白灰为主
  static const Color _black = Color(0xFF1A1A1A);
  static const Color _darkGray = Color(0xFF333333);
  static const Color _gray = Color(0xFF666666);
  static const Color _lighterGray = Color(0xFFE5E5E5);
  static const Color _offWhite = Color(0xFFF5F5F5);
  static const Color _white = Color(0xFFFFFFFF);

  // 强调色 - 仅用于关键操作
  static const Color accent = Color(0xFF0066FF);
  static const Color error = Color(0xFFDC2626);

  // 字体配置（空字符串 = 系统默认）
  static String _fontFamily = '';
  static void setFontFamily(String value) {
    if (_fontFamily == value) return;
    debugPrint('[Theme] 应用字体: ${value.isEmpty ? '默认' : value}');
    _fontFamily = value;
  }

  // 字重
  static const FontWeight _regular = FontWeight.w400;
  static const FontWeight _medium = FontWeight.w500;
  static const FontWeight _semibold = FontWeight.w600;

  // 统一圆角
  static const double _rCard = 12;
  static const double _rButton = 8;
  static const double _rDialog = 16;
  static const double _rSheet = 20;

  // 配色方案种子色（index 0 = 经典，不使用种子，走中性色板）
  static const List<Color> seedColors = [
    Color(0xFF333333), // 经典
    Color(0xFF3F51B5), // 靛蓝
    Color(0xFF009688), // 薄荷
    Color(0xFFFF8F00), // 琥珀
    Color(0xFFE91E63), // 玫瑰
    Color(0xFF673AB7), // 紫罗兰
    Color(0xFF8B6F47), // 米黄
  ];

  static const List<String> colorSchemeNames = ['经典', '靛蓝', '薄荷', '琥珀', '玫瑰', '紫罗兰', '米黄'];

  // 莫奈动态取色
  static Color? _monetColor;
  static void setMonetColor(Color? color) => _monetColor = color;
  static Color? get monetColor => _monetColor;

  /// 根据配色索引获取浅色主题（index -1 = 莫奈自动取色）
  static ThemeData getLightTheme(int index, {Color? monetColor}) {
    return _buildTheme(_lightScheme(index, monetColor));
  }

  /// 根据配色索引获取暗色主题（index -1 = 莫奈自动取色）
  static ThemeData getDarkTheme(int index, {Color? monetColor}) {
    return _buildTheme(_darkScheme(index, monetColor));
  }

  /// 兼容旧入口
  static ThemeData get lightTheme => getLightTheme(0);
  static ThemeData get darkTheme => getDarkTheme(0);

  static ColorScheme _lightScheme(int index, Color? monetColor) {
    if (index == -1) {
      final c = monetColor ?? _monetColor;
      if (c != null) return ColorScheme.fromSeed(seedColor: c, brightness: Brightness.light);
      return _classicLight;
    }
    if (index <= 0) return _classicLight;
    return ColorScheme.fromSeed(seedColor: seedColors[index], brightness: Brightness.light);
  }

  static ColorScheme _darkScheme(int index, Color? monetColor) {
    if (index == -1) {
      final c = monetColor ?? _monetColor;
      if (c != null) return ColorScheme.fromSeed(seedColor: c, brightness: Brightness.dark);
      return _classicDark;
    }
    if (index <= 0) return _classicDark;
    return ColorScheme.fromSeed(seedColor: seedColors[index], brightness: Brightness.dark);
  }

  // 经典中性浅色（显式给出表面层级，比 fromSeed 更贴近原有黑白灰）
  static const ColorScheme _classicLight = ColorScheme.light(
    primary: _black,
    onPrimary: _white,
    primaryContainer: _lighterGray,
    onPrimaryContainer: _black,
    secondary: _darkGray,
    onSecondary: _white,
    surface: _white,
    onSurface: _black,
    onSurfaceVariant: Color(0xFF5A5A5A),
    error: error,
    onError: _white,
    surfaceContainerLowest: _white,
    surfaceContainerLow: Color(0xFFFAFAFA),
    surfaceContainerHigh: _offWhite,
    surfaceContainerHighest: Color(0xFFF0F0F0),
    outline: _lighterGray,
    outlineVariant: Color(0xFFF0F0F0),
  );

  // 经典中性暗色
  static const ColorScheme _classicDark = ColorScheme.dark(
    primary: _white,
    onPrimary: _black,
    primaryContainer: _darkGray,
    onPrimaryContainer: _white,
    secondary: _offWhite,
    onSecondary: _black,
    surface: _black,
    onSurface: _white,
    onSurfaceVariant: Color(0xFFB3B3B3),
    error: Color(0xFFEF4444),
    onError: _black,
    surfaceContainerLowest: Color(0xFF141414),
    surfaceContainerLow: Color(0xFF202020),
    surfaceContainerHigh: Color(0xFF2A2A2A),
    surfaceContainerHighest: _darkGray,
    outline: _gray,
    outlineVariant: Color(0xFF2E2E2E),
  );

  /// 唯一的主题构建入口：亮/暗、各配色共用，保证组件细节一致
  static ThemeData _buildTheme(ColorScheme scheme) {
    final bool dark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: scheme.surface,
      colorScheme: scheme,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 24,
        iconTheme: IconThemeData(color: scheme.onSurface),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily, fontSize: 18, fontWeight: _semibold,
          color: scheme.onSurface, letterSpacing: 0,
        ),
      ),

      // 卡片：用低一级的表面色与背景拉开层级，圆角统一，细描边兜底
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_rCard),
          side: BorderSide(color: scheme.outlineVariant, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rDialog)),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_rSheet)),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rButton + 4)),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minLeadingWidth: 0, dense: true,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant, thickness: 0.5, space: 0,
      ),

      iconTheme: IconThemeData(color: scheme.onSurface),
      primaryIconTheme: IconThemeData(color: scheme.onPrimary),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return scheme.onSurface.withValues(alpha: 0.3);
          return scheme.onSurface.withValues(alpha: dark ? 0.15 : 0.1);
        }),
        thickness: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return 6.0;
          return 4.0;
        }),
        radius: const Radius.circular(3),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: UnderlineInputBorder(borderSide: BorderSide(color: scheme.outlineVariant, width: 0.5)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: scheme.outlineVariant, width: 0.5)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: scheme.primary, width: 1)),
        errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: scheme.error, width: 0.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        hintStyle: TextStyle(fontFamily: _fontFamily, fontSize: 15, fontWeight: _regular, color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 13, fontWeight: _medium, color: scheme.onSurfaceVariant),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary,
          elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rButton)),
          textStyle: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: _medium, letterSpacing: 0.3),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary,
          elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rButton)),
          textStyle: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: _medium, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rButton)),
          textStyle: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: _medium),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rButton)),
          textStyle: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: _medium),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rDialog)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.onSurfaceVariant;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        side: BorderSide(color: scheme.outlineVariant, width: 0.5),
        labelStyle: TextStyle(
          fontFamily: _fontFamily, fontSize: 13, fontWeight: _medium,
          color: scheme.onSurfaceVariant,
        ),
        shape: const StadiumBorder(),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: scheme.outlineVariant,
        labelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: _medium),
        unselectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: _regular),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        elevation: 0, type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 11, fontWeight: _medium),
        unselectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 11, fontWeight: _regular, color: scheme.onSurfaceVariant),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(
          fontFamily: _fontFamily, fontSize: 14, fontWeight: _regular,
          color: scheme.onSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rButton)),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(_rButton),
        ),
        textStyle: TextStyle(
          fontFamily: _fontFamily, fontSize: 12,
          color: scheme.onSurface,
        ),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.18),
        selectionHandleColor: scheme.primary,
      ),

      textTheme: _textTheme(scheme),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) => TextTheme(
    headlineLarge: TextStyle(
      fontFamily: _fontFamily, fontSize: 32, fontWeight: _semibold,
      color: scheme.onSurface, letterSpacing: 0, height: 1.2,
    ),
    headlineMedium: TextStyle(
      fontFamily: _fontFamily, fontSize: 24, fontWeight: _semibold,
      color: scheme.onSurface, letterSpacing: 0, height: 1.3,
    ),
    headlineSmall: TextStyle(
      fontFamily: _fontFamily, fontSize: 20, fontWeight: _semibold,
      color: scheme.onSurface, letterSpacing: 0, height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontFamily: _fontFamily, fontSize: 16, fontWeight: _regular,
      color: scheme.onSurface, height: 1.6,
    ),
    bodyMedium: TextStyle(
      fontFamily: _fontFamily, fontSize: 15, fontWeight: _regular,
      color: scheme.onSurface, height: 1.5,
    ),
    bodySmall: TextStyle(
      fontFamily: _fontFamily, fontSize: 13, fontWeight: _regular,
      color: scheme.onSurfaceVariant, height: 1.5,
    ),
    labelLarge: TextStyle(
      fontFamily: _fontFamily, fontSize: 14, fontWeight: _medium,
      color: scheme.onSurface,
    ),
    labelMedium: TextStyle(
      fontFamily: _fontFamily, fontSize: 12, fontWeight: _medium,
      color: scheme.onSurfaceVariant,
    ),
    labelSmall: TextStyle(
      fontFamily: _fontFamily, fontSize: 11, fontWeight: _medium,
      color: scheme.onSurfaceVariant, letterSpacing: 0.3,
    ),
  );

  // ===== 媒体状态语义色（已看/在看/想看、已读/在读/想读、通关/在玩/想玩、放弃）=====

  /// 把各媒体类型的状态字符串归一到 4 个语义阶段
  static String _phase(String? status) => switch (status) {
    'watched' || 'read' || 'completed' => 'done',
    'watching' || 'reading' || 'playing' => 'active',
    'want_to_watch' || 'want_to_read' || 'want_to_play' => 'wish',
    'abandoned' => 'abandoned',
    _ => 'none',
  };

  /// 信息区内的柔和状态徽标颜色（淡底 + 主题文字）
  static ({Color bg, Color fg}) statusChipColors(ColorScheme s, String? status) {
    return switch (_phase(status)) {
      'done' => (bg: s.primary, fg: s.onPrimary),
      'active' => (bg: s.primaryContainer, fg: s.onPrimaryContainer),
      'wish' => (bg: s.surfaceContainerHighest, fg: s.onSurfaceVariant),
      'abandoned' => (bg: s.error.withValues(alpha: 0.15), fg: s.error),
      _ => (bg: s.surfaceContainerHighest, fg: s.onSurfaceVariant),
    };
  }

  /// 封面叠层上的状态徽标颜色（实色，保证在图片/深色渐变上醒目可读）
  static ({Color bg, Color fg}) statusOverlayColors(ColorScheme s, String? status) {
    return switch (_phase(status)) {
      'done' => (bg: s.primary, fg: s.onPrimary),
      'active' => (bg: s.secondary, fg: s.onSecondary),
      'wish' => (bg: Colors.white.withValues(alpha: 0.22), fg: Colors.white),
      'abandoned' => (bg: s.error, fg: s.onError),
      _ => (bg: Colors.white.withValues(alpha: 0.22), fg: Colors.white),
    };
  }

  /// 列表/信息区里的状态指示圆点颜色
  static Color statusDotColor(ColorScheme s, String? status) {
    return switch (_phase(status)) {
      'done' => s.primary,
      'active' => s.secondary,
      'abandoned' => s.error,
      _ => s.onSurfaceVariant,
    };
  }

  // 毛玻璃主题 - 半透明面板透出背景的暗色玻璃
  static ThemeData get frostedTheme {
    const bg = Color(0xFF121418);          // 深冷玻璃底（兜底）
    const surface = Color(0x52121418);     // 内容区 32%
    const surfaceHigh = Color(0x8C121418); // 面板 55%
    const surfaceHighest = Color(0xA6121418); // 卡片/输入 65%
    const border = Color(0x1FFFFFFF);      // 白 12%
    const borderStrong = Color(0x2EFFFFFF); // 白 18%
    const onSurface = Colors.white;
    const onSurfaceWeak = Color(0x99FFFFFF); // 白 60%
    const onSurfaceFaint = Color(0x66FFFFFF); // 白 40%
    const accent = Color(0xFF8AB4FF);      // 柔和玻璃蓝

    const scheme = ColorScheme.dark(
      primary: accent,
      onPrimary: Color(0xFF0B0D11),
      primaryContainer: Color(0x338AB4FF),
      onPrimaryContainer: accent,
      secondary: Color(0xFF9AA5B5),
      onSecondary: bg,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceWeak,
      error: Color(0xFFEF6A6A),
      onError: Color(0xFF2A0A0A),
      surfaceContainerLow: surfaceHighest,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHighest,
      outline: borderStrong,
      outlineVariant: border,
    );

    final base = _buildTheme(scheme);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: base.appBarTheme.copyWith(backgroundColor: surfaceHigh),
      cardTheme: CardThemeData(
        color: surfaceHighest, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_rCard),
          side: const BorderSide(color: borderStrong),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0x99121418), // 60% 深色，透出外层磨砂
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_rDialog),
          side: const BorderSide(color: borderStrong),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xCC121418), // 80% 深色（封装 sheet 用 transparent + FrostedPanel）
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: borderStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_rSheet)),
          side: BorderSide(color: borderStrong),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontFamily: _fontFamily, fontSize: 32, fontWeight: _semibold, color: onSurface, letterSpacing: 0, height: 1.2),
        headlineMedium: TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: _semibold, color: onSurface, letterSpacing: 0, height: 1.3),
        headlineSmall: TextStyle(fontFamily: _fontFamily, fontSize: 20, fontWeight: _semibold, color: onSurface, letterSpacing: 0, height: 1.4),
        bodyLarge: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: _regular, color: onSurfaceWeak, height: 1.6),
        bodyMedium: TextStyle(fontFamily: _fontFamily, fontSize: 15, fontWeight: _regular, color: onSurfaceWeak, height: 1.5),
        bodySmall: TextStyle(fontFamily: _fontFamily, fontSize: 13, fontWeight: _regular, color: onSurfaceFaint, height: 1.5),
        labelLarge: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: _medium, color: onSurface),
        labelMedium: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: _medium, color: onSurfaceWeak),
        labelSmall: TextStyle(fontFamily: _fontFamily, fontSize: 11, fontWeight: _medium, color: onSurfaceFaint, letterSpacing: 0.3),
      ),
    );
  }
}
