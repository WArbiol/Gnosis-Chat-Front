import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({
    super.key,
    required this.url,
    required this.bookName,
    required this.initialPage,
  });

  final String url;
  final String bookName;
  final int initialPage;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfViewerController _pdfViewerController;
  
  bool _isDocumentLoaded = false;
  int _currentPage = 0;
  int _totalPages = 0;
  
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  Future<void> _downloadAndShare() async {
    HapticFeedback.mediumImpact();

    if (kIsWeb) {
      // Na web, abrimos a URL para visualização e download nativo do navegador
      try {
        final uri = Uri.parse(widget.url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir o link do PDF.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final uri = Uri.parse(widget.url);
      final filename = uri.pathSegments.isNotEmpty 
          ? uri.pathSegments.last 
          : '${widget.bookName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.pdf';
      final localFile = File('${tempDir.path}/$filename');

      if (await localFile.exists()) {
        debugPrint('PDF_VIEWER: PDF already downloaded, sharing local cache: ${localFile.path}');
        await Share.shareXFiles(
          [XFile(localFile.path)],
          text: widget.bookName,
        );
        return;
      }

      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      final tempFile = File('${localFile.path}.tmp');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      debugPrint('PDF_VIEWER: Downloading full PDF to temp: ${tempFile.path}');
      final dio = Dio();
      await dio.download(
        widget.url,
        tempFile.path,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      // Rename to final location only on success (atomic write, avoids caching corrupted files if aborted)
      await tempFile.rename(localFile.path);

      setState(() {
        _isDownloading = false;
      });

      HapticFeedback.mediumImpact();
      await Share.shareXFiles(
        [XFile(localFile.path)],
        text: widget.bookName,
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao baixar o arquivo: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: AppColors.background,
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            widget.bookName,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.ios_share_rounded, color: AppColors.onSurface),
              onPressed: _downloadAndShare,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: AppColors.accent.withValues(alpha: 0.15),
              height: 1,
            ),
          ),
        ),
        body: Stack(
          children: [
            // Visualizador de PDF com Syncfusion
            SfPdfViewer.network(
              Uri.encodeFull(Uri.decodeFull(widget.url)),
              controller: _pdfViewerController,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              enableDoubleTapZooming: true,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                setState(() {
                  _isDocumentLoaded = true;
                  _totalPages = details.document.pages.count;
                  _currentPage = widget.initialPage;
                });
                // Aguarda o primeiro frame renderizar para pular para a página inicial da citação
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _pdfViewerController.jumpToPage(widget.initialPage);
                });
              },
              onPageChanged: (PdfPageChangedDetails details) {
                setState(() {
                  _currentPage = details.newPageNumber;
                });
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Falha ao abrir PDF: ${details.description}'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            
            // Placeholder de Loading Premium
            if (!_isDocumentLoaded)
              Container(
                color: AppColors.background,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Carregando páginas...',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
            // Barra de Progresso de Download (mostrada apenas ao compartilhar)
            if (_isDownloading)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.downloading_rounded, color: AppColors.accent, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Baixando PDF completo...',
                          style: TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        LinearProgressIndicator(
                          value: _downloadProgress,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: AppColors.accentLight,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Barra Flutuante de Informação de Página (Premium Bottom indicator)
            if (_isDocumentLoaded)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.25),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Zoom Out
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0);
                          },
                          child: const Icon(Icons.zoom_out_rounded, color: AppColors.onSurface, size: 20),
                        ),
                        const SizedBox(width: 12),
                        // Page selector button
                        InkWell(
                          onTap: () => _showPageJumpDialog(context),
                          child: Text(
                            'Pág. $_currentPage / $_totalPages',
                            style: const TextStyle(
                              color: AppColors.accentLight,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Zoom In
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0);
                          },
                          child: const Icon(Icons.zoom_in_rounded, color: AppColors.onSurface, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Dialog para pular direto para uma página específica
  void _showPageJumpDialog(BuildContext context) {
    final TextEditingController jumpController = TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.2), width: 0.5),
        ),
        title: const Text(
          'Ir para a Página',
          style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: jumpController,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppColors.onSurface),
          cursorColor: AppColors.accent,
          decoration: InputDecoration(
            hintText: 'Digite o número (1 a $_totalPages)',
            hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(jumpController.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                HapticFeedback.mediumImpact();
                _pdfViewerController.jumpToPage(page);
              }
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ir', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
