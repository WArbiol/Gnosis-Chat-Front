import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// A customized, ultra-premium Dark Liquid Glass surface tailored for Gnosis.
/// Inspired by Apple's iOS/visionOS optical glass:
/// - Subtle, discrete perimeter refraction (no harsh letter flips)
/// - Balanced smoky translucency (not heavy opaque, not transparent)
/// - Zero chromatic aberration (clean glass without rainbow artifacts)
/// - Organic soft-body liquid touch feedback on interactive elements
class GnosisLiquidGlass extends StatelessWidget {
  const GnosisLiquidGlass({
    super.key,
    required this.child,
    this.cornerRadius = 24,
    this.padding,
    this.borderWidth = 0.8,
    this.borderColor,
    this.tintColor,
    this.enableTouchFlex = false,
    this.blurSigma = 14.0,
    this.shadowOpacity = 0.35,
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
    final effectiveBorderColor = borderColor ?? Colors.white.withValues(alpha: 0.14);
    // Balanced ~60% smoky obsidian glass (translucent with body, not super opaque)
    final effectiveTint = tintColor ?? const Color(0x99141418);

    return LiquidGlassLens(
      touch: enableTouchFlex
          ? const LiquidGlassTouch(flex: LiquidGlassFlex.subtle())
          : null,
      style: LiquidGlassStyle(
        shape: LiquidGlassShape.continuousRoundedRectangle(
          cornerRadius: cornerRadius,
          borderWidth: borderWidth,
          borderColor: effectiveBorderColor,
          lightIntensity: 0.20,
          lightDirection: 90, // subtle top-down specular highlight
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
            blur: 14,
            cornerRadius: cornerRadius,
            offset: const Offset(0, 5),
          ),
        ),
        refraction: LiquidGlassRefraction(
          distortion: distortion, // Subtle Apple-style edge refraction
          distortionWidth: distortionWidth, // Narrow perimeter band (center stays clear)
          chromaticAberration: 0.0, // Zero aberration (no rainbow/green fringing)
          magnification: 1.0,
        ),
      ),
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );
  }
}
