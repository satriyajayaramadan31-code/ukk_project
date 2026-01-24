import 'package:flutter/material.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import '../widget/add_user.dart';
import '../widget/edit_user.dart';
import '../widget/delete_user.dart';

class User {
  final String id;
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
  final List<User> _users = [
    User(id: '1', username: 'admin', role: 'admin', password: 'admin123'),
    User(id: '2', username: 'petugas', role: 'petugas', password: 'petugas123'),
    User(id: '3', username: 'peminjam', role: 'peminjam', password: 'user123'),
  ];

  final TextEditingController _searchController = TextEditingController();
  List<User> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = _users;
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

  void _addUser(String username, String role, String password) {
    setState(() {
      _users.add(
        User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          username: username,
          role: role,
          password: password,
        ),
      );
      _filterUsers();
    });
  }

  void _editUser(User user, String username, String role, String password) {
    setState(() {
      user.username = username;
      user.role = role;
      user.password = password;
      _filterUsers();
    });
  }

  void _deleteUser(User user) {
    setState(() {
      _users.remove(user);
      _filterUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Manajemen User'),
      drawer: const SideMenu(role: 'admin'),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
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
                                    // EDIT
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        size: 18,
                                      ),
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

                                    // DELETE
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
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
