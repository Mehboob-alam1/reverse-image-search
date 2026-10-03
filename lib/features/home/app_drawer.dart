import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../services/url_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _open(BuildContext context, VoidCallback action) async {
    Navigator.pop(context);
    action();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const textColor = AppColors.brandIconOnHero;
    const iconColor = AppColors.brandIconOnHero;

    return Drawer(
      width: MediaQuery.sizeOf(context).width,
      backgroundColor: AppColors.primaryDark,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppColors.heroGradient,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
            children: [
              const Center(child: _DrawerLogo()),
              const SizedBox(height: 18),
              Text(
                l10n.appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 36),
              _DrawerItem(
                icon: Icons.share,
                label: l10n.shareApp,
                color: textColor,
                iconColor: iconColor,
                onTap: () => _open(context, () {
                  Share.share(
                    l10n.shareAppMessage(
                      'https://play.google.com/store/apps/details?id=${AppConstants.packageName}',
                    ),
                  );
                }),
              ),
              _DrawerItem(
                icon: Icons.translate,
                label: l10n.selectLanguageTitle,
                color: textColor,
                iconColor: iconColor,
                onTap: () => _open(context, () => context.push('/language-settings')),
              ),
              _DrawerItem(
                icon: Icons.verified_user,
                label: l10n.privacyPolicy,
                color: textColor,
                iconColor: iconColor,
                onTap: () => _open(context, () => context.push('/privacy')),
              ),
              _DrawerItem(
                icon: Icons.login,
                label: l10n.moreApps,
                color: textColor,
                iconColor: iconColor,
                ad: true,
                onTap: () => _open(context, () {
                  const UrlService().openStore(
                    'https://play.google.com/store/apps/developer?id=Deep+Image+Search',
                  );
                }),
              ),
              _DrawerItem(
                icon: Icons.star,
                label: l10n.rateUs,
                color: textColor,
                iconColor: iconColor,
                onTap: () => _open(context, () {
                  const UrlService().openStore(
                    'https://play.google.com/store/apps/details?id=${AppConstants.packageName}',
                  );
                }),
              ),
              _DrawerItem(
                icon: Icons.warning_amber_rounded,
                label: l10n.communityGuidelines,
                color: textColor,
                iconColor: iconColor,
                onTap: () => _open(context, () => context.push('/community')),
              ),
              _DrawerItem(
                icon: Icons.chat_bubble,
                label: l10n.feedback,
                color: textColor,
                iconColor: iconColor,
                showDivider: false,
                onTap: () => _open(context, () {
                  const UrlService().openStore(
                    'mailto:${AppConstants.supportEmail}?subject=Deep%20Image%20Search%20feedback',
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.iconColor,
    this.ad = false,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;
  final bool ad;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: iconColor, size: 26),
          title: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: ad
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppLocalizations.of(context).adBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,
          onTap: onTap,
        ),
        if (showDivider)
          Divider(color: Colors.white.withValues(alpha: 0.22), height: 1),
      ],
    );
  }
}

class _DrawerLogo extends StatelessWidget {
  const _DrawerLogo();

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.brandIconOnHero;
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const CustomPaint(
            size: Size(88, 88),
            painter: _ViewfinderPainter(accent: accent),
          ),
          const Icon(Icons.image, color: accent, size: 36),
          const Positioned(
            right: 22,
            top: 22,
            child: Icon(Icons.search, color: accent, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    void corner(Offset start, Offset mid, Offset end, Color color) {
      stroke.color = color;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(mid.dx, mid.dy)
        ..lineTo(end.dx, end.dy);
      canvas.drawPath(path, stroke);
    }

    final w = size.width;
    final h = size.height;
    const arm = 22.0;
    corner(const Offset(0, arm), Offset.zero, Offset(arm, 0), const Color(0xFF3DDC84));
    corner(Offset(w - arm, 0), Offset(w, 0), Offset(w, arm), accent);
    corner(Offset(w, h - arm), Offset(w, h), Offset(w - arm, h), accent);
    corner(Offset(arm, h), Offset(0, h), Offset(0, h - arm), AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) => oldDelegate.accent != accent;
}
