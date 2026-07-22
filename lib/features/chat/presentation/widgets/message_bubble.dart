import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/widgets/suggested_followups_chips.dart';
import 'package:gnosis_chat/services/api/api_client.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final MessageEntity message;

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showContextMenu(context);
      },
      child: Align(
        alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: _isUser ? null : double.infinity,
          constraints: BoxConstraints(
            maxWidth: _isUser
                ? (MediaQuery.sizeOf(context).width * 0.78).clamp(0.0, 660.0)
                : double.infinity,
          ),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: _isUser ? _userBubble(context) : _aiBubble(context),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MessageContextSheet(content: message.content),
    );
  }

  Widget _userBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.7),
            AppColors.primaryDark.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: _content(context, AppColors.onSurface),
    );
  }

  Widget _aiBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: _content(context, AppColors.onSurface),
    );
  }

  Widget _content(BuildContext context, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectionArea(
          child: MarkdownBody(
            data: message.content,
            selectable:
                false, // Prevents Web selection crash, Handled by SelectionArea
            builders: {
              'latex': LatexElementBuilder(
                textStyle: TextStyle(color: textColor, fontSize: 15),
              ),
            },
            extensionSet: md.ExtensionSet(
              [LatexBlockSyntax(), ...md.ExtensionSet.gitHubFlavored.blockSyntaxes],
              [LatexInlineSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
            ),
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(
                  p: TextStyle(color: textColor, fontSize: 15, height: 1.5),
                  h1: TextStyle(
                    color: textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    letterSpacing: -0.5,
                  ),
                  h2: TextStyle(
                    color: textColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    letterSpacing: -0.5,
                  ),
                  h3: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  h4: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                  horizontalRuleDecoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        width: 2,
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                  ),
                  blockquote: TextStyle(
                    color: textColor.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.25),
                    border: Border(
                      left: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  blockquotePadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
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
        if (!_isUser) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: _MessageActionBar(message: message),
            ),
          ),
          Builder(
            builder: (context) {
              final followups = _getEffectiveFollowups(message);
              if (followups.isEmpty) return const SizedBox.shrink();
              return Consumer(
                builder: (context, ref, child) {
                  return SuggestedFollowupsChips(
                    followups: followups,
                    onTapFollowup: (question) {
                      ref.read(chatProvider.notifier).ask(question);
                    },
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  List<String> _getEffectiveFollowups(MessageEntity message) {
    if (message.suggestedFollowups.isNotEmpty) {
      return message.suggestedFollowups;
    }

    if (message.role == MessageRole.assistant && message.route != 'ASK_USER') {
      final content = message.content.toLowerCase();
      if (content.contains('pentagrama') ||
          content.contains('selo') ||
          content.contains('exorcismo')) {
        return const [
          'Como traçar o Pentagrama corretamente no ar?',
          'Qual o significado dos símbolos no Pentagrama?',
          'Como usar o Pentagrama na meditação diária?',
        ];
      } else if (content.contains('ego') ||
          content.contains('defeito') ||
          content.contains('psicolog')) {
        return const [
          'Como praticar a morte do Ego?',
          'Qual a diferença entre Ego e Essência?',
          'Como a auto-observação auxilia na eliminação do Ego?',
        ];
      } else if (content.contains('meditaç') ||
          content.contains('prática') ||
          content.contains('mantra')) {
        return const [
          'Quais são os mantras para aprofundar a meditação?',
          'Como acalmar a mente nos exercícios práticos?',
          'Qual o melhor horário para praticar a meditação?',
        ];
      } else if (content.contains('astral') ||
          content.contains('desdobramento') ||
          content.contains('sonho')) {
        return const [
          'Qual a melhor chave de desdobramento astral?',
          'Como manter a lucidez durante o sono?',
          'O que fazer ao despertar no mundo astral?',
        ];
      }

      return const [
        'O que é o Ego no gnosticismo?',
        'Como praticar a meditação diária?',
        'Quais são os rituais de defesa espiritual?',
      ];
    }

    return const [];
  }
}

class _CitationChip extends StatelessWidget {
  const _CitationChip({required this.citation});

  final CitationEntity citation;

  void _showCitationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CitationBottomSheet(citation: citation),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCitationSheet(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.surfaceVariant.withValues(alpha: 0.6),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Text(
          '${citation.pdfName} p.${citation.page}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.accentLight,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _CitationBottomSheet extends ConsumerStatefulWidget {
  const _CitationBottomSheet({required this.citation});

  final CitationEntity citation;

  @override
  ConsumerState<_CitationBottomSheet> createState() =>
      _CitationBottomSheetState();
}

class _CitationBottomSheetState extends ConsumerState<_CitationBottomSheet> {
  bool _isLoading = false;

  Future<void> _openPdf() async {
    setState(() {
      _isLoading = true;
    });
    HapticFeedback.lightImpact();

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get(
        '/pdfs/url',
        queryParameters: {'book_name': widget.citation.pdfName},
      );

      final data = response.data as Map<String, dynamic>;
      final url = data['url'] as String;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop(); // close sheet

        context.pushNamed(
          'pdf-viewer',
          extra: {
            'url': url,
            'bookName': widget.citation.pdfName,
            'page': widget.citation.page,
          },
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMsg = 'Erro ao carregar o PDF. Tente novamente.';
        if (e.response?.statusCode == 404) {
          errorMsg = 'PDF ainda não disponível para este livro.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.menu_book_rounded,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.citation.pdfName,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Página ${widget.citation.page}',
            style: const TextStyle(
              color: AppColors.accentLight,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.3,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(color: AppColors.accent, width: 3),
              ),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                widget.citation.snippet.isNotEmpty
                    ? '“${widget.citation.snippet}”'
                    : 'Trecho não disponível.',
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.accent,
                            ),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _openPdf,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.background,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.menu_book_rounded, size: 20),
                        label: const Text(
                          'Abrir na Página',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          if (widget.citation.snippet.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: widget.citation.snippet),
                  );
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                  _showCopiedSnackBar(context, 'Trecho copiado!');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  foregroundColor: AppColors.accentLight,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                icon: const Icon(Icons.copy_all_rounded, size: 18),
                label: const Text(
                  'Copiar Trecho',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Long press context menu
// ---------------------------------------------------------------------------
class _MessageContextSheet extends StatelessWidget {
  const _MessageContextSheet({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          _ContextAction(
            icon: Icons.copy_rounded,
            label: 'Copiar',
            onTap: () {
              Clipboard.setData(ClipboardData(text: _cleanMarkdown(content)));
              Navigator.of(context).pop();
              _showCopiedSnackBar(context, 'Copiado!');
            },
          ),

          const SizedBox(height: 4),

          _ContextAction(
            icon: Icons.share_rounded,
            label: 'Compartilhar',
            onTap: () {
              Navigator.of(context).pop();
              Share.share(content);
            },
          ),
        ],
      ),
    );
  }
}

class _ContextAction extends StatelessWidget {
  const _ContextAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.onSurface),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message Actions Bar
// ---------------------------------------------------------------------------
class _MessageActionBar extends StatelessWidget {
  const _MessageActionBar({required this.message});

  final MessageEntity message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CopyButton(content: message.content),
        const SizedBox(width: 8),
        _SharePdfButton(message: message),
      ],
    );
  }
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.content});

  final String content;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: _cleanMarkdown(widget.content)));
    HapticFeedback.lightImpact();
    setState(() {
      _copied = true;
    });

    _showCopiedSnackBar(context, 'Resposta copiada!');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(17);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _copy,
        borderRadius: border,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _copied
                ? AppColors.success.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: _copied
                  ? AppColors.success.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.12),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _copied ? Icons.check_rounded : Icons.content_copy_rounded,
                key: ValueKey(_copied),
                size: 14,
                color: _copied
                    ? AppColors.success
                    : AppColors.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// _ShareButton removed

class _SharePdfButton extends StatefulWidget {
  const _SharePdfButton({required this.message});

  final MessageEntity message;

  @override
  State<_SharePdfButton> createState() => _SharePdfButtonState();
}

class _SharePdfButtonState extends State<_SharePdfButton> {
  bool _loading = false;

  Future<void> _sharePdf() async {
    if (_loading) return;

    setState(() {
      _loading = true;
    });
    HapticFeedback.lightImpact();

    try {
      final pdfBytes = await _generatePdf(
        widget.message.content,
        widget.message.citations,
      );

      final XFile xFile;
      if (kIsWeb) {
        xFile = XFile.fromData(
          pdfBytes,
          mimeType: 'application/pdf',
          name: 'resposta_gnosis.pdf',
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/resposta_gnosis.pdf');
        await file.writeAsBytes(pdfBytes);
        xFile = XFile(
          file.path,
          mimeType: 'application/pdf',
          name: 'resposta_gnosis.pdf',
        );
      }

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }

      await Share.shareXFiles([xFile]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(17);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _sharePdf,
        borderRadius: border,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.onSurfaceVariant,
                      ),
                    ),
                  )
                : Icon(
                    Icons
                        .ios_share, // Square with arrow pointing up (universal share symbol)
                    size: 14,
                    color: AppColors.onSurface.withValues(alpha: 0.6),
                  ),
          ),
        ),
      ),
    );
  }
}

