import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/update_service.dart';

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
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await _checkForUpdate();
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) return;
    final role = await AuthService.currentUserRole();
    if (!mounted) return;
    if (role == 'driver') {
      context.go('/driver');
    } else {
      context.go('/passenger');
    }
  }

  Future<void> _checkForUpdate() async {
    final update = await UpdateService.checkForUpdate();
    if (update == null || !mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UpdateDialog(
        version: update['version'] as String,
        apkUrl: update['apk_url'] as String,
        releaseNotes: update['release_notes'] as String? ?? '',
      ),
    );
  }

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
            child: Center(
              child: SizedBox(
                width: 120,
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
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final String version;
  final String apkUrl;
  final String releaseNotes;

  const _UpdateDialog({
    required this.version,
    required this.apkUrl,
    required this.releaseNotes,
  });

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      await UpdateService.downloadAndInstall(
        widget.apkUrl,
        onProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Update Available',
        style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version ${widget.version} is ready to install.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          if (widget.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.releaseNotes,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: AppColors.outline),
            ),
          ],
          if (_downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: AppColors.outline.withValues(alpha: 0.2),
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Text(
              _progress > 0
                  ? 'Downloading… ${(_progress * 100).toStringAsFixed(0)}%'
                  : 'Preparing download…',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: AppColors.outline),
            ),
          ],
        ],
      ),
      actions: _downloading
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Later',
                    style: GoogleFonts.plusJakartaSans(
                        color: AppColors.outline)),
              ),
              ElevatedButton(
                onPressed: _download,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Update Now',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
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
