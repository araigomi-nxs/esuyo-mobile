import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_colors.dart';
import '../../services/supabase_service.dart';
import '../../models/route_model.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  late final MobileScannerController _controller;
  bool _isProcessing = false;
  bool _torchOn = false;

  static const double _frameSize = 260.0;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;

    setState(() => _isProcessing = true);
    await _controller.stop();

    final token = code.trim();
    final RouteModel? route = await SupabaseService.fetchRouteById(token);

    if (!mounted) return;

    if (route != null && route.stops.isNotEmpty) {
      context.go('/passenger/calculation', extra: route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'QR code not recognized. Please scan a valid Esuyo jeepney QR.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      setState(() => _isProcessing = false);
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 60),
      width: _frameSize,
      height: _frameSize,
    );

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Live camera feed
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              scanWindow: scanRect,
            ),
          ),

          // Overlay: dark everywhere except scan window
          Positioned.fill(
            child: CustomPaint(painter: _ScanOverlayPainter(scanRect)),
          ),

          // Glass top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: AppColors.surface.withValues(alpha: 0.15),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    left: 8,
                    right: 8,
                    bottom: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/passenger'),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Scan frame corners + animated line — pinned exactly over the overlay hole
          Positioned(
            left: scanRect.left,
            top: scanRect.top,
            child: SizedBox(
              width: _frameSize,
              height: _frameSize,
              child: Stack(
                children: [
                  _Corner(top: true, left: true),
                  _Corner(top: true, left: false),
                  _Corner(top: false, left: true),
                  _Corner(top: false, left: false),

                  if (_isProcessing)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryContainer,
                        strokeWidth: 3,
                      ),
                    )
                  else
                    Animate(
                      onPlay: (c) => c.repeat(reverse: true),
                      effects: [
                        MoveEffect(
                          begin: const Offset(0, 0),
                          end: const Offset(0, 240),
                          duration: 2500.ms,
                          curve: Curves.easeInOut,
                        ),
                      ],
                      child: Container(
                        height: 2,
                        margin: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.primaryContainer,
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryContainer.withValues(
                                alpha: 0.8,
                              ),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Labels + controls below the scan frame
          Positioned(
            top: scanRect.bottom + 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Align the Jeepney QR code within the frame',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isProcessing
                      ? 'Verifying QR code...'
                      : 'Keep your phone steady for faster detection',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 32),

                // Torch + camera switch controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ControlButton(
                      icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                      active: _torchOn,
                      onTap: _isProcessing
                          ? null
                          : () async {
                              await _controller.toggleTorch();
                              setState(() => _torchOn = !_torchOn);
                            },
                    ),
                    const SizedBox(width: 24),
                    _ControlButton(
                      icon: Icons.cameraswitch,
                      onTap: _isProcessing
                          ? null
                          : () async {
                              await _controller.switchCamera();
                            },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter: darkens everything outside the scan window
class _ScanOverlayPainter extends CustomPainter {
  final Rect scanWindow;

  const _ScanOverlayPainter(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    // evenOdd fill rule punches a transparent hole where the paths overlap
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(4)));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) =>
      oldDelegate.scanWindow != scanWindow;
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  const _ControlButton({required this.icon, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? AppColors.primaryContainer.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.2),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final bool top;
  final bool left;

  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? const BorderSide(color: AppColors.primaryContainer, width: 4)
                : BorderSide.none,
            bottom: top
                ? BorderSide.none
                : const BorderSide(color: AppColors.primaryContainer, width: 4),
            left: left
                ? const BorderSide(color: AppColors.primaryContainer, width: 4)
                : BorderSide.none,
            right: left
                ? BorderSide.none
                : const BorderSide(color: AppColors.primaryContainer, width: 4),
          ),
          borderRadius: BorderRadius.only(
            topLeft: (top && left) ? const Radius.circular(12) : Radius.zero,
            topRight: (top && !left) ? const Radius.circular(12) : Radius.zero,
            bottomLeft: (!top && left)
                ? const Radius.circular(12)
                : Radius.zero,
            bottomRight: (!top && !left)
                ? const Radius.circular(12)
                : Radius.zero,
          ),
        ),
      ),
    );
  }
}
