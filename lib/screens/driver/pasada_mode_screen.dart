import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../theme/app_colors.dart';
import '../../models/route_model.dart';
import '../../utils/fare_matrix.dart';

class PasadaModeScreen extends StatefulWidget {
  final RouteModel? route;
  const PasadaModeScreen({super.key, this.route});

  @override
  State<PasadaModeScreen> createState() => _PasadaModeScreenState();
}

class _PassengerEntry {
  final DateTime time;
  final double fare;
  final bool isDiscount;
  _PassengerEntry({required this.time, required this.fare, this.isDiscount = false});
}

class _PasadaModeScreenState extends State<PasadaModeScreen> {
  int _passengerCount = 0;
  double _totalRevenue = 0;
  late DateTime _tripStart;
  Timer? _clockTimer;
  String _elapsed = '00:00';
  int _currentStopIndex = 0;
  final List<_PassengerEntry> _passengers = [];
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _tripStart = DateTime.now();
    _startClock();
    _subscribeToScans();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final dur = DateTime.now().difference(_tripStart);
      final h = dur.inHours;
      final m = dur.inMinutes % 60;
      final s = dur.inSeconds % 60;
      setState(() {
        _elapsed = h > 0
            ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
            : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      });
    });
  }

  void _subscribeToScans() {
    try {
      _realtimeChannel = Supabase.instance.client
          .channel('driver_pasada_scans')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'transactions',
            callback: (payload) {
              final data = payload.newRecord;
              final amount = (data['amount'] as num?)?.toDouble() ?? 0;
              final isDiscount = (data['has_discount'] as bool?) ?? false;
              if (mounted) {
                setState(() {
                  _passengerCount++;
                  _totalRevenue += amount;
                  _passengers.insert(
                    0,
                    _PassengerEntry(
                      time: DateTime.now(),
                      fare: amount,
                      isDiscount: isDiscount,
                    ),
                  );
                });
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  void _addManualPassenger(double fare, bool isDiscount) {
    setState(() {
      _passengerCount++;
      _totalRevenue += fare;
      _passengers.insert(
        0,
        _PassengerEntry(time: DateTime.now(), fare: fare, isDiscount: isDiscount),
      );
    });
  }

  Future<void> _endPasada() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Tapusin ang Pasada?',
              style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SummaryRow(label: 'Pasahero', value: '$_passengerCount'),
                _SummaryRow(
                  label: 'Kabuuang Kita',
                  value: '₱${_totalRevenue.toStringAsFixed(2)}',
                ),
                _SummaryRow(label: 'Tagal', value: _elapsed),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Huwag',
                  style: GoogleFonts.lexend(color: AppColors.outline),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Tapusin',
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      // Optionally record the trip to Supabase
      try {
        await Supabase.instance.client.from('trips').insert({
          'route_id': widget.route?.id,
          'passenger_count': _passengerCount,
          'revenue': _totalRevenue,
          'started_at': _tripStart.toIso8601String(),
          'ended_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
      if (mounted) context.go('/driver');
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  double get _baseFare =>
      FareMatrix.calculate(0, widget.route?.vehicleType);

  double get _discountFare => _baseFare * 0.8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsBar(),
            _buildStopProgress(),
            Expanded(child: _buildPassengerLog()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2B6000), Color(0xFF427800)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PASADA MODE — AKTIBO',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white60,
                    letterSpacing: 1.6,
                  ),
                ),
                Text(
                  widget.route?.name ?? 'Aktibong Biyahe',
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  _elapsed,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TripStat(
            label: 'Pasahero',
            value: '$_passengerCount',
            icon: Icons.people_rounded,
            color: AppColors.primaryContainer,
          ),
          Container(width: 1, height: 36, color: AppColors.outlineVariant),
          _TripStat(
            label: 'Kinikita',
            value: '₱${_totalRevenue.toStringAsFixed(2)}',
            icon: Icons.payments_rounded,
            color: AppColors.tertiaryContainer,
          ),
          Container(width: 1, height: 36, color: AppColors.outlineVariant),
          _TripStat(
            label: 'Base Fare',
            value: '₱${_baseFare.toStringAsFixed(2)}',
            icon: Icons.monetization_on_rounded,
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStopProgress() {
    final stops = widget.route?.stops ?? [];
    if (stops.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 72,
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: stops.length,
        itemBuilder: (ctx, i) {
          final isActive = i == _currentStopIndex;
          final isPast = i < _currentStopIndex;
          return GestureDetector(
            onTap: () => setState(() => _currentStopIndex = i),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isActive ? 30 : 24,
                      height: isActive ? 30 : 24,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.tertiaryContainer
                            : isPast
                                ? AppColors.outline.withValues(alpha: 0.35)
                                : AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                        border: isActive
                            ? Border.all(
                                color: AppColors.tertiaryFixed,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: isActive ? 12 : 10,
                            fontWeight: FontWeight.bold,
                            color: isActive || isPast
                                ? Colors.white
                                : AppColors.outline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 56,
                      child: Text(
                        stops[i].name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          color: isActive
                              ? AppColors.tertiaryContainer
                              : AppColors.outline,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                if (i < stops.length - 1)
                  Container(
                    width: 16,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 14),
                    color: isPast
                        ? AppColors.outline.withValues(alpha: 0.3)
                        : AppColors.outlineVariant,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPassengerLog() {
    if (_passengers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 52,
              color: AppColors.outline.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 14),
            Text(
              'Hintay ng mga pasahero...',
              style: GoogleFonts.lexend(
                fontSize: 15,
                color: AppColors.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'I-tap ang "Dagdag" para manu-manong idagdag.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.outline.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _passengers.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final p = _passengers[i];
        final num = _passengers.length - i;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: p.isDiscount
                      ? AppColors.secondaryContainer.withValues(alpha: 0.3)
                      : AppColors.primaryContainer.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  p.isDiscount
                      ? Icons.discount_rounded
                      : Icons.person_rounded,
                  size: 18,
                  color: p.isDiscount
                      ? AppColors.secondary
                      : AppColors.primaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pasahero #$num',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (p.isDiscount)
                      Text(
                        'May diskwento',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.secondary,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '₱${p.fare.toStringAsFixed(2)}',
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.tertiaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${p.time.hour.toString().padLeft(2, '0')}:${p.time.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showAddPassengerSheet(isDiscount: false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dagdag',
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _showAddPassengerSheet(isDiscount: true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.discount_rounded,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Diskwento',
                      style: GoogleFonts.lexend(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _endPasada,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.stop_circle_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tapusin',
                    style: GoogleFonts.lexend(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPassengerSheet({required bool isDiscount}) {
    final fullFare = _baseFare;
    final fare = isDiscount ? _discountFare : fullFare;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isDiscount ? 'Pasahero na may Diskwento' : 'Idagdag ang Pasahero',
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isDiscount
                      ? 'PWD, Senior Citizen, o ibang may diskwento (20% off)'
                      : 'Regular na pamasahe base sa ruta',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDiscount
                        ? AppColors.secondaryContainer.withValues(alpha: 0.2)
                        : AppColors.tertiaryContainer.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDiscount
                          ? AppColors.secondary.withValues(alpha: 0.3)
                          : AppColors.tertiaryContainer.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDiscount ? 'Diskwentong Fare' : 'Regular Fare',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.outline,
                            ),
                          ),
                          if (isDiscount)
                            Text(
                              '₱${fullFare.toStringAsFixed(2)} → -20%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.outline,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '₱${fare.toStringAsFixed(2)}',
                        style: GoogleFonts.lexend(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDiscount
                              ? AppColors.secondary
                              : AppColors.tertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDiscount
                          ? AppColors.secondary
                          : AppColors.tertiaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _addManualPassenger(fare, isDiscount);
                    },
                    child: Text(
                      'Kumpirmahin — ₱${fare.toStringAsFixed(2)}',
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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

class _TripStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _TripStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppColors.outline,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(color: AppColors.outline),
          ),
          Text(
            value,
            style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
