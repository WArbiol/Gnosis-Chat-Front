import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/auth/presentation/auth_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/glass_filter_sheet.dart';

class GlassInputBar extends ConsumerStatefulWidget {
  const GlassInputBar({
    super.key,
    required this.controller,
    required this.hasText,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool hasText;
  final VoidCallback onSend;

  @override
  ConsumerState<GlassInputBar> createState() => _GlassInputBarState();
}

class _GlassInputBarState extends ConsumerState<GlassInputBar> {
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

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GlassFilterSheet(),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.accentLight,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.close,
              size: 12,
              color: AppColors.accentLight,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFilters = ref.watch(activeFiltersProvider);
    final chips = <Widget>[];

    for (final book in activeFilters.books) {
      chips.add(_buildFilterChip(book, () {
        ref.read(activeFiltersProvider.notifier).state = activeFilters.copyWith(
          books: activeFilters.books.where((b) => b != book).toList(),
        );
      }));
    }

    for (final author in activeFilters.authors) {
      chips.add(_buildFilterChip(author, () {
        ref.read(activeFiltersProvider.notifier).state = activeFilters.copyWith(
          authors: activeFilters.authors.where((a) => a != author).toList(),
        );
      }));
    }

    final authState = ref.watch(authProvider);
    final user = authState.maybeWhen(
      authenticated: (u) => u,
      orElse: () => null,
    );
    final hasSecondChamberAccess = user != null && user.chamberLevel >= 2;

    if (hasSecondChamberAccess && activeFilters.chamberLevels.length == 1) {
      final label = activeFilters.chamberLevels.first == 1 ? '1ª Câmara' : '2ª Câmara';
      chips.add(_buildFilterChip(label, () {
        ref.read(activeFiltersProvider.notifier).state = activeFilters.copyWith(
          chamberLevels: const [1, 2],
        );
      }));
    }

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chips.isNotEmpty) ...[
                SizedBox(
                  height: 32,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(children: chips),
                  ),
                ),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Filter Button
                  IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: activeFilters.isEmpty ? AppColors.onSurfaceVariant : AppColors.accent,
                      size: 20,
                    ),
                    onPressed: () => _showFilterSheet(context),
                  ),

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
                            horizontal: 8,
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
                  const SizedBox(width: 4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
