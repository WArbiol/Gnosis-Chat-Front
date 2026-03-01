import 'dart:math' as math;
import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _d2r = math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s / 2, s / 2);
    final outerRadius = s / 2;
    final innerRadius = s * 0.28;
    final strokeW = outerRadius - innerRadius;
    final arcR = (outerRadius + innerRadius) / 2;
    final rect = Rect.fromCircle(center: center, radius: arcR);

    // DICA EXTRA: Recorta tudo que sair do círculo perfeito.
    // Isso evita que a quina quadrada da barra azul (desenhada como Rect) vaze para fora do formato.
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: outerRadius)),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    // Green — right side, curving down to bottom-left
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 5 * _d2r, 115 * _d2r, false, paint);

    // Yellow — bottom-left to left
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 120 * _d2r, 90 * _d2r, false, paint);

    // Red — left to upper-left
    // Nota: como encolhemos o azul, o espaço em branco (gap) aumentou um pouco.
    // Se quiser o gap menor, aumente o sweepAngle aqui (ex: de 85 para 95).
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 210 * _d2r, 85 * _d2r, false, paint);

    // Blue arc — Ajustado para começar em 347 graus!
    // Esse é o ângulo exato onde a curva encontra o topo da barra horizontal.
    // O sweep agora é de 18 graus para continuar fechando certinho nos 5 graus do verde.
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, 347 * _d2r, 18 * _d2r, false, paint);

    // Blue crossbar — horizontal bar from center to right edge at mid-height
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx,
        center.dy - strokeW / 2,
        center.dx + outerRadius,
        center.dy + strokeW / 2,
      ),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill,
    );

    canvas.restore(); // Restaura o canvas para remover a máscara do clipPath
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
