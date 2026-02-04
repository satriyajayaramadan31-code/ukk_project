import 'package:flutter/material.dart';
import '../../widget/app_bar.dart';
import '../../widget/side_menu.dart';
import '../../widget/add_user.dart';
import '../../widget/edit_user.dart';
import '../../widget/delete_user.dart';
import 'package:engine_rent_app/service/supabase_service.dart';
import 'package:engine_rent_app/models/user.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  List<User> _users = [];
  List<User> _filteredUsers = [];

  final TextEditingController _searchController = TextEditingController();

  // expand/collapse per user
  final Set<int> _expandedUserIds = {};

  String _capitalize(String text) {
    if (text.trim().isEmpty) return text;
    final t = text.trim();
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

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
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredUsers = query.isEmpty
          ? _users
          : _users.where((u) => u.username.toLowerCase().contains(query)).toList();
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

  void _toggleExpand(int userId) {
    setState(() {
      if (_expandedUserIds.contains(userId)) {
        _expandedUserIds.remove(userId);
      } else {
        _expandedUserIds.add(userId);
      }
    });
  }

  Color _roleColor(ThemeData theme, String role) {
    final r = role.toLowerCase().trim();
    if (r.contains('admin')) return theme.colorScheme.primary;
    if (r.contains('petugas')) return Colors.orange;
    if (r.contains('peminjam')) return Colors.green;
    return theme.colorScheme.secondary;
  }

  Widget _infoRow({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.hintColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(User user, ThemeData theme) {
    final isExpanded = _expandedUserIds.contains(user.id);
    final roleText = _capitalize(user.role);
    final roleColor = _roleColor(theme, user.role);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _toggleExpand(user.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // avatar bulat
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: roleColor.withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                roleText,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: roleColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    AnimatedRotation(
                      duration: const Duration(milliseconds: 220),
                      turns: isExpanded ? 0.5 : 0.0,
                      child: Icon(Icons.expand_more, color: theme.hintColor),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // INFO (tanpa kotak putih)
                _infoRow(
                  theme: theme,
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: roleText,
                ),
                const SizedBox(height: 8),
                _infoRow(
                  theme: theme,
                  icon: Icons.lock_outline,
                  label: 'Password',
                  value: user.password,
                ),

                // EXPAND BUTTON AREA
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      children: [
                        Divider(color: theme.dividerColor.withOpacity(0.7), height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit'),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.delete),
                                label: const Text('Hapus'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  crossFadeState:
                      isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: const AppBarWithMenu(title: 'Manajemen User'),
      drawer: const SideMenu(),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // SEARCH + ADD (SEBARIS)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _filterUsers(),
                  decoration: InputDecoration(
                    labelText: 'Search user',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Tambah User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            ],
          ),

          const SizedBox(height: 14),

          // LIST CARD USER
          if (_filteredUsers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Center(
                child: Text(
                  'User tidak ditemukan.',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            )
          else
            ..._filteredUsers.map((user) => _buildUserCard(user, theme)).toList(),
        ],
      ),
    );
  }
}
