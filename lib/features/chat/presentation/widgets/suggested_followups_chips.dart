import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';

/// Renderiza sugestões de acompanhamento ("Follow-up Chips") com estética Glassmorphism
/// e efeito de onda/splash ao toque (efeito de gota d'água).
class SuggestedFollowupsChips extends StatelessWidget {
  const SuggestedFollowupsChips({
    super.key,
    required this.followups,
    required this.onTapFollowup,
  });

  final List<String> followups;
  final ValueChanged<String> onTapFollowup;

  @override
  Widget build(BuildContext context) {
    if (followups.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 13,
                color: AppColors.accent.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 6),
              Text(
                'Sugestões:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: followups.map((question) {
              return _buildGlassChip(context, question);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassChip(BuildContext context, String question) {
    final borderRadius = BorderRadius.circular(16);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: () {
              HapticFeedback.lightImpact();
              onTapFollowup(question);
            },
            splashColor: AppColors.primary.withValues(alpha: 0.35),
            highlightColor: AppColors.accent.withValues(alpha: 0.15),
            hoverColor: Colors.white.withValues(alpha: 0.05),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: AppColors.surfaceVariant.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 0.9,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      question,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface.withValues(alpha: 0.9),
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 12,
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
