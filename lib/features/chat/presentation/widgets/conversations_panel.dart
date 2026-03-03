import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/chat/domain/conversation_entity.dart';
import 'package:gnosis_chat/features/chat/presentation/conversation_provider.dart';

class ConversationsPanel extends ConsumerStatefulWidget {
  const ConversationsPanel({
    super.key,
    required this.width,
    required this.onNewConversation,
    required this.onSelectConversation,
    required this.onDeleteConversation,
  });

  final double width;
  final VoidCallback onNewConversation;
  final ValueChanged<String> onSelectConversation;
  final ValueChanged<String> onDeleteConversation;

  @override
  ConsumerState<ConversationsPanel> createState() => _ConversationsPanelState();
}

class _ConversationsPanelState extends ConsumerState<ConversationsPanel> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final convState = ref.watch(conversationProvider);
    final conversations = _searchQuery.isEmpty
        ? convState.conversations
        : ref.read(conversationProvider.notifier).search(_searchQuery);

    return Container(
      width: widget.width,
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Conversas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _NewConversationButton(onTap: widget.onNewConversation),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar conversas...',
                  hintStyle: TextStyle(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant.withValues(alpha: 0.4),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Conversations list
            Expanded(
              child: conversations.isEmpty
                  ? _EmptyState(hasSearch: _searchQuery.isNotEmpty)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conv = conversations[index];
                        final isActive = conv.id == convState.activeId;

                        return _ConversationTile(
                          conversation: conv,
                          isActive: isActive,
                          onTap: () => widget.onSelectConversation(conv.id),
                          onDelete: () => widget.onDeleteConversation(conv.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New conversation button
// ---------------------------------------------------------------------------
class _NewConversationButton extends StatelessWidget {
  const _NewConversationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: 'Nova conversa',
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [AppColors.accent, AppColors.accentLight],
        ).createShader(bounds),
        child: const Icon(Icons.edit_outlined, size: 20, color: Colors.white),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single conversation tile with swipe-to-delete
// ---------------------------------------------------------------------------
class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  final ConversationEntity conversation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Dismissible(
        key: ValueKey(conversation.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.flame.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.flame,
            size: 22,
          ),
        ),
        onDismissed: (_) => onDelete(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isActive
                    ? AppColors.surfaceVariant.withValues(alpha: 0.6)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: isActive
                        ? AppColors.accent
                        : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive
                                ? AppColors.onSurface
                                : AppColors.onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: isActive
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(conversation.updatedAt),
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    if (diff.inDays < 7) return '${diff.inDays}d atrás';

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch
                ? Icons.search_off_rounded
                : Icons.chat_bubble_outline_rounded,
            size: 40,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Text(
            hasSearch ? 'Nenhum resultado' : 'Nenhuma conversa ainda',
            style: TextStyle(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
