import 'package:flutter/material.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import '../widget/add_user.dart';
import '../widget/edit_user.dart';
import '../widget/delete_user.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

class User {
  final int id;
  String username;
  String role;
  String password;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.password,
  });
}

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  List<User> _users = [];
  List<User> _filteredUsers = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final res = await SupabaseService.getUsers();
    setState(() {
      _users = res
          .map((e) => User(
                id: e['id'],
                username: e['username'],
                role: e['role'],
                password: e['password'],
              ))
          .toList();
      _filteredUsers = _users;
    });
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = query.isEmpty
          ? _users
          : _users
              .where((u) => u.username.toLowerCase().contains(query))
              .toList();
    });
  }

  Future<void> _addUser(String username, String role, String password) async {
    final success = await SupabaseService.addUser(
      username: username,
      password: password,
      role: role,
    );

    if (success) _fetchUsers();
  }

  Future<void> _editUser(User user, String username, String role, String password) async {
    final success = await SupabaseService.editUser(
      id: user.id,
      username: username,
      password: password,
      role: role,
    );

    if (success) _fetchUsers();
  }

  Future<void> _deleteUser(User user) async {
    final success = await SupabaseService.deleteUser(id: user.id);
    if (success) _fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: const AppBarWithMenu(title: 'Manajemen User'),
      drawer: const SideMenu(),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          // Search
          TextField(
            controller: _searchController,
            onChanged: (_) => _filterUsers(),
            decoration: InputDecoration(
              labelText: 'Search user',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.cardColor),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Add Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Tambah User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.all(10),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AddUserDialog(
                    onSubmit: _addUser,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Users Table
          Card(
            color: theme.scaffoldBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daftar User',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 32,
                      headingRowColor: MaterialStateProperty.all(theme.scaffoldBackgroundColor),
                      columns: const [
                        DataColumn(label: Text('Username')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Password')),
                        DataColumn(label: Center(child: Text('Aksi'))),
                      ],
                      rows: _filteredUsers.map((user) {
                        return DataRow(
                          cells: [
                            DataCell(Text(user.username)),
                            DataCell(Text(user.role)),
                            DataCell(Text(user.password)),
                            DataCell(
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Edit
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => EditUserDialog(
                                            user: user,
                                            onSubmit: (username, role, password) =>
                                                _editUser(user, username, role, password),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    // Delete
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => DeleteUserDialog(
                                            username: user.username,
                                            onDelete: () => _deleteUser(user),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
