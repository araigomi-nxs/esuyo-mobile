import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/esuyo_logo.dart';

class AlbaySplashScreen extends StatefulWidget {
  const AlbaySplashScreen({super.key});

  @override
  State<AlbaySplashScreen> createState() => _AlbaySplashScreenState();
}

class _AlbaySplashScreenState extends State<AlbaySplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideUp = Tween<double>(
      begin: 28,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) context.go('/splash');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return GestureDetector(
      onTap: () => context.go('/splash'),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        body: Stack(
          children: [
            // Sky gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.30, 0.52, 0.62, 0.62, 1.0],
                  colors: [
                    Color(0xFF050E1A),
                    Color(0xFF0D1B2A),
                    Color(0xFF1A3A5C),
                    Color(0xFF3D6B8E),
                    Color(0xFF2D5A3D),
                    Color(0xFF1A3520),
                  ],
                ),
              ),
            ),
            // Scene illustration
            Positioned.fill(
              child: CustomPaint(painter: _CagsawaScenePainter()),
            ),
            // Animated text overlay at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FadeTransition(
                opacity: _fadeIn,
                child: AnimatedBuilder(
                  animation: _slideUp,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _slideUp.value),
                    child: child,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: EsuyoLogo(width: 96, height: 68, padding: 6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'esuyo',
                        style: GoogleFonts.lexend(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'CONNECTED ALBAY',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                      Text(
                        'Tap anywhere to continue',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.4),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 52 + bottomPad),
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
}