// Helper to strip markdown formatting for copy & share actions
String _cleanMarkdown(String text) {
  return text
      // Replace bold markers **text** or __text__ with text
      .replaceAll(RegExp(r'\*\*|__'), '')
      // Replace italic markers *text* or _text_ with text
      .replaceAll(RegExp(r'\*|_'), '')
      // Replace heading hashes (### Heading -> Heading)
      .replaceAll(RegExp(r'^#+\s+', multiLine: true), '')
      // Convert list indicators to clean unicode bullets (* or - -> •)
      .replaceAllMapped(
        RegExp(r'^\s*[\*\-]\s+', multiLine: true),
        (match) => '• ',
      )
      // Clean up blockquote indentation (> text -> text)
      .replaceAll(RegExp(r'^>\s+', multiLine: true), '');
}

void _showCopiedSnackBar(BuildContext context, String text) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final horizontalMargin = (screenWidth - 160) / 2;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
      ),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceVariant,
      margin: EdgeInsets.only(
        bottom: 120, // Elevates SnackBar above input bar and black overlay
        left: horizontalMargin.clamp(16.0, double.infinity),
        right: horizontalMargin.clamp(16.0, double.infinity),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

pw.Widget _buildRichText(
  String line,
  pw.Font fontRegular,
  pw.Font fontBold,
  double fontSize,
  PdfColor textColor,
) {
  final parts = line.split('**');
  final spans = <pw.InlineSpan>[];
  for (int i = 0; i < parts.length; i++) {
    final isBold = i % 2 == 1;
    // Remove single italic asterisks *text* to prevent orphan asterisks in PDF
    final partText = parts[i].replaceAll('*', '');
    spans.add(
      pw.TextSpan(
        text: partText,
        style: pw.TextStyle(
          font: isBold ? fontBold : fontRegular,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
  return pw.RichText(
    text: pw.TextSpan(
      children: spans,
      style: pw.TextStyle(
        font: fontRegular,
        fontSize: fontSize,
        color: textColor,
        height: 1.3,
      ),
    ),
  );
}

Future<Uint8List> _generatePdf(
  String markdown,
  List<CitationEntity> citations,
) async {
  final pdf = pw.Document();
  final fontRegular = pw.Font.helvetica();
  final fontBold = pw.Font.helveticaBold();
  final fontOblique = pw.Font.helveticaOblique();

  const pageFormat = PdfPageFormat(
    320, // Estreito estilo celular
    568, // Altura finita (estilo iPhone SE) para suportar MultiPage
    marginLeft: 16,
    marginRight: 16,
    marginTop: 20,
    marginBottom: 20,
  );

  const textColor = PdfColor.fromInt(0xFF2C2C2C);
  const primaryColor = PdfColor.fromInt(0xFF3A7BD5); // Royal Blue
  const accentColor = PdfColor.fromInt(0xFFCB9E28); // Gold
  const quoteBarColor = PdfColor.fromInt(0xFFE8B730);

  final lines = markdown.split('\n');
  final widgets = <pw.Widget>[];

  // Cabeçalho
  widgets.add(
    pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            'Pergunte à Gnosis',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 22,
              color: accentColor,
              letterSpacing: 1.5,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Citação & Resposta',
            style: pw.TextStyle(
              font: fontOblique,
              fontSize: 11,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            height: 0.8,
            color: const PdfColor.fromInt(0x4CCB9E28), // 30% opacidade
            width: 60,
          ),
          pw.SizedBox(height: 14),
        ],
      ),
    ),
  );

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      widgets.add(pw.SizedBox(height: 8));
      continue;
    }

    // 1. Títulos (Headers)
    if (trimmed.startsWith('#')) {
      final headingLevel = RegExp(r'^#+').stringMatch(trimmed)?.length ?? 1;
      final headingText = trimmed.replaceAll(RegExp(r'^#+\s+'), '');
      final double fontSize = headingLevel == 1
          ? 22
          : headingLevel == 2
          ? 18
          : 15;

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
          child: pw.Text(
            headingText,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: fontSize,
              color: primaryColor,
            ),
          ),
        ),
      );
    }
    // 2. Blockquotes
    else if (trimmed.startsWith('>')) {
      final quoteText = trimmed.replaceAll(RegExp(r'^>\s+'), '');
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          margin: const pw.EdgeInsets.only(bottom: 6),
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF9F9F9),
            border: pw.Border(
              left: pw.BorderSide(color: quoteBarColor, width: 2.5),
            ),
          ),
          child: _buildRichText(
            quoteText,
            fontOblique,
            fontBold,
            13,
            const PdfColor.fromInt(0xCC2C2C2C),
          ), // 80% opacidade
        ),
      );
    }
    // 3. Divisórias (Horizontal Rule)
    else if (trimmed.startsWith('---') || trimmed.startsWith('***')) {
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Container(height: 0.5, color: PdfColors.grey300),
        ),
      );
    }
    // 4. List items (Bullet points)
    else if (trimmed.startsWith('*') ||
        trimmed.startsWith('-') ||
        trimmed.startsWith('•')) {
      final listContent = trimmed.replaceFirst(RegExp(r'^[\*\-•]\s+'), '');
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 4, bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Vector circle bullet instead of unicode character (prevents missing glyph boxes)
              pw.Container(
                width: 3.5,
                height: 3.5,
                margin: const pw.EdgeInsets.only(top: 4.5, right: 6),
                decoration: const pw.BoxDecoration(
                  color: primaryColor,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.Expanded(
                child: _buildRichText(
                  listContent,
                  fontRegular,
                  fontBold,
                  14,
                  textColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    // 4. Parágrafos comuns
    else {
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: _buildRichText(trimmed, fontRegular, fontBold, 14, textColor),
        ),
      );
    }
  }

  // Citations / Fontes Citadas
  if (citations.isNotEmpty) {
    widgets.add(pw.SizedBox(height: 14));
    widgets.add(
      pw.Text(
        'FONTES CITADAS:',
        style: pw.TextStyle(
          font: fontBold,
          fontSize: 13,
          color: primaryColor,
          letterSpacing: 1,
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    for (final citation in citations) {
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 3,
                height: 3,
                margin: const pw.EdgeInsets.only(top: 4, right: 6),
                decoration: const pw.BoxDecoration(
                  color: primaryColor,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  '${citation.pdfName} (pág. ${citation.page})',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 11,
                    color: const PdfColor.fromInt(0xCC2C2C2C), // 80% opacidade
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Rodapé sutil
  widgets.add(
    pw.Column(
      children: [
        pw.SizedBox(height: 16),
        pw.Container(height: 0.5, color: PdfColors.grey300),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(
            'Gerado via Gnosis Chat RAG',
            style: pw.TextStyle(
              font: fontOblique,
              fontSize: 9.5,
              color: PdfColors.grey500,
            ),
          ),
        ),
      ],
    ),
  );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
        italic: fontOblique,
      ),
      build: (pw.Context context) => widgets,
    ),
  );

  return pdf.save();
}
