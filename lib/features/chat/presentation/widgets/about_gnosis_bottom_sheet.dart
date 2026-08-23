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
            color: const Color(0xFF101014).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              const SizedBox(height: 10),
              const Center(child: _DragHandle()),
              const SizedBox(height: 8),

              // Header with Official Logo, Title & Close Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
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
                          'Gnosis',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Fechar',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Divider(color: Color(0x1FFFFFFF), height: 1),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Magnetic Hook Card (Instigante e Empolgante)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryDark.withValues(alpha: 0.25),
                              const Color(0xFF16161F),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.explore_rounded, color: AppColors.accentLight, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Um Mapa para o Invisível',
                                  style: TextStyle(
                                    color: AppColors.accentLight,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              'A Gnosis não é uma crença cega nem teoria abstrata: é a chave viva do autoconhecimento. '
                              'Guardada pelas grandes civilizações — do Egito e Grécia ao Oriente e Maias —, '
                              'ela revela os mistérios do cosmos e responde à pergunta mais fascinante de todas: quem você realmente é.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Section Title: As 4 Chaves da Sabedoria
                      const Text(
                        'As Quatro Chaves do Saber',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 2x2 Grid of Keys
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 480;
                          final items = [
                            const _PillarCard(
                              icon: Icons.biotech_rounded,
                              title: 'Ciência',
                              color: AppColors.primaryLight,
                              badgeBg: Color(0x253A7BD5),
                              description: 'O laboratório da mente e as leis ocultas da natureza.',
                            ),
                            const _PillarCard(
                              icon: Icons.palette_outlined,
                              title: 'Arte',
                              color: AppColors.flameLight,
                              badgeBg: Color(0x25C94040),
                              description: 'A beleza sagrada dos mistérios antigos e da alma.',
                            ),
                            const _PillarCard(
                              icon: Icons.menu_book_rounded,
                              title: 'Filosofia',
                              color: AppColors.accentLight,
                              badgeBg: Color(0x25E8B730),
                              description: 'Respostas reais para: "Quem sou eu?" e "Para onde vou?".',
                            ),
                            const _PillarCard(
                              icon: Icons.spa_outlined,
                              title: 'Mística & Religião',
                              color: Color(0xFF4EDB8C),
                              badgeBg: Color(0x254CAF50),
                              description: 'A reconexão direta do coração com a Centelha Divina.',
                            ),
                          ];

                          if (isWide) {
                            return GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 2.1,
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

                      const SizedBox(height: 18),

                      // Action Hook: Pergunte e Descubra
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14141A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, color: AppColors.accent, size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Faça uma pergunta sobre sonhos, símbolos ou espiritualidade e descubra o que a Gnosis tem a revelar.',
                                style: TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 13.5,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Official Portal Link
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openUrl(context, 'https://gnosisbrasil.com'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.08),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.public_rounded,
                                    color: AppColors.accentLight,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Explore o Portal Gnosis Brasil',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Cursos, acervo e práticas gratuitas • gnosisbrasil.com',
                                        style: TextStyle(
                                          color: AppColors.accentLight,
                                          fontSize: 12.5,
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

                      const SizedBox(height: 18),

                      // Section: Baixe o Aplicativo (Clean Store Buttons)
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
                          const SizedBox(width: 10),
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
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.badgeBg,
    required this.description,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Color badgeBg;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.95),
              fontSize: 12.5,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFF181820),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 21),
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
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      badge,
                      style: TextStyle(
                        color: AppColors.accentLight.withValues(alpha: 0.9),
                        fontSize: 11,
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
