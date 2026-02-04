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
  String role = "peminjam";

  @override
  void initState() {
    super.initState();

    /// FIX: langsung load dari cache dulu biar ga delay
    _initFromCache();

    /// refresh background (opsional) untuk update jika ada perubahan
    _refreshFromSupabase();
  }

  void _initFromCache() async {
    final cachedName = await SupabaseService.getUsername();
    final cachedRole = await SupabaseService.getRole();

    if (!mounted) return;
    setState(() {
      username = cachedName ?? "User";
      role = cachedRole ?? "peminjam";
    });
  }

  /// refresh data tanpa bikin delay di UI
  void _refreshFromSupabase() async {
    final name = await SupabaseService.getUsername(forceRefresh: true);
    final r = await SupabaseService.getRole(forceRefresh: true);

    if (!mounted) return;
    setState(() {
      username = name ?? username;
      role = r ?? role;
    });
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
                  _menuItem(context,
                      icon: Icons.home,
                      title: "Dashboard",
                      keyValue: "dashboard"),

                  if (role == "admin")
                    _menuItem(context,
                        icon: Icons.people, title: "User", keyValue: "user"),

                  if (role == "admin")
                    _menuItem(context,
                        icon: Icons.dashboard,
                        title: "Kategori",
                        keyValue: "kategori"),

                  if (role == "admin")
                    _menuItem(context,
                        icon: Icons.inventory_2,
                        title: "Daftar Alat",
                        keyValue: "daftaralat"),

                  if (role == "peminjam")
                    _menuItem(context,
                        icon: Icons.inventory_2, title: "Alat", keyValue: "alat"),

                  if (role == "peminjam")
                    _menuItem(context,
                        icon: Icons.assignment,
                        title: "Peminjaman",
                        keyValue: "pinjam"),

                  if (role == "admin")
                    _menuItem(context,
                        icon: Icons.assignment,
                        title: "Peminjaman",
                        keyValue: "daftarpeminjaman"),

                  if (role == "petugas")
                    _menuItem(context,
                        icon: Icons.assignment,
                        title: "Peminjaman",
                        keyValue: "penerimaan"),

                  if (role == "admin")
                    _menuItem(context,
                        icon: Icons.history,
                        title: "Log Aktivitas",
                        keyValue: "logs"),

                  // if (role == "peminjam")
                  //   _menuItem(context,
                  //       icon: Icons.calendar_month_outlined,
                  //       title: "Pemanjangan",
                  //       keyValue: "panjang"),

                  // if (role == "petugas")
                  //   _menuItem(context,
                  //       icon: Icons.calendar_month_outlined,
                  //       title: "Pemanjangan",
                  //       keyValue: "hari"),

                  if (role == "petugas")
                    _menuItem(context,
                        icon: Icons.print,
                        title: "Laporan",
                        keyValue: "laporan"),

                  const Divider(),

                  _menuItem(context,
                      icon: Icons.logout,
                      title: "Logout",
                      keyValue: "logout",
                      isDanger: true),
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
          Navigator.of(context).pop();

          switch (keyValue) {
            case 'dashboard':
              NavigationService.navigateAndRemoveUntil(
                '/dashboard',
                arguments: role,
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
              break;

            case 'alat':
              NavigationService.navigateTo('/alat');
              break;

            case 'pinjam':
              NavigationService.navigateTo('/pinjam');
              break;

            // case 'panjang':
            //   NavigationService.navigateTo('/panjang');
            //   break;

            // case 'hari':
            //   NavigationService.navigateTo('/hari');
            //   break;

            case 'logout':
              await SupabaseService.logout(); // sudah clear cache
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
