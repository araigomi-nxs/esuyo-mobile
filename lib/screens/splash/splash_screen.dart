import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _albayColor = Color(0xFFD4580A);

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Connected\nAlbay',
      'subtitle':
          'Proudly built for Albay. Serving every route from Legazpi City to the province.',
      'image': null,
      'color': _albayColor,
    },
    {
      'title': 'Modernizing\nPublic Transport',
      'subtitle':
          'Experience the future of jeepney travel with real-time tracking and digital solutions.',
      'image': Icons.directions_bus_rounded,
      'color': AppColors.primary,
    },
    {
      'title': 'Cashless\nPayments',
      'subtitle':
          'Say goodbye to loose change. Pay securely with your phone anywhere.',
      'image': Icons.contactless_rounded,
      'color': AppColors.tertiary,
    },
    {
      'title': 'Smart\nRoute Planning',
      'subtitle': 'Know exactly where to ride. Find the best jeepney routes.',
      'image': Icons.map_rounded,
      'color': AppColors.secondary,
    },
    {
      'title': 'Safe &\nSecure Rides',
      'subtitle':
          'Verified drivers, tracked rides. Your safety is our priority.',
      'image': Icons.verified_user_rounded,
      'color': Colors.green.shade600,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/select-mode');
    }
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _skip() {
    context.go('/select-mode');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              final color = page['color'] as Color;
              final imageData = page['image'];
              return Stack(
                children: [
                  Positioned(
                    right: -50,
                    bottom: 50,
                    child: Opacity(
                      opacity: 0.12,
                      child: Transform.rotate(
                        angle: -0.1,
                        child: const Icon(
                          Icons.directions_bus_filled,
                          size: 180,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -60,
                    top: 120,
                    child: Opacity(
                      opacity: 0.08,
                      child: Transform.rotate(
                        angle: 0.15,
                        child: const Icon(
                          Icons.directions_bus_filled,
                          size: 120,
                          color: AppColors.tertiary,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: imageData == null
                                ? SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: CustomPaint(
                                      painter: _VolcanoRuinsSymbol(
                                        color: color,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    imageData as IconData,
                                    size: 70,
                                    color: color,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page['title'] as String,
                          style: GoogleFonts.lexend(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page['subtitle'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppColors.outline,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 120 + bottomPad,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return GestureDetector(
                  onTap: () => _goToPage(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : AppColors.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          Positioned(
            bottom: 48 + bottomPad,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.outline,
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1 ? 'Start' : 'Next',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_currentPage < _pages.length - 1) ...[
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ],
                    ),
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

/// Volcano icon: crater rim, perfect cone body, lava drips, ground base.
class _VolcanoRuinsSymbol extends CustomPainter {
  final Color color;
  const _VolcanoRuinsSymbol({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Ground base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.80, w, h * 0.20),
        const Radius.circular(4),
      ),
      Paint()..color = color.withValues(alpha: 0.30),
    );

    // Volcano cone body
    final cone = Path()
      ..moveTo(w * 0.50, h * 0.22)
      ..lineTo(w * 0.96, h * 0.80)
      ..lineTo(w * 0.04, h * 0.80)
      ..close();
    canvas.drawPath(cone, fill);

    // Highlight on left face of cone
    final highlight = Path()
      ..moveTo(w * 0.50, h * 0.22)
      ..lineTo(w * 0.04, h * 0.80)
      ..lineTo(w * 0.28, h * 0.80)
      ..close();
    canvas.drawPath(
      highlight,
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );

    // Crater rim (flat-top U shape)
    final rimW = w * 0.38;
    final rimH = h * 0.12;
    final rimLeft = w * 0.50 - rimW / 2;
    final rimTop = h * 0.10;
    final rimPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    // Left wall
    canvas.drawRect(
      Rect.fromLTWH(rimLeft, rimTop, rimW * 0.22, rimH),
      rimPaint,
    );
    // Right wall
    canvas.drawRect(
      Rect.fromLTWH(rimLeft + rimW * 0.78, rimTop, rimW * 0.22, rimH),
      rimPaint,
    );

    // Lava glow inside crater
    canvas.drawRect(
      Rect.fromLTWH(
        rimLeft + rimW * 0.22,
        rimTop + rimH * 0.35,
        rimW * 0.56,
        rimH * 0.65,
      ),
      Paint()..color = color.withValues(alpha: 0.45),
    );

    // Eruption — three rising dots above crater
    final dotPaint = Paint()..color = color.withValues(alpha: 0.70);
    canvas.drawCircle(Offset(w * 0.50, h * 0.02), w * 0.045, dotPaint);
    canvas.drawCircle(
      Offset(w * 0.38, h * 0.055),
      w * 0.032,
      Paint()..color = color.withValues(alpha: 0.45),
    );
    canvas.drawCircle(
      Offset(w * 0.62, h * 0.055),
      w * 0.032,
      Paint()..color = color.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(_VolcanoRuinsSymbol old) => old.color != color;
}
