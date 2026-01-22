import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'package:engine_rent_app/service/navigation_service.dart';

class SideMenu extends StatelessWidget {
  final String role;

  const SideMenu({flutter r
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppTheme.primary,
              child: Row(
                children: [
                  Icon(Icons.inventory_2, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Aplikasi Peminjaman Alat",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _menuItem(
                    context,
                    icon: Icons.dashboard,
                    title: "Dashboard",
                    keyValue: "dashboard",
                  ),
                  if (role == "admin")
                  _menuItem(
                    context,
                    icon: Icons.inventory_2,
                    title: "Alat",
                    keyValue: "daftaralat",
                  ),
                  if (role == "peminjam")
                  _menuItem(
                    context,
                    icon: Icons.inventory_2,
                    title: "Alat",
                    keyValue: "alat",
                  ),
                  if (role == "admin")
                  _menuItem(
                    context,
                    icon: Icons.people,
                    title: "User",
                    keyValue: "user",
                  ),
                  if (role == "admin" || role == "petugas")
                    _menuItem(
                      context,
                      icon: Icons.assignment,
                      title: "Peminjaman",
                      keyValue: "peminjaman",
                    ),
                  if (role == "admin")
                    _menuItem(
                      context,
                      icon: Icons.settings,
                      title: "Kategori",
                      keyValue: "kategori",
                    ),
                  if (role == "admin")
                    _menuItem(context, 
                    icon: Icons.history, 
                    title: "Log Aktifitas", 
                    keyValue: "log"),

                  const Divider(),

                  _menuItem(
                    context,
                    icon: Icons.logout,
                    title: "Logout",
                    keyValue: "logout",
                    isDanger: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String keyValue,
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDanger ? AppTheme.statusLate : AppTheme.primary,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDanger ? AppTheme.statusLate : AppTheme.textPrimary,
            ),
      ),
      onTap: () {
        Navigator.of(context).pop(); // tutup drawer

        if (keyValue == 'dashboard') {
          NavigationService.navigateAndRemoveUntil(
            '/dashboard',
            arguments: role, // KIRIM ROLE
          );
        } else if (keyValue == 'kategori') {
          NavigationService.navigateAndRemoveUntil(
            '/kategori',
            arguments: role, // opsional kalau perlu
          );
        } else if (keyValue == 'daftaralat') {
          NavigationService.navigateTo('/daftaralat');
        } else if (keyValue == 'logout') {
          NavigationService.navigateAndRemoveUntil('/login');
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: AppTheme.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
}
