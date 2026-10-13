import 'package:flutter/material.dart';

/// Arcade text built from the supplied bitmap glyph sheets at
/// `assets/images/ui/font/digits/` and `assets/images/ui/font/letters/`.
///
/// The glyph sheets are not uniform (digits are 48x64, letters 35x42), so each
/// glyph is scaled by height with [BoxFit.contain] to keep its proportions.
/// Characters with no glyph render as blank space so spacing stays stable.
class PixelText extends StatelessWidget {
  const PixelText(
    this.text, {
    super.key,
    this.color = Colors.white,
    this.height = 16,
    this.spacing = 2,
    this.shadowColor,
  });

  final String text;
  final Color color;

  /// Rendered pixel height of each glyph.
  final double height;

  /// Gap between glyphs, in logical pixels.
  final double spacing;

  /// When set, an offset dark copy is drawn behind the glyphs.
  final Color? shadowColor;

  static const String _digits = 'assets/images/ui/font/digits/';
  static const String _letters = 'assets/images/ui/font/letters/';

  static String? glyphFor(String character) {
    if (RegExp(r'[0-9]').hasMatch(character)) return '$_digits$character.png';
    if (RegExp(r'[a-zA-Z]').hasMatch(character)) {
      return '$_letters${character.toUpperCase()}.png';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (shadowColor != null)
          Positioned(
            left: height * 0.18,
            top: height * 0.18,
            child: _strip(shadowColor!),
          ),
        _strip(color),
      ],
    );
  }

  Widget _strip(Color fill) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < text.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          _glyph(text[i], fill),
        ],
      ],
    );
  }

  Widget _glyph(String character, Color fill) {
    final path = glyphFor(character);
    if (path == null) {
      return SizedBox(width: height * 0.5, height: height);
    }
    return Image.asset(
      path,
      height: height,
      fit: BoxFit.contain,
      color: fill,
      filterQuality: FilterQuality.none,
    );
  }
}
