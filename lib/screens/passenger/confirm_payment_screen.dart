import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../services/wallet_service.dart';
import '../../services/active_trip_service.dart';
import '../../utils/fare_matrix.dart';
import '../../models/route_model.dart';

class ConfirmPaymentScreen extends StatefulWidget {
  final String startingPoint;
  final String dropOffPoint;
  final double distance;
  final String vehicleType;
  final double baseFare;
  final double fare;
  final double totalFare;
  final bool hasDiscount;
  final int tipAmount;
  final int estimatedMinutes;
  final String paymentMethod;
  final RouteModel? route;

  const ConfirmPaymentScreen({
    super.key,
    required this.startingPoint,
    required this.dropOffPoint,
    this.distance = 0.0,
    this.vehicleType = 'puj',
    required this.baseFare,
    required this.fare,
    required this.totalFare,
    required this.hasDiscount,
    required this.tipAmount,
    this.estimatedMinutes = 0,
    this.paymentMethod = 'Wallet',
    this.route,
  });

  @override
  State<ConfirmPaymentScreen> createState() => _ConfirmPaymentScreenState();
}

class _ConfirmPaymentScreenState extends State<ConfirmPaymentScreen> {
  late double discountAmount;
  late double fareAfterDiscount;
  bool _isProcessing = false;

  // Jeepney info (mock data - replace with real data from backend)
  final String jeepneyPlateNumber = 'ABC 1234';
  final String driverName = 'Juan Dela Cruz';
  final String operatorContact = '+63 912 345 6789';

  @override
  void initState() {
    super.initState();
    discountAmount = widget.hasDiscount ? widget.fare * 0.2 : 0.0;
    fareAfterDiscount = widget.fare - discountAmount;
  }

  String get _vehicleLabel {
    final v = FareMatrix.getRates(widget.vehicleType);
    switch (widget.vehicleType) {
      case 'puj':
        return 'Traditional Jeepney';
      case 'mpuj':
        return 'Modern Jeepney';
      case 'pub-city':
        return 'City Bus (Ordinary)';
      case 'pub-city-ac':
        return 'City Bus (Aircon)';
      case 'uv-express':
        return 'UV Express';
      default:
        return 'Traditional Jeepney';
    }
  }

  String get _estimatedTime {
    if (widget.estimatedMinutes <= 0) return '—';
    if (widget.estimatedMinutes < 60) return '${widget.estimatedMinutes} min';
    final h = widget.estimatedMinutes ~/ 60;
    final m = widget.estimatedMinutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  Future<void> _confirmPayment() async {
    setState(() => _isProcessing = true);
    try {
      final newBalance = await WalletService.instance.spend(widget.totalFare);
      if (!mounted) return;

      ActiveTripService.instance.startTrip(ActiveTripData(
        from: widget.startingPoint,
        to: widget.dropOffPoint,
        distanceKm: widget.distance,
        fare: widget.totalFare,
        vehicleType: widget.vehicleType,
        estimatedMinutes: widget.estimatedMinutes,
        route: widget.route,
      ));

      context.pushNamed(
        'payment_success',
        extra: {
          'amount': widget.totalFare,
          'paymentMethod': widget.paymentMethod,
          'newBalance': newBalance,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Bad state: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Confirm Payment',
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        leading: IconButton(
          onPressed: _isProcessing ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRIP DETAILS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Starting Point
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'A',
                              style: GoogleFonts.lexend(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Starting Point',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: AppColors.outline,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.startingPoint,
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      color: AppColors.outlineVariant.withValues(alpha: 0.2),
                      height: 1,
                    ),
                    const SizedBox(height: 16),
                    // Drop-off Point
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'B',
                              style: GoogleFonts.lexend(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Drop-off Point',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: AppColors.outline,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.dropOffPoint,
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.distance > 0) ...[
                      const SizedBox(height: 16),
                      Divider(
                        color: AppColors.outlineVariant.withValues(alpha: 0.2),
                        height: 1,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.straighten_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${widget.distance.toStringAsFixed(2)} km',
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.schedule_rounded,
                            color: AppColors.outline,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _estimatedTime,
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_bus_rounded,
                            color: AppColors.outline,
                            size: 16,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _vehicleLabel,
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Fare Breakdown Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FARE BREAKDOWN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.outline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (widget.distance > 0) ...[
                      _fareLine(
                        'Base Fare (${widget.distance.toStringAsFixed(2)} km)',
                        widget.fare,
                      ),
                    ] else ...[
                      _fareLine('Base Fare', widget.baseFare),
                    ],
                    // Discount (if applicable)
                    if (widget.hasDiscount) ...[
                      _fareLine('Discount (20%)', -discountAmount,
                          isDiscount: true),
                    ],
                    // Fare After Discount
                    if (widget.hasDiscount)
                      _fareLine('Fare', fareAfterDiscount, isBold: true),
                    // Tip (if applicable)
                    if (widget.tipAmount > 0) ...[
                      _fareLine('Tip', widget.tipAmount.toDouble()),
                    ],
                    Divider(
                      color: AppColors.outlineVariant.withValues(alpha: 0.2),
                      height: 1,
                    ),
                    const SizedBox(height: 12),
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          '₱${widget.totalFare.toStringAsFixed(2)}',
                          style: GoogleFonts.lexend(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Payment Method
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAYMENT METHOD',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.outline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.paymentMethod,
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        FutureBuilder<double>(
                          future: WalletService.instance.isLoaded
                              ? Future.value(WalletService.instance.balance)
                              : WalletService.instance.load().then(
                                  (_) => WalletService.instance.balance),
                          builder: (context, snapshot) {
                            final balance = snapshot.data ?? 0;
                            return Text(
                              '₱${balance.toStringAsFixed(2)}',
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: balance >= widget.totalFare
                                    ? AppColors.primary
                                    : AppColors.error,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _confirmPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Confirm & Pay ₱${widget.totalFare.toStringAsFixed(2)}',
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.surface,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: AppColors.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.outline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fareLine(String label, double amount,
      {bool isDiscount = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? AppColors.primary : AppColors.onSurface,
            ),
          ),
          Text(
            isDiscount
                ? '-₱${amount.abs().toStringAsFixed(2)}'
                : '₱${amount.toStringAsFixed(2)}',
            style: GoogleFonts.lexend(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isDiscount ? AppColors.primary : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
