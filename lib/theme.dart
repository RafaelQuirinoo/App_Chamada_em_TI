import 'package:flutter/material.dart';

class Cores {
  Cores._();

  static const Color azul = Color(0xFF2B4084);
  static const Color laranja = Color(0xFFE25127);

  static const Color azulNoite = Color(0xFF1A2653);
  static const Color azulClaro = Color(0xFFE6EBF7);

  static const Color laranjaEscuro = Color(0xFFB8350F);
  static const Color laranjaClaro = Color(0xFFFCE6DD);

  static const Color papel = Color(0xFFF3F5FA);
  static const Color tinta = Color(0xFF1B2238);
  static const Color tintaSuave = Color(0xFF5A6480);
  static const Color borda = Color(0xFFDDE2EF);

  static const Color perigo = Color(0xFFB71C3A);
  static const Color perigoClaro = Color(0xFFFDECEF);
  static const Color perigoBorda = Color(0xFFF4B8C4);
  static const Color sucesso = Color(0xFF136C43);
}

ThemeData construirTema() {
  final esquema = ColorScheme.fromSeed(
    seedColor: Cores.azul,
    brightness: Brightness.light,
  ).copyWith(
    primary: Cores.azul,
    onPrimary: Colors.white,
    primaryContainer: Cores.azulClaro,
    onPrimaryContainer: Cores.azulNoite,
    secondary: Cores.laranja,
    onSecondary: Colors.white,
    secondaryContainer: Cores.laranjaClaro,
    onSecondaryContainer: Cores.laranjaEscuro,
    error: Cores.perigo,
    onError: Colors.white,
    outline: Cores.tintaSuave,
    outlineVariant: Cores.borda,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Cores.papel,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    dividerColor: Cores.borda,
    appBarTheme: const AppBarTheme(
      backgroundColor: Cores.azul,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Cores.laranja,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Cores.laranja,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      indicatorColor: Cores.laranjaClaro,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      indicatorColor: Cores.laranjaClaro,
      selectedIconTheme: IconThemeData(color: Cores.laranjaEscuro),
      unselectedIconTheme: IconThemeData(color: Cores.tintaSuave),
      selectedLabelTextStyle:
          TextStyle(color: Cores.azul, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: TextStyle(color: Cores.tintaSuave),
    ),
    badgeTheme: const BadgeThemeData(
      backgroundColor: Cores.laranja,
      textColor: Colors.white,
    ),
  );
}
