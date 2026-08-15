import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gnosis_chat/core/constants/app_colors.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

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
              'Termos de Uso',
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
                  title: 'Termos de Uso',
                  subtitle: 'Última atualização: 15 de Agosto de 2026',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  number: '1',
                  title: 'Aceitação dos Termos',
                  content:
                      'Ao acessar, cadastrar-se ou utilizar o Gnosis Chat ("aplicativo" ou "serviço"), você declara que leu, compreendeu e concorda expressamente com estes Termos de Uso e com nossa Política de Privacidade. Caso não concorde com qualquer disposição, solicitamos que interrompa o uso do serviço imediatamente.',
                ),
                _buildSection(
                  number: '2',
                  title: 'Descrição dos Serviços e Natureza da IA',
                  content:
                      'O Gnosis Chat é uma plataforma digital projetada para pesquisa teológica, estudo filosófico e recuperação de conhecimento com auxílio de Inteligência Artificial generativa e busca semântica em acervos literários gnósticos.\n\n'
                      '• Natureza Educacional: As respostas fornecidas destinam-se exclusivamente a fins de estudo, reflexão e pesquisa cultural/filosófica.\n'
                      '• Limitações da Tecnologia: Embora nosso motor utilize sistemas rigorosos de fundamentação em citações de livros, modelos de IA podem ocasionalmente gerar interpretações imprecisas. As respostas não constituem orientação médica, psicológica, jurídica ou financeira.',
                ),
                _buildSection(
                  number: '3',
                  title: 'Planos, Pagamentos e Renovação Automática',
                  content:
                      'O Gnosis Chat oferece planos de acesso:\n\n'
                      '• Plano Gratuito: Cota de cortesia de 3 perguntas mensais.\n'
                      '• Plano Básico (R\$ 9,99/mês): Cota mensal de 100 perguntas com citações de páginas exatas.\n'
                      '• Plano Premium (R\$ 29,99/mês): Cota mensal de 1.000 perguntas e recursos avançados.\n\n'
                      'Renovação Recorrente: As assinaturas pagas renovam-se automaticamente ao término de cada ciclo mensal, a menos que sejam canceladas pelo usuário antes da data de renovação.\n\n'
                      'Cancelamento Sem Burocracia: O usuário pode cancelar a renovação automática a qualquer momento no aplicativo. Ao cancelar, o plano e os benefícios contratados permanecem 100% ativos e disponíveis até a data final do ciclo vigente já pago.\n\n'
                      'Reativação Fácil: O usuário pode reativar a renovação de sua assinatura com 1 clique antes do término do período contratado.',
                ),
                _buildSection(
                  number: '4',
                  title: 'Conduta Adequada do Usuário',
                  content:
                      'Ao utilizar o Gnosis Chat, você concorda em:\n\n'
                      '• Não utilizar o serviço para finalidades ilícitas, abusivas, difamatórias ou que violem direitos de terceiros.\n'
                      '• Não tentar burlar os limites de cota, injetar códigos maliciosos, sobrecarregar a infraestrutura com ataques de negação de serviço (DDoS) ou realizar engenharia reversa do aplicativo.\n'
                      '• Manter a segurança e confidencialidade de suas credenciais de acesso.',
                ),
                _buildSection(
                  number: '5',
                  title: 'Propriedade Intelectual',
                  content:
                      'Todos os direitos sobre a marca Gnosis Chat, interfaces visuais, logotipos, códigos-fonte, algoritmos de orquestração e arquitetura de software são de propriedade exclusiva de seus desenvolvedores e protegidos pelas leis de propriedade intelectual e direitos autorais.',
                ),
                _buildSection(
                  number: '6',
                  title: 'Encerramento e Exclusão de Conta',
                  content:
                      '• Exclusão Voluntária: Você pode excluir permanentemente sua conta a qualquer momento diretamente no aplicativo, através do menu de Perfil ("Excluir conta"). Ao confirmar a exclusão, todo o seu histórico de conversas criptografadas, dados cadastrais e preferências serão apagados de forma irreversível de nossos servidores.\n\n'
                      '• Assinaturas e Cobranças: Ao excluir a conta, qualquer assinatura ativa gerenciada via Web (Stripe) será cancelada automaticamente. Para assinaturas realizadas via lojas de aplicativos (Apple App Store / Google Play Store), o usuário deve cancelar a renovação nos Ajustes do respectivo dispositivo, em conformidade com as diretrizes das plataformas.\n\n'
                      '• Suspensão por Violação: Reservamo-nos o direito de suspender ou encerrar o acesso de usuários que violem estes Termos ou que tentem fraudar os sistemas de pagamento, cota e segurança do serviço.',
                ),
                _buildSection(
                  number: '7',
                  title: 'Legislação Aplicável e Contato',
                  content:
                      'Estes Termos são regidos pelas leis da República Federativa do Brasil. Para dúvidas, notificações ou suporte relacionado a estes Termos, entre em contato:\n\n'
                      '📧 suporte.gnosischat@gmail.com\n'
                      '🌐 https://gnosischat.com',
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'Gnosis Chat — Conhecimento Sagrado Revelado.',
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
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: const Text(
            'TERMOS E CONDIÇÕES',
            style: TextStyle(
              color: AppColors.primaryLight,
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
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: AppColors.accentLight,
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
