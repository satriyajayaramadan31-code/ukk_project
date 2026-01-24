import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widget/activity_item.dart';
import '../widget/stat_card.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';

class DashboardPage extends StatelessWidget {
  final String role;

  const DashboardPage({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const stats = {
      'totalEquipment': 45,
      'activeLoans': 12,
      'pendingApprovals': 5,
      'overdueReturns': 3,
    };

    final List<Widget> statCards = [
      StatCard(
        title: 'Alat',
        value: stats['totalEquipment'].toString(),
        icon: Icons.inventory_2,
      ),
      StatCard(
        title: 'Dipinjam',
        value: stats['activeLoans'].toString(),
        icon: Icons.assignment,
      ),
      StatCard(
        title: 'Menunggu',
        value: stats['pendingApprovals'].toString(),
        icon: Icons.trending_up,
        iconColor: AppTheme.statusPending,
      ),
      StatCard(
        title: 'Terlambat',
        value: stats['overdueReturns'].toString(),
        icon: Icons.warning_amber,
        iconColor: AppTheme.statusLate,
      ),
    ];

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Dashboard'),
      drawer: SideMenu(role: role),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: statCards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
              ),
              itemBuilder: (context, index) => statCards[index],
            ),

            const SizedBox(height: 24),

            Card(
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktivitas Terkini',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),

                    // Activity list
                    const ActivityItem(
                      item: 'Kamera DSLR Canon',
                      status: 'Menunggu',
                      time: '2 jam lalu',
                    ),
                    const ActivityItem(
                      item: 'Laptop Dell XPS',
                      status: 'Dikembalikan',
                      time: '3 jam lalu',
                    ),
                    const ActivityItem(
                      item: 'Proyektor Epson',
                      status: 'Dipinjam',
                      time: '5 jam lalu',
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
