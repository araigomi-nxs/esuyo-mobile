import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final double amount;
  final String paymentMethod;
  final double? newBalance;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.paymentMethod,
    this.newBalance,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Animated checkmark circle
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.tertiaryContainer,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.tertiary.withValues(alpha: 0.3),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Success message
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Payment Successful!',
                          style: GoogleFonts.lexend(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.newBalance != null
                              ? 'Your trip fare has been paid'
                              : 'Your wallet has been topped up',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Transaction details
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Amount
                        _buildDetailRow(
                          label: widget.newBalance != null
                              ? 'Amount Paid'
                              : 'Amount Added',
                          value: widget.newBalance != null
                              ? '-₱${widget.amount.toStringAsFixed(2)}'
                              : '₱${widget.amount.toStringAsFixed(2)}',
                          isHighlight: true,
                        ),
                        const SizedBox(height: 16),
                        Divider(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.2,
                          ),
                          height: 1,
                        ),
                        const SizedBox(height: 16),
                        // Payment method
                        _buildDetailRow(
                          label: 'Payment Method',
                          value: widget.paymentMethod,
                        ),
                        if (widget.newBalance != null) ...[
                          const SizedBox(height: 16),
                          Divider(
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.2,
                            ),
                            height: 1,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            label: 'New Balance',
                            value: '₱${widget.newBalance!.toStringAsFixed(2)}',
                            isNewBalance: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Action buttons
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: ElevatedButton(
                      onPressed: () => context.go('/passenger'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        shadowColor: AppColors.primaryContainer.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      child: Text(
                        'Back to Home',
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    bool isHighlight = false,
    bool isNewBalance = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isNewBalance ? FontWeight.w700 : FontWeight.w500,
            color: isNewBalance ? AppColors.tertiary : AppColors.outline,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: isHighlight || isNewBalance
                ? FontWeight.w900
                : FontWeight.bold,
            color: isHighlight
                ? AppColors.tertiary
                : isNewBalance
                ? AppColors.tertiary
                : AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
