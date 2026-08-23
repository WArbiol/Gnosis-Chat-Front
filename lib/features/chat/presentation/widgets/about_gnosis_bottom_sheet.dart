import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutGnosisBottomSheet extends StatelessWidget {
  const AboutGnosisBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AboutGnosisBottomSheet(),
    );
  }

  Future<void> _openUrl(BuildContext context, String urlStr) async {
    final uri = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o link.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir link: $e')),
        );
      }
    }
  }

  void _showAppStoreMockNotice(BuildContext context, String storeName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E24),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'O aplicativo para $storeName estará disponível em breve nas lojas oficiais!',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar with Drag Handle and Close button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    const Expanded(
                      child: Center(
                        child: _DragHandle(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Fechar',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Emblem
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.accent.withValues(alpha: 0.25),
                                AppColors.accent.withValues(alpha: 0.05),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.accentLight,
                              size: 32,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Title
                      Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              AppColors.accentLight,
                              AppColors.accent,
                              AppColors.accentLight,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            'O que é a Gnosis?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Center(
                        child: Text(
                          'A Sabedoria Sagrada & O Conhecimento do Ser',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Introduction Card
                      const _ContentCard(
                        icon: Icons.lightbulb_outline_rounded,
                        title: 'Conhecimento Vivo e Interior',
                        content:
                            'Etimologicamente, a palavra Gnosis provém do grego e significa "conhecimento iluminado e vivencial". '
                            'Longe de ser uma mera crença, dogma ou filosofia convencional, a Gnosis é o funcionalismo natural da consciência humana — uma sabedoria eterna e universal presente nas grandes culturas e tradições sagradas da humanidade.',
                      ),

                      const SizedBox(height: 16),

                      // Section: Os 4 Pilares
                      const Text(
                        'Os Quatro Pilares do Saber',
                        style: TextStyle(
                          color: AppColors.accentLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 500;
                          final items = [
                            const _PillarItem(
                              icon: Icons.biotech_rounded,
                              title: 'Ciência',
                              description: 'A ciência do laboratório interior, que estuda as leis da Natureza e ensina o autoconhecimento prático no momento presente.',
                            ),
                            const _PillarItem(
                              icon: Icons.palette_outlined,
                              title: 'Arte',
                              description: 'A Arte Régia que une a sabedoria das antigas civilizações à capacidade de esculpir as virtudes da Alma.',
                            ),
                            const _PillarItem(
                              icon: Icons.menu_book_rounded,
                              title: 'Filosofia',
                              description: 'A sabedoria perene que responde às grandes inquietações existenciais ("Quem sou?", "Para que existo?") e guia a reflexão diária.',
                            ),
                            const _PillarItem(
                              icon: Icons.spa_outlined,
                              title: 'Religião (Religare)',
                              description: 'O resgate da essência de "Religare": a união e reconexão íntima do coração humano com a sua própria Centelha Divina Interior.',
                            ),
                          ];

                          if (isWide) {
                            return GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 2.2,
                              children: items,
                            );
                          }

                          return Column(
                            children: items
                                .map((item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: item,
                                    ))
                                .toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Auto-Gnosis Card
                      const _ContentCard(
                        icon: Icons.self_improvement_rounded,
                        title: 'Auto-Gnosis: Conhece-te a ti Mesmo',
                        content:
                            'O ponto central do ensinamento gnóstico é o autoconhecimento prático. '
                            'Através da auto-observação, da meditação e da regeneração da energia interior, a Gnosis ensina a transformar o "chumbo" da personalidade no "ouro" puro do Espírito, despertando as mais nobres faculdades da alma.',
                      ),

                      const SizedBox(height: 24),

                      // Card Saiba Mais (gnosisbrasil.com)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openUrl(context, 'https://gnosisbrasil.com'),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accent.withValues(alpha: 0.18),
                                  AppColors.accent.withValues(alpha: 0.06),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.public_rounded,
                                    color: AppColors.accentLight,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Conheça o Portal Oficial',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'gnosisbrasil.com',
                                        style: TextStyle(
                                          color: AppColors.accentLight,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_outward_rounded,
                                  color: AppColors.accentLight,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Section: Baixe o Aplicativo (Web & Mobile)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_iphone_rounded,
                                  color: AppColors.accent.withValues(alpha: 0.8),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Aplicativo Móvel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tenha o acervo e a sabedoria sagrada sempre ao seu alcance.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _StoreButton(
                                    icon: Icons.apple_rounded,
                                    storeName: 'App Store',
                                    badge: 'iOS',
                                    onTap: () => _showAppStoreMockNotice(context, 'App Store (iOS)'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StoreButton(
                                    icon: Icons.play_arrow_rounded,
                                    storeName: 'Google Play',
                                    badge: 'Android',
                                    onTap: () => _showAppStoreMockNotice(context, 'Google Play (Android)'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  final IconData icon;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accentLight, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              color: AppColors.onSurface.withValues(alpha: 0.88),
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarItem extends StatelessWidget {
  const _PillarItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141418).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.accentLight, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.9),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreButton extends StatelessWidget {
  const _StoreButton({
    required this.icon,
    required this.storeName,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String storeName;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      storeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      badge,
                      style: TextStyle(
                        color: AppColors.accentLight.withValues(alpha: 0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