class _CagsawaScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawStars(canvas, w, h);
    _drawMoon(canvas, w, h);
    _drawMayon(canvas, w, h);
    _drawLandscape(canvas, w, h);
    _drawCagsawaRuins(canvas, w, h);
    _drawForegroundTrees(canvas, w, h);
    _drawBottomFade(canvas, w, h);
  }

  void _drawStars(Canvas canvas, double w, double h) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    const positions = [
      [0.08, 0.04],
      [0.18, 0.09],
      [0.32, 0.05],
      [0.44, 0.02],
      [0.58, 0.07],
      [0.67, 0.03],
      [0.78, 0.08],
      [0.90, 0.05],
      [0.12, 0.14],
      [0.26, 0.18],
      [0.50, 0.12],
      [0.70, 0.15],
      [0.85, 0.11],
      [0.95, 0.17],
      [0.03, 0.20],
      [0.40, 0.20],
    ];
    for (final s in positions) {
      canvas.drawCircle(Offset(w * s[0], h * s[1]), 1.3, paint);
    }
    // A few larger twinkling stars
    paint.color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(w * 0.15, h * 0.07), 2.0, paint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.06), 1.8, paint);
    canvas.drawCircle(Offset(w * 0.38, h * 0.11), 1.6, paint);
  }

  void _drawMoon(Canvas canvas, double w, double h) {
    final cx = w * 0.80;
    final cy = h * 0.10;

    // Soft glow halo
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.12), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 55));
    canvas.drawCircle(Offset(cx, cy), 55, glowPaint);

    // Moon disc
    canvas.drawCircle(
      Offset(cx, cy),
      22,
      Paint()..color = const Color(0xFFEEF2FF),
    );

    // Crescent shadow
    canvas.drawCircle(
      Offset(cx + 11, cy - 5),
      18,
      Paint()..color = const Color(0xFF0D1B2A),
    );
  }

  void _drawMayon(Canvas canvas, double w, double h) {
    final tipX = w * 0.60;
    final tipY = h * 0.24;
    final baseY = h * 0.62;

    // Volcano body — perfect cone
    final bodyPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Color(0xFF253545), Color(0xFF1C2B38)],
          ).createShader(
            Rect.fromLTRB(tipX - w * 0.32, tipY, tipX + w * 0.32, baseY),
          );

    final path = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(tipX + w * 0.32, baseY)
      ..lineTo(tipX - w * 0.30, baseY)
      ..close();
    canvas.drawPath(path, bodyPaint);

    // Right-side lighting (subtle)
    final lightPath = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(tipX + w * 0.32, baseY)
      ..lineTo(tipX + w * 0.10, baseY)
      ..close();
    canvas.drawPath(
      lightPath,
      Paint()..color = Colors.white.withValues(alpha: 0.04),
    );

    // Volcanic crater glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF7B45).withValues(alpha: 0.55),
          const Color(0xFFFF4500).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(tipX, tipY), radius: 36));
    canvas.drawCircle(Offset(tipX, tipY), 36, glowPaint);

    // Lava trickle (faint)
    final lavaPaint = Paint()
      ..color = const Color(0xFFFF6020).withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final lavaPath = Path()
      ..moveTo(tipX - w * 0.01, tipY + h * 0.015)
      ..quadraticBezierTo(
        tipX - w * 0.04,
        tipY + h * 0.07,
        tipX - w * 0.06,
        tipY + h * 0.14,
      );
    canvas.drawPath(lavaPath, lavaPaint);

    // Ash cap at summit
    final capPath = Path()
      ..moveTo(tipX, tipY - 2)
      ..lineTo(tipX + w * 0.04, tipY + h * 0.028)
      ..lineTo(tipX - w * 0.04, tipY + h * 0.028)
      ..close();
    canvas.drawPath(
      capPath,
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
  }

  void _drawLandscape(Canvas canvas, double w, double h) {
    // Mid-ground green hills
    final hillPaint = Paint()..color = const Color(0xFF2A5038);
    final hillPath = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.12, h * 0.54, w * 0.28, h * 0.59)
      ..quadraticBezierTo(w * 0.40, h * 0.63, w * 0.52, h * 0.58)
      ..quadraticBezierTo(w * 0.68, h * 0.52, w * 0.82, h * 0.60)
      ..quadraticBezierTo(w * 0.92, h * 0.65, w, h * 0.61)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hillPath, hillPaint);

    // Foreground ground
    final groundPaint = Paint()..color = const Color(0xFF1E3A26);
    final groundPath = Path()
      ..moveTo(0, h * 0.74)
      ..quadraticBezierTo(w * 0.30, h * 0.70, w * 0.55, h * 0.74)
      ..quadraticBezierTo(w * 0.78, h * 0.78, w, h * 0.73)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(groundPath, groundPaint);

    // Horizon atmospheric haze
    final hazePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF3D6B8E).withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.54, w, h * 0.14));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.54, w, h * 0.14), hazePaint);
  }

  void _drawCagsawaRuins(Canvas canvas, double w, double h) {
    final tx = w * 0.25;
    final tBase = h * 0.835;
    final tW = w * 0.095;
    final tH = h * 0.30;

    final stone = Paint()..color = const Color(0xFF8C7455);
    final stoneDark = Paint()..color = const Color(0xFF674F36);
    final stoneOutline = Paint()
      ..color = const Color(0xFF3E2E18).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final void_ = Paint()..color = const Color(0xFF0D1218);

    // --- Main tower body ---
    final towerRect = Rect.fromLTWH(tx - tW / 2, tBase - tH, tW, tH);
    canvas.drawRect(towerRect, stone);
    canvas.drawRect(towerRect, stoneOutline);

    // Shadow side (right ~quarter)
    canvas.drawRect(
      Rect.fromLTWH(tx + tW * 0.22, tBase - tH, tW * 0.28, tH),
      stoneDark,
    );

    // Horizontal stone courses
    final lineP = Paint()
      ..color = const Color(0xFF3E2E18).withValues(alpha: 0.25)
      ..strokeWidth = 0.6;
    for (int i = 1; i <= 9; i++) {
      final y = tBase - tH + tH * i / 9;
      canvas.drawLine(Offset(tx - tW / 2, y), Offset(tx + tW / 2, y), lineP);
    }
    // Vertical joints (staggered per row)
    for (int i = 0; i < 5; i++) {
      final y1 = tBase - tH + tH * i / 5;
      final y2 = tBase - tH + tH * (i + 1) / 5;
      canvas.drawLine(Offset(tx, y1), Offset(tx, y2), lineP);
      canvas.drawLine(
        Offset(tx - tW * 0.3, y1),
        Offset(tx - tW * 0.3, y2),
        lineP,
      );
    }

    // --- Large arched window (bell opening) ---
    final aw = tW * 0.44;
    final ah = tH * 0.17;
    final aY = tBase - tH * 0.60;
    _drawArch(canvas, tx, aY, aw, ah, void_);

    // --- Upper smaller arch ---
    final aw2 = tW * 0.30;
    final ah2 = tH * 0.10;
    final aY2 = tBase - tH * 0.85;
    _drawArch(canvas, tx, aY2, aw2, ah2, void_);

    // --- Battlements (crenellations) at top ---
    final mW = tW / 5.5;
    final mH = tH * 0.055;
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(tx - tW / 2 + i * mW * 1.6, tBase - tH - mH, mW, mH),
        stone,
      );
    }

    // --- Left ruined wall extension ---
    final wallPaint = Paint()..color = const Color(0xFF7A6348);
    final wallH1 = tH * 0.42;
    final wallW1 = tW * 0.75;
    final wX1 = tx - tW / 2 - wallW1;
    canvas.drawRect(
      Rect.fromLTWH(wX1, tBase - wallH1, wallW1, wallH1),
      wallPaint,
    );
    // Rough broken top edge
    final brokenTop = Paint()..color = const Color(0xFF1E3A26);
    canvas.drawPath(
      Path()
        ..moveTo(wX1, tBase - wallH1)
        ..lineTo(wX1 + wallW1 * 0.2, tBase - wallH1 - tH * 0.04)
        ..lineTo(wX1 + wallW1 * 0.5, tBase - wallH1 + tH * 0.02)
        ..lineTo(wX1 + wallW1 * 0.75, tBase - wallH1 - tH * 0.03)
        ..lineTo(wX1 + wallW1, tBase - wallH1)
        ..lineTo(wX1 + wallW1, tBase - wallH1 - 2)
        ..lineTo(wX1, tBase - wallH1 - 2)
        ..close(),
      brokenTop,
    );

    // --- Right ruined wall extension (shorter) ---
    final wallH2 = tH * 0.25;
    final wallW2 = tW * 0.55;
    canvas.drawRect(
      Rect.fromLTWH(tx + tW / 2, tBase - wallH2, wallW2, wallH2),
      wallPaint,
    );
    // Rough broken top
    final wX2 = tx + tW / 2;
    canvas.drawPath(
      Path()
        ..moveTo(wX2, tBase - wallH2)
        ..lineTo(wX2 + wallW2 * 0.3, tBase - wallH2 - tH * 0.03)
        ..lineTo(wX2 + wallW2 * 0.6, tBase - wallH2 + tH * 0.015)
        ..lineTo(wX2 + wallW2, tBase - wallH2)
        ..lineTo(wX2 + wallW2, tBase - wallH2 - 2)
        ..lineTo(wX2, tBase - wallH2 - 2)
        ..close(),
      brokenTop,
    );

    // --- Vegetation / vines on the base ---
    final vegPaint = Paint()
      ..color = const Color(0xFF1E5C28)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(tx - tW * 1.1, tBase - tH * 0.06),
        width: tW * 0.65,
        height: tH * 0.09,
      ),
      vegPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(tx + tW * 0.85, tBase - tH * 0.05),
        width: tW * 0.55,
        height: tH * 0.08,
      ),
      vegPaint,
    );
    // Small vine patches on tower itself
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(tx - tW * 0.35, tBase - tH * 0.18),
        width: tW * 0.20,
        height: tH * 0.04,
      ),
      Paint()..color = const Color(0xFF1E5C28).withValues(alpha: 0.5),
    );
  }

  void _drawArch(
    Canvas canvas,
    double cx,
    double top,
    double aw,
    double ah,
    Paint fill,
  ) {
    final path = Path()
      ..moveTo(cx - aw / 2, top + ah)
      ..lineTo(cx - aw / 2, top + ah * 0.35)
      ..arcToPoint(
        Offset(cx + aw / 2, top + ah * 0.35),
        radius: Radius.circular(aw / 2),
        clockwise: false,
      )
      ..lineTo(cx + aw / 2, top + ah)
      ..close();
    canvas.drawPath(path, fill);
  }

  void _drawForegroundTrees(Canvas canvas, double w, double h) {
    final paint = Paint()..color = const Color(0xFF0F2A14);

    void drawPineTree(double x, double baseY, double height, double spread) {
      // trunk
      canvas.drawRect(
        Rect.fromLTWH(x - 2, baseY - height * 0.3, 4, height * 0.3),
        paint,
      );
      // three layered triangles for a palm/pine silhouette
      for (int layer = 0; layer < 3; layer++) {
        final ly = baseY - height * (0.3 + layer * 0.25);
        final lw = spread * (1.0 - layer * 0.25);
        canvas.drawPath(
          Path()
            ..moveTo(x, ly - height * 0.27)
            ..lineTo(x + lw, ly)
            ..lineTo(x - lw, ly)
            ..close(),
          paint,
        );
      }
    }

    drawPineTree(w * 0.04, h * 0.84, h * 0.14, w * 0.038);
    drawPineTree(w * 0.08, h * 0.82, h * 0.17, w * 0.032);
    drawPineTree(w * 0.84, h * 0.82, h * 0.15, w * 0.04);
    drawPineTree(w * 0.90, h * 0.80, h * 0.18, w * 0.036);
    drawPineTree(w * 0.96, h * 0.83, h * 0.13, w * 0.030);
  }

  void _drawBottomFade(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
      ).createShader(Rect.fromLTWH(0, h * 0.52, w, h * 0.48));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.52, w, h * 0.48), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
