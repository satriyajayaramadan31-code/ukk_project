import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _logs = [];
  String _searchTerm = "";
  bool _ascending = false; // false = terbaru dulu
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _subscribeLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await SupabaseService.getLogs();
    setState(() {
      _logs = logs;
    });
  }

  void _subscribeLogs() {
    _channel = Supabase.instance.client.channel('realtime-log_aktivitas');

    _channel!.onPostgresChanges(
      schema: 'public',
      table: 'log_aktivitas',
      event: PostgresChangeEvent.insert,
      callback: (payload) {
        debugPrint('🔔 Log baru masuk: ${payload.newRecord}');
        _loadLogs();
      },
    );

    _channel!.subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // filter
    var filteredLogs = _logs.where((log) {
      final query = _searchTerm.toLowerCase();
      final username = (log['username'] ?? '').toString().toLowerCase();
      final description = (log['aksi'] ?? '').toString().toLowerCase();
      return username.contains(query) || description.contains(query);
    }).toList();

    // sort by created_at
    filteredLogs.sort((a, b) {
      final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
      return _ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Log Aktivitas'),
      drawer: const SideMenu(),
      backgroundColor: theme.colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // SEARCH
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchTerm = value;
              });
            },
            decoration: InputDecoration(
              labelText: "Cari username atau deskripsi",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // TABLE CARD (header + table dalam 1 card)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: theme.colorScheme.surface,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER dalam card
                  Row(
                    children: [
                      Text(
                        'History',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const Spacer(),

                      Tooltip(
                        message: _ascending
                            ? 'Urut: Tertua → Terbaru'
                            : 'Urut: Terbaru → Tertua',
                        child: Material(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _ascending = !_ascending),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.sort, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    _ascending ? "Tertua" : "Terbaru",
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const SizedBox(height: 10),

                  // TABLE
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        theme.scaffoldBackgroundColor,
                      ),
                      columns: const [
                        DataColumn(label: Text('Username')),
                        DataColumn(label: Text('Deskripsi')),
                        DataColumn(label: Text('Tanggal')),
                      ],
                      rows: filteredLogs.map((log) {
                        // format tanggal
                        String formattedDate = '';
                        final rawDate = log['created_at'];
                        if (rawDate != null) {
                          final dt = DateTime.tryParse(rawDate);
                          if (dt != null) {
                            formattedDate =
                                DateFormat('dd/MM/yyyy HH:mm').format(dt);
                          }
                        }

                        return DataRow(
                          cells: [
                            DataCell(Text(log['username'] ?? '')),
                            DataCell(
                              SizedBox(
                                width: 450,
                                child: Text(
                                  log['aksi'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text(formattedDate)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
