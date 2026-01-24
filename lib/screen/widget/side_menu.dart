import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'package:engine_rent_app/service/navigation_service.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

class SideMenu extends StatefulWidget {
  final String role;

  const SideMenu({
    super.key,
    required this.role,
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  String username = "User";

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  void _loadUsername() async {
    final name = await SupabaseService.getUsername();
    if (mounted && name != null) {
      setState(() {
        username = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppTheme.primary,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      username,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ),

                  // Close icon di pojok kanan
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ================= MENU =================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _menuItem(
                    context,
                    icon: Icons.home,
                    title: "Dashboard",
                    keyValue: "dashboard",
                  ),

                  if (widget.role == "admin")
                    _menuItem(
                      context,
                      icon: Icons.people,
                      title: "User",
                      keyValue: "user",
                    ),

                  if (widget.role == "admin")
                    _menuItem(
                      context,
                      icon: Icons.dashboard,
                      title: "Kategori",
                      keyValue: "kategori",
                    ),

                  if (widget.role == "admin")
                    _menuItem(
                      context,
                      icon: Icons.inventory_2,
                      title: "Daftar Alat",
                      keyValue: "daftaralat",
                    ),

                  if (widget.role == "peminjam")
                    _menuItem(
                      context,
                      icon: Icons.inventory_2,
                      title: "Alat",
                      keyValue: "alat",
                    ),

                  if (widget.role == "peminjam")
                    _menuItem(
                      context,
                      icon: Icons.assignment,
                      title: "Peminjaman",
                      keyValue: "pinjam",
                    ),

                  if (widget.role == "admin")
                    _menuItem(
                      context,
                      icon: Icons.assignment,
                      title: "Peminjaman",
                      keyValue: "daftarpeminjaman",
                    ),

                  if (widget.role == "petugas")
                    _menuItem(
                      context,
                      icon: Icons.assignment,
                      title: "Peminjaman",
                      keyValue: "penerimaan",
                    ),

                  if (widget.role == "admin")
                    _menuItem(
                      context,
                      icon: Icons.history,
                      title: "Log Aktivitas",
                      keyValue: "logs",
                    ),

                  if (widget.role == "petugas")
                    _menuItem(
                      context,
                      icon: Icons.print,
                      title: "Laporan",
                      keyValue: "laporan",
                    ),

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

  // ================= MENU ITEM =================
  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String keyValue,
    bool isDanger = false,
  }) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      color: AppTheme.background,
      child: ListTile(
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

          switch (keyValue) {
            case 'dashboard':
              NavigationService.navigateAndRemoveUntil(
                '/dashboard',
                arguments: widget.role,
              );
              break;

            case 'daftaralat':
              NavigationService.navigateTo('/daftaralat');
              break;

            case 'kategori':
              NavigationService.navigateTo('/kategori');
              break;

            case 'daftarpeminjaman':
              NavigationService.navigateTo('/daftarpeminjaman');
              break;

            case 'penerimaan':
              NavigationService.navigateTo('/penerimaan');
              break;

            case 'user':
              NavigationService.navigateTo('/user');
              break;

            case 'logs':
              NavigationService.navigateTo('/logs');
              break;

            case 'laporan':
              NavigationService.navigateTo('/laporan');

            case 'alat':
              NavigationService.navigateTo('/alat');

            case 'pinjam':
              NavigationService.navigateTo('/pinjam');

            case 'logout':
              NavigationService.navigateAndRemoveUntil('/login');
              break;
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
