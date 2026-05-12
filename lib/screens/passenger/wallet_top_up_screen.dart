import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../services/wallet_service.dart';
import 'payment_success_screen.dart';

class WalletTopUpScreen extends StatefulWidget {
  const WalletTopUpScreen({super.key});
  @override
  State<WalletTopUpScreen> createState() => _WalletTopUpScreenState();
}

class _WalletTopUpScreenState extends State<WalletTopUpScreen> {
  int _selectedAmount = 500;
  int _selectedMethod = 0;
  final _controller = TextEditingController();

  final _amounts = [100, 200, 500, 1000];
  final _methods = [
    {'name': 'GCash', 'sub': 'Instant processing', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF3B82F6)},
    {'name': 'Maya', 'sub': 'Fast and reliable', 'icon': Icons.payments_rounded, 'color': const Color(0xFF10B981)},
    {'name': 'Bank Transfer', 'sub': 'InstaPay / PESONet', 'icon': Icons.account_balance_rounded, 'color': const Color(0xFF1E293B)},
  ];

  @override
  void initState() {
    super.initState();
    WalletService.instance.load();
    WalletService.instance.addListener(_onWalletChanged);
  }

  @override
  void dispose() {
    WalletService.instance.removeListener(_onWalletChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onWalletChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmTopUp() async {
    final topUpAmount =
        double.tryParse(_controller.text) ?? _selectedAmount.toDouble();
    final selectedPaymentMethod = _methods[_selectedMethod]['name'] as String;

    if (topUpAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount greater than zero.')),
      );
      return;
    }

    final newBalance = await WalletService.instance.topUp(topUpAmount);
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentSuccessScreen(
          amount: topUpAmount,
          paymentMethod: selectedPaymentMethod,
          newBalance: newBalance,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: GestureDetector(
            onTap: _confirmTopUp,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.35),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Confirm Top Up',
                    style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppColors.surface.withValues(alpha: 0.85),
            elevation: 0,
            leading: IconButton(
              onPressed: () => context.go('/passenger'),
              icon: const Icon(Icons.arrow_back,
                  color: AppColors.primaryContainer),
            ),
            title: Text(
              'Wallet Top Up',
              style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Balance card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2B60E6).withValues(alpha: 0.2),
                        offset: const Offset(0, 12),
                        blurRadius: 40,
                      )
                    ],
                  ),
                  child: Stack(children: [
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AVAILABLE BALANCE',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                letterSpacing: 2,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('₱',
                                style: GoogleFonts.lexend(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(width: 4),
                            Text(
                                WalletService.instance.balance
                                    .toStringAsFixed(2),
                                style: GoogleFonts.lexend(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1.5)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(children: [
                          const Icon(Icons.verified_user_outlined,
                              color: Colors.white70, size: 13),
                          const SizedBox(width: 6),
                          Text('Securely stored in your E-SUYO Wallet',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.9))),
                        ]),
                      ],
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // Amount section header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Top Up Amount',
                        style: GoogleFonts.lexend(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99)),
                      child: Text('Manual Entry',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryContainer,
                              letterSpacing: 1.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Custom input
                Container(
                  decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text('₱',
                          style: GoogleFonts.lexend(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.outline)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.lexend(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: GoogleFonts.lexend(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: AppColors.outline.withValues(alpha: 0.3)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),

                // Quick amounts — 4 across, compact
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  childAspectRatio: 2.0,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: _amounts.map((amount) {
                    final isSelected = _selectedAmount == amount;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedAmount = amount;
                        _controller.text = amount.toString();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryContainer
                              : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryContainer
                                        .withValues(alpha: 0.25),
                                    offset: const Offset(0, 4),
                                    blurRadius: 12,
                                  )
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            '₱$amount',
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Payment methods
                Text('Select Payment Method',
                    style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface)),
                const SizedBox(height: 12),
                ...List.generate(_methods.length, (i) {
                  final m = _methods[i];
                  final isSelected = _selectedMethod == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMethod = i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.surfaceContainerLowest
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.primaryContainer
                                    .withValues(alpha: 0.4))
                            : null,
                      ),
                      child: Row(children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                              color: m['color'] as Color,
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(m['icon'] as IconData,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m['name'] as String,
                                  style: GoogleFonts.lexend(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onSurface)),
                              Text(m['sub'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11, color: AppColors.outline)),
                            ],
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryContainer
                                      : AppColors.outlineVariant,
                                  width: 2)),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 9,
                                    height: 9,
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primaryContainer),
                                  ),
                                )
                              : null,
                        ),
                      ]),
                    ),
                  );
                }),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
