import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppColors.surface.withOpacity(0.85),
            elevation: 0,
            leading: IconButton(
              onPressed: () => context.go('/passenger'),
              icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
            ),
            title: Text('Notifications', style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
            actions: [
              TextButton(
                onPressed: () {},
                child: Text('Mark all as read', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, color: AppColors.primaryContainer)),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Critical advisory
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.warning_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('CRITICAL ADVISORY', style: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.onErrorContainer.withOpacity(0.7), letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text('Due to National Emergency, some routes may not be available',
                          style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.onErrorContainer)),
                      const SizedBox(height: 6),
                      Text("Please check the 'Route' tab for updated schedules and alternative transport options.",
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.onErrorContainer.withOpacity(0.9), height: 1.5)),
                    ])),
                  ]),
                ),
                const SizedBox(height: 28),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Recent Activity', style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                  Text('TODAY', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.outline, letterSpacing: 1.5)),
                ]),
                const SizedBox(height: 16),
                _NotifItem(
                  icon: Icons.account_balance_wallet_rounded,
                  iconBg: AppColors.tertiaryContainer.withOpacity(0.12),
                  iconColor: AppColors.tertiaryContainer,
                  title: 'PHP 500.00 added successfully',
                  time: '2m ago',
                  hasUnread: true,
                ),
                const SizedBox(height: 12),
                _NotifItem(
                  icon: Icons.map_rounded,
                  iconBg: AppColors.primaryContainer.withOpacity(0.1),
                  iconColor: AppColors.primaryContainer,
                  title: 'Loop 1 expansion update',
                  time: '1h ago',
                  hasUnread: false,
                ),
                const SizedBox(height: 12),
                _NotifItem(
                  icon: Icons.history_rounded,
                  iconBg: AppColors.onSecondaryContainer.withOpacity(0.1),
                  iconColor: AppColors.onSecondaryContainer,
                  title: 'Real-time tracking is back online',
                  time: '5h ago',
                  hasUnread: false,
                ),
                const SizedBox(height: 28),
                Text('Traffic Insights', style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _TrafficCard(
                    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCaq7NZvekWLuQhiiaoNHUdjU_IDvt_JVJHPZB1Q8ByZBtWU5pF-HuB-1mTC5_x3eXwKQqPdlNnAZu1fwkSY3KQt3iUC3SxRg3OqtKhSV3sVQc-6abuQwpyLjbVCqWAxO3-4mBg8Kx9r2yTiQq4EHqsG6b9lgRk2SDnNeAi61lFt4r6iEKa2Oi02L__i0YtLboVxDU3lNWDucmAiDQfIfSpP-ru8glBlORNQFvxqXc12SKXMlAg7KQj9xiFVtJpM76zdnBeQQk40P4',
                    badge: 'HEAVY', badgeColor: AppColors.error,
                    title: 'Heavy Congestion: EDSA',
                    subtitle: 'Commuter delay approx. 45 mins near Cubao station.',
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _TrafficCard(
                    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBwgeJ4VYh5E24UNINAKgazTSk4TtlUq_15kz1Flf2x8XGjbiHl8ITTpviZ0ghhSngzf-2tQx-J_JzTc_qHpfhQ-lGEb302S8h-q4pUKjxLTfu3On6ucrh1yTe7Lx9Nfzyd8vkpwffJ61Xawtxr6Tn_cRVw5imuyU8gc502onj1ibQBbsGYIWDvxufd_pY8Eao3_-zXA-fNjBqBt286viTGZUqE8_TCDrLCth10iGEoPth2Gz5dE96uQY9sNJnNzsmciCM7jrLXS1k',
                    badge: 'PEAK HOURS', badgeColor: AppColors.primary,
                    title: 'Peak Hour Warning',
                    subtitle: 'Expected high volume at major hubs between 4PM - 7PM.',
                  )),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String time;
  final bool hasUnread;
  const _NotifItem({required this.icon, required this.iconBg, required this.iconColor, required this.title, required this.time, required this.hasUnread});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.schedule_outlined, size: 13, color: AppColors.outline),
            const SizedBox(width: 4),
            Text(time, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.outline, fontWeight: FontWeight.w500)),
          ]),
        ])),
        if (hasUnread)
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer,
              boxShadow: [BoxShadow(color: AppColors.primaryContainer.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)],
            ),
          ),
      ]),
    );
  }
}

class _TrafficCard extends StatelessWidget {
  final String imageUrl;
  final String badge;
  final Color badgeColor;
  final String title;
  final String subtitle;
  const _TrafficCard({required this.imageUrl, required this.badge, required this.badgeColor, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 240,
        child: Stack(children: [
          Positioned.fill(child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: AppColors.surfaceContainerHighest))),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.85)])))),
          Positioned(bottom: 0, left: 0, right: 0, child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: badgeColor,
                child: Text(badge, style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(height: 6),
              Text(title, style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white70, height: 1.4)),
            ]),
          )),
        ]),
      ),
    );
  }
}
