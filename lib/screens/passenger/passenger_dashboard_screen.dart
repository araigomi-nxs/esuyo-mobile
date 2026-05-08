import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/route_model.dart';
import '../../services/supabase_service.dart';
import '../../services/favorites_service.dart';
import '../../services/wallet_service.dart';
import '../../widgets/esuyo_logo.dart';

class PassengerDashboardScreen extends StatefulWidget {
  const PassengerDashboardScreen({super.key});

  @override
  State<PassengerDashboardScreen> createState() =>
      _PassengerDashboardScreenState();
}

class _PassengerDashboardScreenState extends State<PassengerDashboardScreen> {
  List<RouteModel> _allRoutes = [];

  @override
  void initState() {
    super.initState();
    FavoritesService.instance.addListener(_onFavoritesChanged);
    WalletService.instance.addListener(_onWalletChanged);
    WalletService.instance.load();
    _loadRoutes();
  }

  @override
  void dispose() {
    FavoritesService.instance.removeListener(_onFavoritesChanged);
    WalletService.instance.removeListener(_onWalletChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  void _onWalletChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRoutes() async {
    try {
      final routes = await SupabaseService.fetchRoutes();
      if (mounted) setState(() => _allRoutes = routes);
    } catch (_) {}
  }

  List<RouteModel> get _favoriteRoutes {
    final ids = FavoritesService.instance.favoriteIds;
    return _allRoutes.where((r) => ids.contains(r.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _favoriteRoutes;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppColors.surface.withValues(alpha: 0.85),
            elevation: 0,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: EsuyoLogo(width: 32, height: 32, padding: 2),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pasahero Dashboard',
                      style: GoogleFonts.lexend(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'Daily commute made easy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => context.go('/passenger/notifications'),
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primaryContainer,
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildBalanceCard(context),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: '4',
                        label: 'TRIPS TODAY',
                        valueColor: AppColors.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        value: '1.2kg',
                        label: 'CO2 SAVED',
                        valueColor: AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Favorite Routes',
                      style: GoogleFonts.lexend(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/passenger/routes'),
                      child: Text(
                        'View All',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFavoriteRoutesList(context, favorites),
                const SizedBox(height: 24),
                Text(
                  'Recent Activity',
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                const _ActivityItem(
                  icon: Icons.map_rounded,
                  title: 'Ayala Malls',
                  time: '14:20 • Dec 12',
                  amount: '₱28.00',
                  isPositive: false,
                ),
                const SizedBox(height: 8),
                const _ActivityItem(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Top Up Wallet',
                  time: '09:15 • Dec 12',
                  amount: '+₱500.00',
                  isPositive: true,
                ),
                const SizedBox(height: 8),
                const _ActivityItem(
                  icon: Icons.route_rounded,
                  title: 'SM Legazpi',
                  time: '18:45 • Dec 11',
                  amount: '₱15.00',
                  isPositive: false,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteRoutesList(
    BuildContext context,
    List<RouteModel> favorites,
  ) {
    if (favorites.isEmpty) {
      return GestureDetector(
        onTap: () => context.go('/passenger/routes'),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 28,
                color: AppColors.outline.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No favorites yet',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.outline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a route and press ♥ to save it here',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: favorites.length,
        itemBuilder: (context, i) {
          final route = favorites[i];
          return _FavRouteCard(
            route: route,
            onTap: () => context.push('/passenger/route_detail', extra: route),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B60E6).withValues(alpha: 0.15),
            offset: const Offset(0, 12),
            blurRadius: 32,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AVAILABLE BALANCE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₱',
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    WalletService.instance.balance.toStringAsFixed(2),
                    style: GoogleFonts.lexend(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _CardBtn(
                      icon: Icons.add_circle_outline,
                      label: 'Top Up',
                      onTap: () => context.go('/passenger/wallet'),
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CardBtn(
                      icon: Icons.qr_code_scanner,
                      label: 'Board',
                      onTap: () => context.go('/passenger/scan'),
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FavRouteCard extends StatelessWidget {
  final RouteModel route;
  final VoidCallback onTap;

  const _FavRouteCard({required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color color;
    try {
      final h = route.color.replaceAll('#', '');
      color = Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      color = AppColors.primaryContainer;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset('assets/jeep.png', width: 22, height: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    route.vehicleLabel.split(' ').first,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              route.name,
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${route.stops.length} stops',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  const _CardBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : AppColors.tertiaryContainer,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary ? AppColors.primaryContainer : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isPrimary ? AppColors.primaryContainer : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.lexend(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.outline,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final String amount;
  final bool isPositive;
  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.amount,
    required this.isPositive,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryContainer, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isPositive
                  ? AppColors.tertiary
                  : AppColors.primaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
