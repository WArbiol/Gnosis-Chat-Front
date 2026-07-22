import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/auth/presentation/auth_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/conversation_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/message_bubble.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/typing_indicator.dart';
import 'package:gnosis_chat/shared/widgets/animated_background.dart';
import 'package:gnosis_chat/shared/widgets/error_view.dart';
import 'package:go_router/go_router.dart';
import 'package:gnosis_chat/core/utils/extensions.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/animated_message.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/empty_state.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/glass_input_bar.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/premium_app_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.onMenuTap, this.onProfileTap});

  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _queryCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  final _knownMessageIds = <String>{};
  String? _lastLoadedActiveId;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _queryCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _queryCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final query = _queryCtrl.text.trim();
    if (query.isEmpty) return;
    _queryCtrl.clear();
    HapticFeedback.lightImpact();

    // Wire loading controller
    final loadingCtrl = ref.read(loadingConversationIdProvider.notifier);
    ref.read(chatProvider.notifier).setLoadingIdController(loadingCtrl);

    try {
      await ref.read(chatProvider.notifier).ask(query);
      HapticFeedback.mediumImpact();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        if (errStr.contains('Você atingiu o limite') ||
            errStr.contains('LIMIT_EXCEEDED') ||
            errStr.contains('limite de 3 mensagens')) {
          _showUpgradeDialog(context);
        } else {
          final cleanMsg = errStr.replaceAll('DioException:', '').trim();
          context.showSnackBar(cleanMsg, isError: true);
        }
      }
    }
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.accent, size: 28),
            const SizedBox(width: 8),
            Text(
              'Limite de Perguntas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'Você atingiu o limite de 3 perguntas do plano Gratuito. Faça o upgrade para continuar explorando o conhecimento gnóstico livremente.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Ver Planos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollCtrl.hasClients) {
        try {
          _scrollCtrl.jumpTo(0.0);
        } catch (_) {}
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollCtrl.hasClients) {
        try {
          _scrollCtrl.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final user = ref.watch(authProvider).whenOrNull(authenticated: (u) => u);
    final activeId = ref.watch(conversationProvider).activeId;

    // Reset scroll when switching conversations
    ref.listen(conversationProvider.select((s) => s.activeId), (prev, next) {
      if (prev != next) {
        _jumpToBottom();
      }
    });

    // Auto-scroll logic for chat messages
    ref.listen(chatProvider, (prev, next) {
      final prevList = prev?.valueOrNull ?? [];
      final nextList = next.valueOrNull ?? [];

      if (prevList.isEmpty && nextList.isNotEmpty) {
        // Initial load of history: jump to bottom
        _jumpToBottom();
      } else if (nextList.length > prevList.length && prevList.isNotEmpty) {
        // New incoming message in active conversation: animate scroll down
        _scrollToBottom();
      }
    });

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Subtle animated background blobs
            AnimatedBackground(animation: _glowAnim, intensity: 0.65),

            // Main content
            SafeArea(
              child: Stack(
                children: [
                  // Chat body (bottom layer, scrolls under app bar and input)
                  Positioned.fill(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: [
                            0.05,
                            0.12,
                            0.95,
                            1.0,
                          ], // Push bottom fade zone much lower to avoid hiding the typing indicator
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 850),
                          child: chatState.when(
                            data: (messages) {
                              if (messages.isEmpty) {
                                if (activeId == null) {
                                  return EmptyState(glowAnim: _glowAnim);
                                }
                                return const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: AppColors.accent,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                );
                              }

                              final loadingId =
                                  ref.watch(loadingConversationIdProvider);
                              final isLoading = loadingId != null &&
                                  (loadingId == activeId ||
                                      (activeId == null &&
                                          loadingId == 'NEW_CONV'));
                              final itemCount =
                                  messages.length + (isLoading ? 1 : 0);

                              // If this is a newly loaded conversation history,
                              // clear the old IDs to prevent memory leak and add the new ones
                              if (_lastLoadedActiveId != activeId) {
                                _knownMessageIds.clear();
                                if (messages.isNotEmpty) {
                                  _knownMessageIds.addAll(messages.map((m) => m.id));
                                }
                                _lastLoadedActiveId = activeId;
                              }

                              return ListView.builder(
                                reverse: true,
                                controller: _scrollCtrl,
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  top: 100,
                                  bottom: 120,
                                ),
                                itemCount: itemCount,
                                itemBuilder: (context, index) {
                                  final actualIndex = itemCount - 1 - index;

                                  // Typing indicator
                                  if (isLoading && actualIndex == messages.length) {
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 4, bottom: 8),
                                      child: TypingIndicator(),
                                    );
                                  }

                                  final msg = messages[actualIndex];
                                  final isNew = !_knownMessageIds.contains(
                                    msg.id,
                                  );
                                  if (isNew) _knownMessageIds.add(msg.id);

                                  return AnimatedMessage(
                                    key: ValueKey(msg.id),
                                    animate: isNew,
                                    child: MessageBubble(message: msg),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: AppColors.accent,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                            error: (e, _) => ErrorView(
                              message: e.toString().contains('connection') || e.toString().contains('XMLHttpRequest')
                                  ? 'Falha de conexão com o servidor. Verifique se a API está online.'
                                  : e.toString().replaceAll('DioException:', '').trim(),
                              onRetry: () {
                                if (activeId != null) {
                                  ref.read(conversationProvider.notifier).selectConversation(activeId);
                                } else {
                                  ref.invalidate(chatProvider);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Custom premium AppBar (top layer)
                  Align(
                    alignment: Alignment.topCenter,
                    child: PremiumAppBar(
                      glowAnim: _glowAnim,
                      user: user,
                      onMenuTap: widget.onMenuTap,
                      onProfileTap: widget.onProfileTap,
                    ),
                  ),

                  // Premium input bar (bottom layer)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: GlassInputBar(
                        controller: _queryCtrl,
                        hasText: _queryCtrl.text.trim().isNotEmpty,
                        onSend: _sendMessage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
