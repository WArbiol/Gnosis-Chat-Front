import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_screen.dart';
import 'package:gnosis_chat/features/chat/presentation/conversation_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/conversations_panel.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/profile_bottom_sheet.dart';

class ChatShell extends ConsumerStatefulWidget {
  const ChatShell({super.key});

  @override
  ConsumerState<ChatShell> createState() => _ChatShellState();
}

class _ChatShellState extends ConsumerState<ChatShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<double> _slideAnim;

  static const _panelWidth = 300.0;
  static const _chatScale = 0.88;
  static const _chatBorderRadius = 20.0;

  bool _isPanelOpen = false;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = CurvedAnimation(
      parent: _slideCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _togglePanel() {
    if (_isPanelOpen) {
      _slideCtrl.reverse();
    } else {
      _slideCtrl.forward();
    }
    setState(() => _isPanelOpen = !_isPanelOpen);
  }

  void _closePanel() {
    if (!_isPanelOpen) return;
    _slideCtrl.reverse();
    setState(() => _isPanelOpen = false);
  }

  void _onNewConversation() {
    ref.read(conversationProvider.notifier).resetActiveId();
    _closePanel();
  }

  void _onSelectConversation(String id) {
    ref.read(conversationProvider.notifier).selectConversation(id);
    _closePanel();
  }

  void _onDeleteConversation(String id) {
    ref.read(conversationProvider.notifier).deleteConversation(id);
  }

  void _showProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ProfileBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sync messages to active conversation whenever they change
    ref.listen(chatProvider, (prev, next) {
      final messages = next.valueOrNull;
      if (messages != null) {
        ref.read(conversationProvider.notifier).syncMessages(messages);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Conversations panel (behind)
          ConversationsPanel(
            width: _panelWidth,
            onNewConversation: _onNewConversation,
            onSelectConversation: _onSelectConversation,
            onDeleteConversation: _onDeleteConversation,
          ),

          // Chat screen (slides over)
          AnimatedBuilder(
            animation: _slideAnim,
            builder: (context, child) {
              final slide = _slideAnim.value;
              final scale = 1.0 - ((1.0 - _chatScale) * slide);
              final translateX = _panelWidth * slide;
              final radius = _chatBorderRadius * slide;

              return Transform.translate(
                offset: Offset(translateX, 0),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: child,
                  ),
                ),
              );
            },
            child: GestureDetector(
              onTap: _isPanelOpen ? _closePanel : null,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: AbsorbPointer(
                absorbing: _isPanelOpen,
                child: Stack(
                  children: [
                    ChatScreen(
                      onMenuTap: _togglePanel,
                      onProfileTap: _showProfile,
                    ),
                    // Scrim overlay when panel is open
                    AnimatedBuilder(
                      animation: _slideAnim,
                      builder: (context, _) {
                        if (_slideAnim.value == 0) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          color: Colors.black.withValues(
                            alpha: 0.3 * _slideAnim.value,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    _slideCtrl.value += delta / _panelWidth;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity > 300) {
      // Flung open
      _slideCtrl.forward();
      setState(() => _isPanelOpen = true);
    } else if (velocity < -300) {
      // Flung closed
      _slideCtrl.reverse();
      setState(() => _isPanelOpen = false);
    } else if (_slideCtrl.value > 0.5) {
      _slideCtrl.forward();
      setState(() => _isPanelOpen = true);
    } else {
      _slideCtrl.reverse();
      setState(() => _isPanelOpen = false);
    }
  }
}
