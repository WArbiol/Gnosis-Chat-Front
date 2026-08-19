import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// A customized, ultra-premium Dark Liquid Glass surface tailored for Gnosis.
/// Inspired by Apple's iOS/visionOS optical glass:
/// - On Impeller (Mobile): leverages hardware LiquidGlass shaders and touch flex.
/// - On Web/Skia: provides a rich, multi-layered crystal glass with top specular sheen,
///   silky backdrop blur, and dual-layer OLED shadows so it never looks flat or opaque.
class GnosisLiquidGlass extends StatelessWidget {
  const GnosisLiquidGlass({
    super.key,
    required this.child,
    this.cornerRadius = 24,
    this.padding,
    this.borderWidth = 0.9,
    this.borderColor,
    this.tintColor,
    this.enableTouchFlex = false,
    this.blurSigma = 16.0,
    this.shadowOpacity = 0.40,
    this.distortion = 0.035,
    this.distortionWidth = 12.0,
  });

  final Widget child;
  final double cornerRadius;
  final EdgeInsetsGeometry? padding;
  final double borderWidth;
  final Color? borderColor;
  final Color? tintColor;
  final bool enableTouchFlex;
  final double blurSigma;
  final double shadowOpacity;
  final double distortion;
  final double distortionWidth;

  @override
  Widget build(BuildContext context) {
    final isShaderSupported = !kIsWeb && ui.ImageFilter.isShaderFilterSupported;

    // 1. If running on a platform supporting live Impeller shaders (Mobile):
    if (isShaderSupported) {
      final effectiveBorderColor = borderColor ?? Colors.white.withValues(alpha: 0.14);
      final effectiveTint = tintColor ?? const Color(0x8C141418);

      return LiquidGlassLens(
        touch: enableTouchFlex
            ? const LiquidGlassTouch(flex: LiquidGlassFlex.subtle())
            : null,
        style: LiquidGlassStyle(
          shape: LiquidGlassShape.continuousRoundedRectangle(
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            borderColor: effectiveBorderColor,
            lightIntensity: 0.25,
            lightDirection: 90,
            borderType: ClassicBorder(
              borderSoftness: 1.5,
              shadowColor: Colors.black.withValues(alpha: 0.45),
            ),
          ),
          appearance: LiquidGlassAppearance(
            color: effectiveTint,
            blur: LiquidGlassBlur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            ),
            shadow: LiquidGlassShadow(
              color: Colors.black,
              opacity: shadowOpacity,
              blur: 16,
              cornerRadius: cornerRadius,
              offset: const Offset(0, 5),
            ),
          ),
          refraction: LiquidGlassRefraction(
            distortion: distortion,
            distortionWidth: distortionWidth,
            chromaticAberration: 0.0,
            magnification: 1.0,
          ),
        ),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      );
    }

    // 2. On Web / CanvasKit / Skia: Craft a stunning, luminous crystal glass
    // with top-lit specular sheen, frosted blur, and transparent smoky body.
    final borderCol = borderColor ?? Colors.white.withValues(alpha: 0.18);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cornerRadius),
        boxShadow: [
          // Ambient soft glow & depth
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowOpacity * 1.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowOpacity * 0.7),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cornerRadius),
              // Top-lit gradient creates authentic glass optical depth
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.14), // top specular catch
                  Colors.white.withValues(alpha: 0.04), // middle glass
                  const Color(0x66101014),              // bottom smoky tint
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
              border: Border.all(
                color: borderCol,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
