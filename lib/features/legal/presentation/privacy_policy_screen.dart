import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 10),
            const Text(
              'Política de Privacidade',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              children: [
                _buildHeader(
                  title: 'Política de Privacidade',
                  subtitle: 'Última atualização: 15 de Agosto de 2026',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  number: '1',
                  title: 'Compromisso com a Privacidade',
                  content:
                      'O Gnosis Chat ("nós", "nosso" ou "aplicativo") respeita a privacidade de seus usuários e tem o compromisso inegociável de proteger os dados pessoais coletados. Esta Política de Privacidade descreve como coletamos, usamos, armazenamos e protegemos suas informações em conformidade com a Lei Geral de Proteção de Dados (LGPD - Lei nº 13.709/2018), o Regulamento Geral sobre a Proteção de Dados (GDPR) e as diretrizes de privacidade da Apple e Google.',
                ),
                _buildSection(
                  number: '2',
                  title: 'Informações que Coletamos',
                  content:
                      'Para proporcionar a experiência de estudo teológico e orquestração de IA, coletamos as seguintes categorias de dados:\n\n'
                      '• Dados de Cadastro e Autenticação: Endereço de e-mail, nome de exibição e foto de perfil fornecidos via login social (Google, Apple ou e-mail).\n'
                      '• Mensagens e Consultas: As perguntas enviadas ao chat e as respostas geradas pelo assistente.\n'
                      '• Dados de Faturamento: Status de assinatura, identificador de cliente no processador de pagamento (Stripe ou Apple/Google In-App Purchase). Nota: Nós NÃO armazenamos dados de cartão de crédito em nossos servidores.\n'
                      '• Dados Técnicos Básicos: Registros de acesso (IP, tipo de dispositivo e versão do aplicativo) estritamente para segurança, diagnóstico de falhas e prevenção de fraudes.',
                ),
                _buildSection(
                  number: '3',
                  title: 'Criptografia e Proteção de Dados',
                  content:
                      'Adotamos práticas avançadas de segurança para assegurar que suas conversas permaneçam confidenciais:\n\n'
                      '• Criptografia no Repouso: Todas as mensagens salvas no banco de dados passam por criptografia AES-256 derivada da identidade única do usuário.\n'
                      '• Criptografia em Trânsito: Todas as comunicações entre o aplicativo e os servidores utilizam protocolo HTTPS com TLS 1.3 obrigatório.\n'
                      '• Isolamento de Acesso (RLS): Políticas de segurança a nível de linha (Row Level Security) garantem que nenhum usuário tenha acesso ao histórico de outro.',
                ),
                _buildSection(
                  number: '4',
                  title: 'Finalidade do Uso dos Dados',
                  content:
                      'Seus dados são utilizados exclusivamente para:\n\n'
                      '1. Autenticar sua conta e permitir o acesso multi-dispositivo.\n'
                      '2. Processar suas consultas com inteligência artificial sobre o acervo bibliográfico gnóstico.\n'
                      '3. Gerenciar sua assinatura, cotas mensais de perguntas e renovações.\n'
                      '4. Prestar suporte técnico e responder a solicitações legítimas do titular.',
                ),
                _buildSection(
                  number: '5',
                  title: 'Não Comercialização de Dados',
                  content:
                      'Nós NUNCA vendemos, alugamos ou comercializamos seus dados pessoais com terceiros para fins publicitários ou de marketing. As mensagens de chat não são utilizadas para treinamento de modelos públicos de terceiros.',
                ),
                _buildSection(
                  number: '6',
                  title: 'Exclusão de Dados e Direito do Titular',
                  content:
                      'Em conformidade com a LGPD (Lei nº 13.709/2018), o GDPR e as Diretrizes da Apple (Guideline 5.1.1(v)), você pode excluir sua conta e todos os dados vinculados diretamente no aplicativo:\n\n'
                      '• Exclusão Direta in-App: Disponível no menu de Perfil ("Excluir conta") com efeito imediato e confirmação segura.\n'
                      '• Eliminação Irreversível em Cascata: Ao confirmar, todas as suas mensagens criptografadas, conversas, registros de perfil e credenciais de acesso no Supabase Auth são definitivamente expurgados de nossos bancos de dados.\n'
                      '• Cancelamento Financeiro: Assinaturas Web ativas (Stripe) são canceladas automaticamente no ato da exclusão. Assinaturas realizadas via App Store ou Google Play devem ser gerenciadas nos Ajustes do dispositivo conforme exigência das plataformas.',
                ),
                _buildSection(
                  number: '7',
                  title: 'Canal de Contato e Encarregado (DPO)',
                  content:
                      'Caso tenha dúvidas sobre esta política, deseje exercer seus direitos de titular ou precise de suporte sobre a privacidade de seus dados, entre em contato com nosso Encarregado de Proteção de Dados pelo e-mail:\n\n'
                      '📧 suporte.gnosischat@gmail.com\n'
                      '🌐 https://gnosischat.com',
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'Gnosis Chat — Conhecimento Sagrado com Privacidade e Respeito.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: const Text(
            'DOCUMENTO LEGAL',
            style: TextStyle(
              color: AppColors.accentLight,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: AppColors.surfaceVariant, thickness: 1),
      ],
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              content,
              style: TextStyle(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.9),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
