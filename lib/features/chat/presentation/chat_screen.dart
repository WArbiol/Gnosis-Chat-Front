import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/auth/presentation/auth_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/message_bubble.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/typing_indicator.dart';
import 'package:gnosis_chat/shared/widgets/animated_background.dart';
import 'package:gnosis_chat/shared/widgets/error_view.dart';
import 'package:gnosis_chat/shared/widgets/loading_overlay.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/inline_cta_banner.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';
import 'package:go_router/go_router.dart';

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
    final loadingCtrl = ref.read(isLoadingProvider.notifier);
    ref.read(chatProvider.notifier).setLoadingController(loadingCtrl);

    await ref.read(chatProvider.notifier).ask(query);
    HapticFeedback.mediumImpact();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final user = ref.watch(authProvider).whenOrNull(authenticated: (u) => u);

    // Check limit
    final userMessagesCount =
        chatState.valueOrNull
            ?.where((m) => m.role == MessageRole.user)
            .length ??
        0;
    final maxReached = userMessagesCount >= 3;

    // Auto-scroll when messages update (streaming mock)
    ref.listen(chatProvider, (_, _) => _scrollToBottom());

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Subtle animated background blobs
            AnimatedBackground(animation: _glowAnim, intensity: 0.45),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Custom premium AppBar
                  _PremiumAppBar(
                    glowAnim: _glowAnim,
                    avatarUrl: user?.avatarUrl,
                    onMenuTap: widget.onMenuTap,
                    onProfileTap: widget.onProfileTap,
                  ),

                  // Chat body
                  Expanded(
                    child: chatState.when(
                      data: (messages) {
                        if (messages.isEmpty) {
                          return _EmptyState(glowAnim: _glowAnim);
                        }

                        final isLoading = ref.watch(isLoadingProvider);
                        final itemCount =
                            messages.length +
                            (isLoading ? 1 : 0) +
                            (maxReached ? 1 : 0);

                        return ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: itemCount,
                          itemBuilder: (context, index) {
                            // Absolute last item -> Banner, if limit reached
                            if (maxReached && index == itemCount - 1) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 24,
                                ),
                                child: InlineCtaBanner(
                                  onUpgradeTap: () =>
                                      context.push('/subscription'),
                                ),
                              );
                            }

                            // Typing indicator
                            if (isLoading && index == messages.length) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: TypingIndicator(),
                              );
                            }

                            final msg = messages[index];
                            final isNew = !_knownMessageIds.contains(msg.id);
                            if (isNew) _knownMessageIds.add(msg.id);

                            return _AnimatedMessage(
                              key: ValueKey(msg.id),
                              animate: isNew,
                              child: MessageBubble(message: msg),
                            );
                          },
                        );
                      },
                      loading: () => const LoadingOverlay(),
                      error: (e, _) => ErrorView(
                        message: e.toString(),
                        onRetry: () => ref.invalidate(chatProvider),
                      ),
                    ),
                  ),

                  // Premium input bar
                  if (!maxReached)
                    _GlassInputBar(
                      controller: _queryCtrl,
                      hasText: _queryCtrl.text.trim().isNotEmpty,
                      onSend: _sendMessage,
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

// ---------------------------------------------------------------------------
// Animated message entrance — fade + slide up
// ---------------------------------------------------------------------------
class _AnimatedMessage extends StatefulWidget {
  const _AnimatedMessage({
    super.key,
    required this.animate,
    required this.child,
  });

  final bool animate;
  final Widget child;

  @override
  State<_AnimatedMessage> createState() => _AnimatedMessageState();
}

class _AnimatedMessageState extends State<_AnimatedMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.animate ? 0 : 1,
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    if (widget.animate) _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(position: _slideAnim, child: widget.child),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom transparent AppBar
// ---------------------------------------------------------------------------
class _PremiumAppBar extends StatelessWidget {
  const _PremiumAppBar({
    required this.glowAnim,
    this.avatarUrl,
    this.onMenuTap,
    this.onProfileTap,
  });

  final Animation<double> glowAnim;
  final String? avatarUrl;
  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          // Sidebar / conversations icon
          IconButton(
            onPressed: onMenuTap,
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Conversas',
            iconSize: 24,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.onSurface,
              fixedSize: const Size(48, 48),
            ),
          ),

          const Spacer(),

          // Gold gradient title
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.accent, AppColors.accentLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'Gnosis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const Spacer(),

          // Profile avatar
          IconButton(
            onPressed: onProfileTap,
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                color: AppColors.surfaceVariant,
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? Image.network(
                        avatarUrl!,
                        headers: kIsWeb
                            ? null
                            : const {
                                'User-Agent':
                                    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                              },
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint(
                            'DEBUG IMAGE: Failed to load avatar: $error',
                          );
                          return const Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: AppColors.onSurfaceVariant,
                          );
                        },
                      )
                    : const Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
              ),
            ),
            tooltip: 'Perfil',
            style: IconButton.styleFrom(fixedSize: const Size(48, 48)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state — logo with glow + welcome text
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.glowAnim});

  final Animation<double> glowAnim;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with animated glow
            AnimatedBuilder(
              animation: glowAnim,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(
                          alpha: glowAnim.value * 0.4,
                        ),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                      BoxShadow(
                        color: AppColors.primary.withValues(
                          alpha: glowAnim.value * 0.2,
                        ),
                        blurRadius: 80,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
              ),
            ),

            const SizedBox(height: 24),

            // Welcome text with gold gradient
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.accent, AppColors.accentLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Pergunte ao Gnosis...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Conhecimento sagrado ao seu alcance',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Glassmorphism input bar
// ---------------------------------------------------------------------------
class _GlassInputBar extends StatefulWidget {
  const _GlassInputBar({
    required this.controller,
    required this.hasText,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool hasText;
  final VoidCallback onSend;

  @override
  State<_GlassInputBar> createState() => _GlassInputBarState();
}

class _GlassInputBarState extends State<_GlassInputBar> {
  final _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: AppColors.surfaceVariant.withValues(alpha: 0.55),
            border: Border.all(
              color: _hasFocus
                  ? AppColors.accent.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
              width: _hasFocus ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Pergunte ao Gnosis...',
                      hintStyle: TextStyle(
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: 15,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ),

              // Send button
              AnimatedScale(
                scale: widget.hasText ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: widget.hasText ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.accent, AppColors.accentLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onSend,
                        borderRadius: BorderRadius.circular(18),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: AppColors.background,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
