import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// A customized, ultra-premium Dark Liquid Glass surface tailored for Gnosis.
/// Eliminates chromatic aberrations (rainbow artifacts) and text-inverting distortions,
/// while providing organic liquid-touch feedback, rich frosted blur, and delicate specular rim highlights.
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
    this.blurSigma = 18.0,
    this.shadowOpacity = 0.35,
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

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? Colors.white.withValues(alpha: 0.12);
    final effectiveTint = tintColor ?? const Color(0xEB131316);

    return LiquidGlassLens(
      touch: enableTouchFlex
          ? const LiquidGlassTouch(flex: LiquidGlassFlex.subtle())
          : null,
      style: LiquidGlassStyle(
        shape: LiquidGlassShape.continuousRoundedRectangle(
          cornerRadius: cornerRadius,
          borderWidth: borderWidth,
          borderColor: effectiveBorderColor,
          lightIntensity: 0.15,
          lightDirection: 90, // subtle top-down specular highlight
          borderType: ClassicBorder(
            borderSoftness: 1.5,
            shadowColor: Colors.black.withValues(alpha: 0.4),
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
            offset: const Offset(0, 6),
          ),
        ),
        refraction: const LiquidGlassRefraction(
          distortion: 0.0, // Zero distortion to keep underlying chat readable
          chromaticAberration: 0.0, // Zero aberration to prevent rainbow/green fringing
          magnification: 1.0,
        ),
      ),
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );
  }
}
