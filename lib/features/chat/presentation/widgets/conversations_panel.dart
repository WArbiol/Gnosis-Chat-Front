import 'package:flutter/foundation.dart';
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
              child: convState.isLoading && conversations.isEmpty
                  ? const _LoadingState()
                  : conversations.isEmpty
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
// Single conversation tile with context actions (Pin, Rename, Delete)
// ---------------------------------------------------------------------------
class _ConversationTile extends ConsumerStatefulWidget {
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
  ConsumerState<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends ConsumerState<_ConversationTile> {
  bool _isHovered = false;

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Excluir conversa?',
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Tem certeza de que deseja excluir "${widget.conversation.title}"? Esta ação não pode ser desfeita.',
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.flame,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.conversation.title);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Renomear conversa',
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Novo título',
            hintStyle: TextStyle(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (value) {
            final trimmed = value.trim();
            if (trimmed.isNotEmpty) {
              ref
                  .read(conversationProvider.notifier)
                  .renameConversation(widget.conversation.id, trimmed);
            }
            Navigator.of(dialogCtx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isNotEmpty) {
                ref
                    .read(conversationProvider.notifier)
                    .renameConversation(widget.conversation.id, trimmed);
              }
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showMobileBottomSheet(BuildContext context) {
    final isPinned = widget.conversation.isPinned;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(
                  isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                  color: AppColors.accent,
                ),
                title: Text(
                  isPinned ? 'Desafixar do topo' : 'Fixar no topo',
                  style: const TextStyle(color: AppColors.onSurface, fontSize: 15),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  ref
                      .read(conversationProvider.notifier)
                      .togglePinConversation(widget.conversation.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.onSurface),
                title: const Text(
                  'Renomear conversa',
                  style: TextStyle(color: AppColors.onSurface, fontSize: 15),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _showRenameDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.flame),
                title: const Text(
                  'Excluir conversa',
                  style: TextStyle(color: AppColors.flame, fontSize: 15),
                ),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  final confirmed = await _confirmDelete(context);
                  if (confirmed) {
                    widget.onDelete();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPinned = widget.conversation.isPinned;
    final showActions = _isHovered || widget.isActive || kIsWeb;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Dismissible(
        key: ValueKey(widget.conversation.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDelete(context),
        onDismissed: (_) => widget.onDelete(),
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
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: () => _showMobileBottomSheet(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: widget.isActive
                      ? AppColors.surfaceVariant.withValues(alpha: 0.6)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      isPinned
                          ? Icons.push_pin_rounded
                          : Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: isPinned
                          ? AppColors.accent
                          : widget.isActive
                              ? AppColors.accent
                              : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.conversation.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.isActive
                                  ? AppColors.onSurface
                                  : AppColors.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: isPinned || widget.isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (isPinned) ...[
                                Text(
                                  'Fixada • ',
                                  style: TextStyle(
                                    color: AppColors.accent.withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              Text(
                                _formatDate(widget.conversation.updatedAt),
                                style: TextStyle(
                                  color: AppColors.onSurfaceVariant.withValues(
                                    alpha: 0.4,
                                  ),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (showActions)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          size: 18,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        tooltip: 'Opções',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 140),
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        onSelected: (action) async {
                          if (action == 'pin') {
                            ref
                                .read(conversationProvider.notifier)
                                .togglePinConversation(widget.conversation.id);
                          } else if (action == 'rename') {
                            _showRenameDialog(context);
                          } else if (action == 'delete') {
                            final confirmed = await _confirmDelete(context);
                            if (confirmed) {
                              widget.onDelete();
                            }
                          }
                        },
                        itemBuilder: (menuCtx) => [
                          PopupMenuItem<String>(
                            value: 'pin',
                            height: 36,
                            child: Row(
                              children: [
                                Icon(
                                  isPinned
                                      ? Icons.push_pin_outlined
                                      : Icons.push_pin_rounded,
                                  size: 16,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isPinned ? 'Desafixar' : 'Fixar no topo',
                                  style: const TextStyle(
                                    color: AppColors.onSurface,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'rename',
                            height: 36,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: AppColors.onSurface,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Renomear',
                                  style: TextStyle(
                                    color: AppColors.onSurface,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            height: 36,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: AppColors.flame,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Excluir',
                                  style: TextStyle(
                                    color: AppColors.flame,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    final diff = now.difference(localDate);

    if (diff.isNegative || diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    if (diff.inDays < 7) return '${diff.inDays}d atrás';

    return '${localDate.day.toString().padLeft(2, '0')}/${localDate.month.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Loading state
// ---------------------------------------------------------------------------
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Carregando conversas...',
            style: TextStyle(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
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
