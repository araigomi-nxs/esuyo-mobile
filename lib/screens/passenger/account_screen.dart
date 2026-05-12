import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _biometricEnabled = true;
  bool _darkModeEnabled = false;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await SupabaseService.fetchProfile();
    if (mounted) setState(() => _profile = p);
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (mounted) context.go('/');
  }

  String get _displayName => (_profile?['full_name'] as String?)?.trim().isNotEmpty == true
      ? _profile!['full_name'] as String
      : 'User';

  String get _displayEmail => (_profile?['email'] as String?) ?? '';
  String get _displayPhone => (_profile?['phone'] as String?) ?? '';

  String get _memberSince {
    final raw = _profile?['created_at'] as String?;
    if (raw == null) return '';
    return 'MEMBER SINCE ${DateTime.parse(raw).year}';
  }

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
              icon: const Icon(Icons.arrow_back, color: AppColors.primaryContainer),
            ),
            title: Text('Account', style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: AppColors.primaryContainer)),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Profile hero
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(32)),
                  child: Column(children: [
                    Stack(children: [
                      Container(
                        width: 112, height: 112,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondaryContainer]),
                        ),
                        child: ClipOval(child: Image.network(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuDPmCB_m6Zp0_4mu1lfJ9uskh412cJnSKZazPTJQXQ2HqX9rM_cCGqw1FUYuYX7_f1nq7lnzpzzT-cHQa9i-ps2giD08vGZk3KrH2ad2jdRTsRRBVPpcbopYPhz1PPiZHrmQjj3bzG9ULePaF1SlI2zMorEdXsJOVR-zEBbC1HRuDy7ZPwA4PIUa_l8ZuePpF8ogDrGY4Cu-Rm95cBvmlhZqzTtvJoksQMQGgUMBTxMIvN78Z0ql7Sm8vRq9DF4qbUTJcAYknhQQr8',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(color: AppColors.surfaceContainerHighest, child: const Icon(Icons.person, size: 48, color: AppColors.outline)),
                        )),
                      ),
                      Positioned(
                        top: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF60A5FA)]),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text('PRO', style: GoogleFonts.lexend(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Text(_displayName, style: GoogleFonts.lexend(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.onSurface, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    if (_memberSince.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(99)),
                      child: Text(_memberSince, style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onPrimaryContainer, letterSpacing: 1)),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // Personal Information
                _SectionHeader('Personal Information'),
                _InfoSection(children: [
                  _InfoRow(icon: Icons.person_outline, label: 'Full Name', value: _displayName),
                  _InfoRow(icon: Icons.mail_outline, label: 'Email', value: _displayEmail),
                  if (_displayPhone.isNotEmpty)
                    _InfoRow(icon: Icons.call_outlined, label: 'Phone', value: _displayPhone),
                ]),
                const SizedBox(height: 24),

                // Subscription
                _SectionHeader('Subscription & Billing'),
                _InfoSection(children: [
                  _InfoRow(icon: Icons.workspace_premium_outlined, label: 'Current Plan', value: 'Avenue Pro Monthly',
                      trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.tertiaryFixed, borderRadius: BorderRadius.circular(99)),
                          child: Text('ACTIVE', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.onTertiaryFixedVariant)))),
                  _InfoRow(icon: Icons.event_note_outlined, label: 'Next Billing Date', value: 'Jan 15, 2024'),
                  _InfoRow(icon: Icons.credit_card_outlined, label: 'Payment Method', value: 'GCash - 0917***4567'),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () => context.go('/passenger/subscription'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.primaryContainer.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.settings_applications_outlined, color: AppColors.primaryContainer, size: 18),
                          const SizedBox(width: 8),
                          Text('Manage Subscription', style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryContainer)),
                        ]),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                // Security
                _SectionHeader('Security'),
                _InfoSection(children: [
                  _InfoRow(icon: Icons.lock_outline, label: '', value: 'Change Password'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFEFF4FF)),
                        child: const Icon(Icons.fingerprint_outlined, color: AppColors.primaryContainer, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text('Biometric Login', style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onSurface))),
                      Switch(
                        value: _biometricEnabled,
                        onChanged: (v) => setState(() => _biometricEnabled = v),
                        activeThumbColor: AppColors.primaryContainer,
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 24),

                // App Settings
                _SectionHeader('App Settings'),
                _InfoSection(children: [
                  _InfoRow(icon: Icons.notifications_outlined, label: '', value: 'Notifications'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFEFF4FF)),
                        child: const Icon(Icons.dark_mode_outlined, color: AppColors.primaryContainer, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text('Dark Mode', style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onSurface))),
                      Switch(
                        value: _darkModeEnabled,
                        onChanged: (v) => setState(() => _darkModeEnabled = v),
                        activeThumbColor: AppColors.primaryContainer,
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 24),

                // Support
                _SectionHeader('Support'),
                _InfoSection(children: [
                  _InfoRow(icon: Icons.help_center_outlined, label: '', value: 'Help Center'),
                  _InfoRow(icon: Icons.report_outlined, label: '', value: 'Report an Issue'),
                ]),
                const SizedBox(height: 28),

                // Logout
                GestureDetector(
                  onTap: _signOut,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: AppColors.error.withOpacity(0.1), offset: const Offset(0, 8), blurRadius: 24)],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.logout_rounded, color: AppColors.onErrorContainer, size: 22),
                      const SizedBox(width: 10),
                      Text('Logout', style: GoogleFonts.lexend(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.onErrorContainer)),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Avenue Pro v2.4.1', textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.outline, letterSpacing: 1.5)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(text.toUpperCase(), style: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.onSurface.withOpacity(0.5), letterSpacing: 2)),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final List<Widget> children;
  const _InfoSection({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.all(8),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  const _InfoRow({required this.icon, required this.label, required this.value, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFEFF4FF)),
          child: Icon(icon, color: AppColors.primaryContainer, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (label.isNotEmpty) Text(label.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.outline, letterSpacing: 1)),
          Text(value, style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onSurface)),
        ])),
        trailing ?? const Icon(Icons.chevron_right, color: AppColors.outlineVariant),
      ]),
    );
  }
}
