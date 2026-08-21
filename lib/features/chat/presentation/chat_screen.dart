import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/auth/presentation/auth_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/conversation_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/message_bubble.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/typing_indicator.dart';
import 'package:gnosis_chat/shared/widgets/animated_background.dart';
import 'package:gnosis_chat/shared/widgets/error_view.dart';
import 'package:go_router/go_router.dart';
import 'package:gnosis_chat/core/utils/extensions.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/animated_message.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/empty_state.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/glass_input_bar.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/premium_app_bar.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

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
  bool _isUserScrolledUp = false;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        debugPrint('LIFECYCLE: App resumed. Refreshing session and data...');
        ref.read(authProvider.notifier).ensureValidSessionAndRefresh();
        ref.read(conversationProvider.notifier).loadConversations();
      },
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _queryCtrl.addListener(() => setState(() {}));

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.hasClients && _scrollCtrl.position.hasContentDimensions) {
        final distanceToBottom =
            _scrollCtrl.position.maxScrollExtent - _scrollCtrl.offset;
        final isUp = distanceToBottom > 60.0;
        if (_isUserScrolledUp != isUp) {
          setState(() {
            _isUserScrolledUp = isUp;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
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

    _isUserScrolledUp = false;
    _scrollToBottom();

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
    _isUserScrolledUp = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollCtrl.hasClients && _scrollCtrl.position.hasContentDimensions) {
        try {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        } catch (_) {}
      }
    });
  }

  void _scrollToBottom() {
    if (_isUserScrolledUp) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollCtrl.hasClients &&
          _scrollCtrl.position.hasContentDimensions &&
          !_isUserScrolledUp) {
        try {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
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

    // Reset scroll & sync known message IDs declaratively when switching conversations
    ref.listen(conversationProvider.select((s) => s.activeId), (prev, next) {
      if (prev != next) {
        _knownMessageIds.clear();
        final currentMsgs = ref.read(chatProvider).valueOrNull ?? [];
        if (currentMsgs.isNotEmpty) {
          _knownMessageIds.addAll(currentMsgs.map((m) => m.id));
        }
        _jumpToBottom();
      }
    });

    // Auto-scroll logic for chat messages
    ref.listen(chatProvider, (prev, next) {
      final prevList = prev?.valueOrNull ?? [];
      final nextList = next.valueOrNull ?? [];

      if (prevList.isEmpty && nextList.isNotEmpty) {
        // Initial load of history: jump to bottom
        _knownMessageIds.clear();
        _knownMessageIds.addAll(nextList.map((m) => m.id));
        _jumpToBottom();
      } else if (nextList.length > prevList.length && prevList.isNotEmpty) {
        // New incoming message in active conversation: only scroll if user is not reading above
        if (!_isUserScrolledUp) {
          _scrollToBottom();
        }
      }
    });

    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final mainContent = Stack(
      children: [
        // Subtle animated background blobs
        AnimatedBackground(animation: _glowAnim, intensity: 0.65),

        // Chat body (True Edge-to-Edge: bottom layer, scrolls under floating glass header and input)
        Positioned.fill(
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x1A000000), // ~10% suave no topo da status bar
                  Color(0x80000000), // ~50% passando pela altura dos botões
                  Colors.black, // 100% nítido abaixo do header
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [
                  0.0,
                  0.08,
                  0.15, // Transição aveludada e gradual
                  0.96,
                  1.0,
                ],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: chatState.when(
                  data: (messages) {
                    final loadingId = ref.watch(
                      loadingConversationIdProvider,
                    );
                    final isLoading =
                        loadingId != null &&
                        (loadingId == activeId ||
                            (activeId == null && loadingId == 'NEW_CONV'));
                    final isLastUserMessage =
                        messages.isNotEmpty &&
                        messages.last.role == MessageRole.user;
                    final showTyping = isLoading || isLastUserMessage;

                    if (messages.isEmpty) {
                      if (isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: TypingIndicator(),
                          ),
                        );
                      }
                      return EmptyState(glowAnim: _glowAnim);
                    }

                    final itemCount =
                        messages.length + (showTyping ? 1 : 0);

                    final listView = ListView.builder(
                      controller: _scrollCtrl,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top:
                            topPadding +
                            64, // Comfortably below floating header on start
                        bottom: bottomPadding + 110,
                      ),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        if (index < messages.length) {
                          final msg = messages[index];
                          final isNew = !_knownMessageIds.contains(msg.id);
                          if (isNew) _knownMessageIds.add(msg.id);

                          return AnimatedMessage(
                            key: ValueKey(msg.id),
                            animate: isNew,
                            child: MessageBubble(message: msg),
                          );
                        }

                        // Typing indicator after the last message
                        if (showTyping) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 4, bottom: 8),
                            child: TypingIndicator(),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    );

                    final isDesktopWeb = kIsWeb &&
                        (defaultTargetPlatform == TargetPlatform.macOS ||
                            defaultTargetPlatform == TargetPlatform.windows ||
                            defaultTargetPlatform == TargetPlatform.linux);

                    if (isDesktopWeb) {
                      return SelectionArea(child: listView);
                    }
                    return listView;
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
                    message:
                        e.toString().contains('connection') ||
                            e.toString().contains('XMLHttpRequest')
                        ? 'Falha de conexão com o servidor. Verifique se a API está online.'
                        : e
                              .toString()
                              .replaceAll('DioException:', '')
                              .trim(),
                    onRetry: () {
                      if (activeId != null) {
                        ref
                            .read(conversationProvider.notifier)
                            .selectConversation(activeId);
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
      ],
    );

    final floatingOverlays = Stack(
      children: [
        // Custom floating glass AppBar (top layer with safe area)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: PremiumAppBar(
              glowAnim: _glowAnim,
              user: user,
              onMenuTap: widget.onMenuTap,
              onProfileTap: widget.onProfileTap,
            ),
          ),
        ),

        // Premium input bar (bottom layer with safe area)
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: GlassInputBar(
                controller: _queryCtrl,
                hasText: _queryCtrl.text.trim().isNotEmpty,
                onSend: _sendMessage,
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: !kIsWeb
            ? LiquidGlassView(
                backgroundWidget: mainContent,
                child: floatingOverlays,
              )
            : Stack(
                children: [
                  mainContent,
                  floatingOverlays,
                ],
              ),
      ),
    );
  }
}
