import 'dart:typed_data';

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF6554E8);
  static const navy = Color(0xFF19213D);
  static const ink = Color(0xFF202A43);
  static const muted = Color(0xFF68738A);
  static const background = Color(0xFFF5F6FB);
  static const line = Color(0xFFE9ECF4);
  static const lavender = Color(0xFFEEEAFE);
  static const teal = Color(0xFF15977D);
  static const mint = Color(0xFFE2F6EF);
  static const peach = Color(0xFFFFF0DF);
  static const orange = Color(0xFFBA6B1B);
  static const pink = Color(0xFFFFEBF0);
  static const red = Color(0xFFD44F6D);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.teal,
    surface: Colors.white,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Roboto',
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8F9FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      labelStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
      prefixIconColor: AppColors.muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.muted,
        side: const BorderSide(color: AppColors.line),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.navy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.dark = false, this.compact = false});
  final bool dark;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: dark ? Colors.white.withValues(alpha: .12) : AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.people_alt_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      if (!compact) ...[
        const SizedBox(width: 12),
        Text(
          'UserHub',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -.6,
            color: dark ? Colors.white : AppColors.ink,
          ),
        ),
      ],
    ],
  );
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.bytes, this.size = 48});
  final String name;
  final Uint8List? bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.lavender,
      AppColors.mint,
      AppColors.peach,
      AppColors.pink,
    ];
    final foreground = [
      AppColors.primary,
      AppColors.teal,
      AppColors.orange,
      AppColors.red,
    ];
    final index =
        name.runes.fold<int>(0, (sum, rune) => sum + rune) % colors.length;
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? '?'
        : (words.length == 1
                  ? words.first.characters.first
                  : '${words.first.characters.first}${words.last.characters.first}')
              .toUpperCase();
    final placeholder = Center(
      child: words.isEmpty
          ? Icon(
              Icons.person_outline_rounded,
              size: size * .5,
              color: foreground[index],
            )
          : Text(
              initials,
              style: TextStyle(
                fontSize: size * .32,
                fontWeight: FontWeight.w700,
                color: foreground[index],
              ),
            ),
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors[index],
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: bytes == null
          ? placeholder
          : Image.memory(
              bytes!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}
