import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBody: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppColors.surface.withOpacity(0.85),
            elevation: 0,
            leading: IconButton(
              onPressed: () => context.go('/passenger/account'),
              icon: const Icon(Icons.arrow_back, color: AppColors.primaryContainer),
            ),
            title: Text('Pasahero Plans', style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Hero
                Text('UPGRADE EXPERIENCE', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryContainer, letterSpacing: 2)),
                const SizedBox(height: 10),
                Text('Select the perfect\nplan for your journey.', style: GoogleFonts.lexend(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.onSurface, letterSpacing: -1, height: 1.15)),
                const SizedBox(height: 12),
                Text('Unlock full analytics and seamless exports to take control of your daily transit ecosystem.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.5)),
                const SizedBox(height: 32),

                // Free Plan Card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(32)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Basic Commuter', style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                        Text('Essential daily tracking', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.onSurfaceVariant)),
                      ]),
                      const Icon(Icons.directions_bus_rounded, size: 36, color: AppColors.outline),
                    ]),
                    const SizedBox(height: 20),
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                      Text('Free', style: GoogleFonts.lexend(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
                      const SizedBox(width: 8),
                      Text('/ lifetime', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.onSurfaceVariant)),
                    ]),
                    const SizedBox(height: 20),
                    _PlanFeature('Basic tracking', color: AppColors.primaryContainer),
                    _PlanFeature('Recent trip history', color: AppColors.primaryContainer),
                    _PlanFeature('QR scanning', color: AppColors.primaryContainer),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outlineVariant, width: 2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Center(child: Text('Current Plan', style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface))),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // Pro Plan Card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: AppColors.primaryContainer.withOpacity(0.25), offset: const Offset(0, 16), blurRadius: 40)],
                  ),
                  child: Stack(children: [
                    Positioned(top: -60, right: -60, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)))),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(99)),
                            child: Text('Recommended', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                          ),
                          const SizedBox(height: 8),
                          Text('Pasahero Pro', style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('Everything you need and more', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70)),
                        ]),
                        const Icon(Icons.workspace_premium_rounded, size: 36, color: Colors.white),
                      ]),
                      const SizedBox(height: 20),
                      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                        Text('₱', style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(width: 2),
                        Text('199', style: GoogleFonts.lexend(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -2)),
                        const SizedBox(width: 8),
                        Text('one-time', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white70)),
                      ]),
                      const SizedBox(height: 20),
                      _PlanFeature('Full Transaction Management', color: AppColors.tertiaryFixed, textColor: Colors.white),
                      _PlanFeature('Priority Support', color: AppColors.tertiaryFixed, textColor: Colors.white),
                      _PlanFeature('Advanced Route Analytics', color: AppColors.tertiaryFixed, textColor: Colors.white),
                      _PlanFeature('CO2 Footprint Deep Dive', color: AppColors.tertiaryFixed, textColor: Colors.white),
                      _PlanFeature('Export CSV/PDF Reports', color: AppColors.tertiaryFixed, textColor: Colors.white),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(0, 6), blurRadius: 20)]),
                          child: Center(child: Text('Upgrade Now', style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryContainer))),
                        ),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(height: 32),

                // Why Premium section
                Row(children: [
                  Text('Why go Premium?', style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  const SizedBox(width: 12),
                  Expanded(child: Container(height: 2, color: AppColors.surfaceContainerHighest)),
                ]),
                const SizedBox(height: 20),
                _BenefitCard(icon: Icons.data_thresholding_outlined, iconBg: AppColors.primaryContainer.withOpacity(0.1), iconColor: AppColors.primaryContainer,
                    title: 'Deep Analytics', body: 'Visualize your travel patterns and optimize your daily routes with high-precision data visualization.'),
                const SizedBox(height: 12),
                _BenefitCard(icon: Icons.eco_outlined, iconBg: AppColors.tertiary.withOpacity(0.1), iconColor: AppColors.tertiary,
                    title: 'Sustainability', body: 'Understand your environmental impact. Tracking your CO2 helps you move toward a greener future.'),
                const SizedBox(height: 12),
                _BenefitCard(icon: Icons.description_outlined, iconBg: AppColors.secondary.withOpacity(0.1), iconColor: AppColors.secondary,
                    title: 'Finance Ready', body: 'Generate expense reports instantly. Perfect for corporate reimbursements or personal budgeting.'),
                const SizedBox(height: 28),

                // Testimonial
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(40)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.format_quote_rounded, color: AppColors.primaryContainer, size: 48),
                    const SizedBox(height: 12),
                    Text('"Since upgrading to E-SUYO Premium, I\'ve managed to cut my commute expenses by 15% just by analyzing my weekly route data."',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontStyle: FontStyle.italic, color: AppColors.onSurface, height: 1.6)),
                    const SizedBox(height: 20),
                    Row(children: [
                      ClipOval(child: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCaUZ3f3esPQLBNAisYn5ua1R0Umj7Iuy4QwiqnFP5Qy4J7bcXcR66KMJzIPdb-5Hu_Xdm2FHxtAehUqtnciMHOjUgs-cnPcY0ZsJbfGwyjLewxUJJiTdR2DHrSisPeJZ81exlSxaAcWsJvR3Y9WESTeKrGSGRBuutu3ncKS37Z6ZT_04pdKRFhIBRtisAgmSzFgjxKIQXYH0ApUQfuTuWCJMfu0G2FZW2ae2RSHEmbBV7RfxzLCYBXIhY0jzhG_JuJgeyd1Cbbuoc',
                        width: 44, height: 44, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(width: 44, height: 44, color: AppColors.surfaceContainerHighest, child: const Icon(Icons.person)),
                      )),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Juan Dela Cruz', style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                        Text('Daily Commuter', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      ]),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanFeature extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const _PlanFeature(this.text, {required this.color, this.textColor = AppColors.onSurfaceVariant});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(Icons.check_circle_rounded, color: color, size: 20),
        const SizedBox(width: 10),
        Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: textColor)),
      ]),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String body;
  const _BenefitCard({required this.icon, required this.iconBg, required this.iconColor, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(24)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
          const SizedBox(height: 4),
          Text(body, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.5)),
        ])),
      ]),
    );
  }
}
