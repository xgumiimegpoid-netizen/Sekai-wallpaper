import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/wallpaper.dart';
import '../services/wallpaper_service.dart';
import '../screens/community_screen.dart';

class AppDrawer extends StatelessWidget {
  final Map<String, List<Wallpaper>> wallpapers;
  final void Function(int index) onCategoryTap;

  const AppDrawer({
    super.key,
    required this.wallpapers,
    required this.onCategoryTap,
  });

  int get _totalCount =>
      wallpapers.values.fold<int>(0, (sum, list) => sum + list.length);

  Future<void> _openDonateLink() async {
    final uri = Uri.parse('https://ko-fi.com/yaemori02');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/banner.gif',
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Wallpapers',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (wallpapers.isNotEmpty)
                          Text(
                            '$_totalCount wallpapers disponibles',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                ...CategoryData.categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final cat = entry.value;
                  final count = wallpapers[cat.name]?.length ?? 0;
                  return ListTile(
                    leading: Icon(cat.icon),
                    title: Text(cat.name),
                    trailing: count > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                        : null,
                    onTap: () => onCategoryTap(index),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.groups),
            title: const Text('Comunidad'),
            subtitle: const Text('Comparte tus wallpapers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CommunityScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.local_cafe),
            title: const Text('Invitarme un café'),
            subtitle: const Text('¿Te gusta la app? Apoya el desarrollo'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: _openDonateLink,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}