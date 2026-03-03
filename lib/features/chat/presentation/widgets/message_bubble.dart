import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final MessageEntity message;

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showContextMenu(context);
      },
      child: Align(
        alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: _isUser ? _userBubble(context) : _aiBubble(context),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MessageContextSheet(content: message.content),
    );
  }

  Widget _userBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.7),
            AppColors.primaryDark.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: _content(context, AppColors.onSurface),
    );
  }

  Widget _aiBubble(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(18),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.12),
              width: 0.5,
            ),
          ),
          child: _content(context, AppColors.onSurface),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          message.content,
          style: TextStyle(color: textColor, height: 1.5),
        ),
        if (message.citations.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: message.citations
                .map((c) => _CitationChip(citation: c))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _CitationChip extends StatelessWidget {
  const _CitationChip({required this.citation});

  final CitationEntity citation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surfaceVariant.withValues(alpha: 0.6),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        '${citation.pdfName} p.${citation.page}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.accentLight,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Long press context menu
// ---------------------------------------------------------------------------
class _MessageContextSheet extends StatelessWidget {
  const _MessageContextSheet({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          _ContextAction(
            icon: Icons.copy_rounded,
            label: 'Copiar',
            onTap: () {
              Clipboard.setData(ClipboardData(text: content));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copiado!'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          const SizedBox(height: 4),

          _ContextAction(
            icon: Icons.share_rounded,
            label: 'Compartilhar',
            onTap: () {
              Navigator.of(context).pop();
              Share.share(content);
            },
          ),
        ],
      ),
    );
  }
}

class _ContextAction extends StatelessWidget {
  const _ContextAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.onSurface),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
