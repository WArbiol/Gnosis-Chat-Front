import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/message_bubble.dart';
import 'package:gnosis_chat/shared/widgets/animated_background.dart';
import 'package:gnosis_chat/shared/widgets/error_view.dart';
import 'package:gnosis_chat/shared/widgets/loading_overlay.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _queryCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

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
    await ref.read(chatProvider.notifier).ask(query);
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

    return Scaffold(
      body: Stack(
        children: [
          // Subtle animated background blobs
          AnimatedBackground(animation: _glowAnim, intensity: 0.45),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom premium AppBar
                _PremiumAppBar(glowAnim: _glowAnim),

                // Chat body
                Expanded(
                  child: chatState.when(
                    data: (messages) => messages.isEmpty
                        ? _EmptyState(glowAnim: _glowAnim)
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: messages.length,
                            itemBuilder: (context, index) =>
                                MessageBubble(message: messages[index]),
                          ),
                    loading: () => const LoadingOverlay(),
                    error: (e, _) => ErrorView(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(chatProvider),
                    ),
                  ),
                ),

                // Premium input bar
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
    );
  }
}

// ---------------------------------------------------------------------------
// Custom transparent AppBar
// ---------------------------------------------------------------------------
class _PremiumAppBar extends StatelessWidget {
  const _PremiumAppBar({required this.glowAnim});

  final Animation<double> glowAnim;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          // Sidebar / conversations icon
          IconButton(
            onPressed: () {
              // TODO: open conversations drawer
            },
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
            onPressed: () {
              // TODO: open profile / settings
            },
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
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: AppColors.onSurfaceVariant,
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
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
