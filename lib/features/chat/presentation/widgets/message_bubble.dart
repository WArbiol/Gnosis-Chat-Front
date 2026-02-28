import 'package:flutter/material.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final MessageEntity message;

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isUser ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(_isUser ? 16 : 4),
            bottomRight: Radius.circular(_isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message.content,
              style: TextStyle(
                color: _isUser ? scheme.onPrimary : scheme.onSurface,
              ),
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
        ),
      ),
    );
  }
}

class _CitationChip extends StatelessWidget {
  const _CitationChip({required this.citation});

  final CitationEntity citation;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '${citation.pdfName} p.${citation.page}',
        style: Theme.of(context).textTheme.labelSmall,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
