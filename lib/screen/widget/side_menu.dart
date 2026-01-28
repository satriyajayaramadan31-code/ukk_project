import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'package:engine_rent_app/service/navigation_service.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  String username = "User";
  String role = "peminjam"; // default sementara

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Load username & role dari Supabase
  void _loadUserData() async {
    final name = await SupabaseService.getUsername();
    final r = await SupabaseService.getRole();

    if (mounted) {
      setState(() {
        username = name ?? "User";
        role = r ?? "peminjam";
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
                  _menuItem(context, icon: Icons.home, title: "Dashboard", keyValue: "dashboard"),

                  if (role == "admin")
                    _menuItem(context, icon: Icons.people, title: "User", keyValue: "user"),

                  if (role == "admin")
                    _menuItem(context, icon: Icons.dashboard, title: "Kategori", keyValue: "kategori"),

                  if (role == "admin")
                    _menuItem(context, icon: Icons.inventory_2, title: "Daftar Alat", keyValue: "daftaralat"),

                  if (role == "peminjam")
                    _menuItem(context, icon: Icons.inventory_2, title: "Alat", keyValue: "alat"),

                  if (role == "peminjam")
                    _menuItem(context, icon: Icons.assignment, title: "Peminjaman", keyValue: "pinjam"),

                  if (role == "admin")
                    _menuItem(context, icon: Icons.assignment, title: "Peminjaman", keyValue: "daftarpeminjaman"),

                  if (role == "petugas")
                    _menuItem(context, icon: Icons.assignment, title: "Peminjaman", keyValue: "penerimaan"),

                  if (role == "admin")
                    _menuItem(context, icon: Icons.history, title: "Log Aktivitas", keyValue: "logs"),

                  if (role == "petugas")
                    _menuItem(context, icon: Icons.print, title: "Laporan", keyValue: "laporan"),

                  const Divider(),

                  _menuItem(context, icon: Icons.logout, title: "Logout", keyValue: "logout", isDanger: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= MENU ITEM BUILDER =================
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
        onTap: () async {
          Navigator.of(context).pop(); // tutup drawer

          switch (keyValue) {
            case 'dashboard':
              final r = await SupabaseService.getRole() ?? role;
              NavigationService.navigateAndRemoveUntil('/dashboard', arguments: r);
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
              break;

            case 'alat':
              NavigationService.navigateTo('/alat');
              break;

            case 'pinjam':
              NavigationService.navigateTo('/pinjam');
              break;

            case 'logout':
              await SupabaseService.logout();
              NavigationService.navigateAndRemoveUntil('/login');
              break;
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
