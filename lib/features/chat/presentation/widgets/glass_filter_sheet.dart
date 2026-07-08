import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/auth/presentation/auth_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_provider.dart';

enum FilterTab { books, authors }

class GlassFilterSheet extends ConsumerStatefulWidget {
  const GlassFilterSheet({super.key});

  @override
  ConsumerState<GlassFilterSheet> createState() => _GlassFilterSheetState();
}

class _GlassFilterSheetState extends ConsumerState<GlassFilterSheet> {
  late List<String> _selectedBooks;
  late List<String> _selectedAuthors;
  late List<int> _selectedChambers;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  FilterTab _currentTab = FilterTab.books;

  @override
  void initState() {
    super.initState();
    final activeFilters = ref.read(activeFiltersProvider);
    _selectedBooks = List.from(activeFilters.books);
    _selectedAuthors = List.from(activeFilters.authors);
    _selectedChambers = List.from(activeFilters.chamberLevels);

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _apply() {
    ref.read(activeFiltersProvider.notifier).state = ActiveFilters(
      books: _selectedBooks,
      authors: _selectedAuthors,
      chamberLevels: _selectedChambers,
    );
    Navigator.pop(context);
    HapticFeedback.mediumImpact();
  }

  void _clear() {
    setState(() {
      _selectedBooks.clear();
      _selectedAuthors.clear();
      _selectedChambers = [1, 2];
      _searchController.clear();
      _searchQuery = '';
      _currentTab = FilterTab.books;
    });
  }

  Widget _buildChamberButton(int level, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            if (_selectedChambers.length > 1) {
              _selectedChambers.remove(level);
            }
          } else {
            _selectedChambers.add(level);
          }
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accentLight : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, bool isSelected, {required int count}) {
    final countLabel = count > 0 ? ' ($count)' : '';
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = label == 'Obras' ? FilterTab.books : FilterTab.authors;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.08),
                width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$label$countLabel',
          style: TextStyle(
            color: isSelected ? AppColors.accentLight : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionChip(String label, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.accentLight,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.cancel_rounded,
              size: 14,
              color: AppColors.accentLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.accentLight : AppColors.onSurface,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.accent : Colors.white.withValues(alpha: 0.2),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(pdfCatalogProvider);
    final authState = ref.watch(authProvider);
    final user = authState.maybeWhen(
      authenticated: (u) => u,
      orElse: () => null,
    );
    final hasSecondChamberAccess = user != null && user.chamberLevel >= 2;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtros de Pesquisa',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  TextButton(
                    onPressed: _clear,
                    child: const Text(
                      'Limpar',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Bar
              TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Filtrar por obra ou autor...',
                  hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
                  prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Tabs selector
              Row(
                children: [
                  Expanded(
                    child: _buildTabButton('Obras', _currentTab == FilterTab.books, count: _selectedBooks.length),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabButton('Autores', _currentTab == FilterTab.authors, count: _selectedAuthors.length),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Selected Chips
              if (_selectedBooks.isNotEmpty || _selectedAuthors.isNotEmpty) ...[
                SizedBox(
                  height: 38,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ..._selectedBooks.map((book) => _buildSelectionChip(book, () {
                          setState(() => _selectedBooks.remove(book));
                        })),
                        ..._selectedAuthors.map((author) => _buildSelectionChip(author, () {
                          setState(() => _selectedAuthors.remove(author));
                        })),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Main scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      catalogAsync.when(
                        data: (catalog) {
                          // Extract unique books with chamber information
                          final allBooks = catalog.map((e) {
                            return {
                              'title': e['book_name'] as String,
                              'author': e['author'] as String,
                              'chamber': e['chamber'] as int? ?? 1,
                            };
                          }).toList();

                          final uniqueBooks = <String, Map<String, dynamic>>{};
                          for (final b in allBooks) {
                            uniqueBooks[b['title'] as String] = b;
                          }
                          final booksList = uniqueBooks.values.toList();

                          // 1. Filter books by selected chambers (if user has 2nd chamber access)
                          var chamberFilteredBooks = booksList;
                          if (hasSecondChamberAccess) {
                            chamberFilteredBooks = booksList.where((b) {
                              final ch = b['chamber'] as int;
                              return _selectedChambers.contains(ch);
                            }).toList();
                          }

                          // 2. Filter books by selected authors (cross-filtering)
                          var authorFilteredBooks = chamberFilteredBooks;
                          if (_selectedAuthors.isNotEmpty) {
                            authorFilteredBooks = chamberFilteredBooks.where((b) {
                              final auth = b['author'] as String;
                              return _selectedAuthors.contains(auth);
                            }).toList();
                          }

                          // Apply search query filter to books
                          final query = _searchQuery.toLowerCase();
                          final filteredBooks = authorFilteredBooks.where((b) {
                            return b['title']!.toLowerCase().contains(query) ||
                                   b['author']!.toLowerCase().contains(query);
                          }).toList();

                          // Extract unique authors that have books in the selected chambers
                          final authorsList = chamberFilteredBooks
                              .map((e) => e['author'] as String)
                              .toSet()
                              .toList();

                           // Sort: prioritize V.M. Samael Aun Weor first, V.M. Lakhsmi Daimon second, others alphabetically
                          authorsList.sort((a, b) {
                            final normA = a.toLowerCase();
                            final normB = b.toLowerCase();
                            
                            // Check if a or b is Samael
                            final isSamaelA = normA.contains('samael');
                            final isSamaelB = normB.contains('samael');
                            if (isSamaelA && !isSamaelB) return -1;
                            if (!isSamaelA && isSamaelB) return 1;
                            
                            // Check if a or b is Lakhsmi
                            final isLakhsmiA = normA.contains('lakhsmi');
                            final isLakhsmiB = normB.contains('lakhsmi');
                            if (isLakhsmiA && !isLakhsmiB) return -1;
                            if (!isLakhsmiA && isLakhsmiB) return 1;
                            
                            return a.compareTo(b);
                          });

                          // Apply search query filter to authors
                          final filteredAuthors = authorsList.where((a) {
                            return a.toLowerCase().contains(query);
                          }).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_currentTab == FilterTab.books) ...[
                                if (filteredBooks.isNotEmpty) ...[
                                  ...filteredBooks.map((book) {
                                    final title = book['title']!;
                                    final author = book['author']!;
                                    final isSelected = _selectedBooks.contains(title);
                                    return _buildItemTile(
                                      title: title,
                                      subtitle: author,
                                      isSelected: isSelected,
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedBooks.remove(title);
                                          } else {
                                            _selectedBooks.add(title);
                                          }
                                        });
                                        HapticFeedback.lightImpact();
                                      },
                                    );
                                  }),
                                ] else
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 32),
                                    child: Center(
                                      child: Text(
                                        'Nenhuma obra encontrada.',
                                        style: TextStyle(color: AppColors.onSurfaceVariant),
                                      ),
                                    ),
                                  ),
                              ],

                              if (_currentTab == FilterTab.authors) ...[
                                if (filteredAuthors.isNotEmpty) ...[
                                  ...filteredAuthors.map((author) {
                                    final isSelected = _selectedAuthors.contains(author);
                                    return _buildItemTile(
                                      title: author,
                                      isSelected: isSelected,
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedAuthors.remove(author);
                                          } else {
                                            _selectedAuthors.add(author);
                                          }
                                        });
                                        HapticFeedback.lightImpact();
                                      },
                                    );
                                  }),
                                ] else
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 32),
                                    child: Center(
                                      child: Text(
                                        'Nenhum autor encontrado.',
                                        style: TextStyle(color: AppColors.onSurfaceVariant),
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(color: AppColors.accent),
                          ),
                        ),
                        error: (err, _) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Erro ao carregar catálogo: $err',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Chamber filter row (only if user has access to 2nd chamber)
              if (hasSecondChamberAccess) ...[
                const Text(
                  'Câmara',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildChamberButton(1, '1ª Câmara', _selectedChambers.contains(1)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildChamberButton(2, '2ª Câmara', _selectedChambers.contains(2)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Apply button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Aplicar Filtros',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
