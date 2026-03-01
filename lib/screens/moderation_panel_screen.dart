import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils.dart';

class ModerationPanelScreen extends StatefulWidget {
  const ModerationPanelScreen({super.key});

  @override
  State<ModerationPanelScreen> createState() => _ModerationPanelScreenState();
}

class _ModerationPanelScreenState extends State<ModerationPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await Supabase.instance.client
          .from('profiles')
          .select()
          .ilike('username', '%$query%')
          .limit(10);
      setState(() => _searchResults = List<Map<String, dynamic>>.from(results));
    } catch (e) {
      dPrint('Error searching: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Verif.', icon: Icon(Icons.verified_user)),
            Tab(text: 'Reportes', icon: Icon(Icons.report)),
            Tab(text: 'Usuarios', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVerificationList(),
          _buildReportsList(),
          _buildUsersList(),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar usuario por nombre...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: _searchUsers,
          ),
        ),
        if (_isSearching) const LinearProgressIndicator(),
        Expanded(
          child: _searchResults.isEmpty
              ? const Center(child: Text('Escribe para buscar usuarios'))
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['profile_pic_url'] != null ? NetworkImage(user['profile_pic_url']) : null,
                        child: user['profile_pic_url'] == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(user['username'] ?? 'Sin nombre'),
                      subtitle: Text('Rol actual: ${user['role'] ?? 'user'}'),
                      trailing: const Icon(Icons.edit_note),
                      onTap: () => _showRoleDialog(user),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showRoleDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cambiar rol de ${user['username']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Usuario Normal'),
              onTap: () => _updateUserRole(user['id'], 'user'),
            ),
            ListTile(
              title: const Text('Moderador'),
              onTap: () => _updateUserRole(user['id'], 'moderator'),
            ),
            ListTile(
              title: const Text('Administrador'),
              onTap: () => _updateUserRole(user['id'], 'admin'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await Supabase.instance.client.from('profiles').update({'role': newRole}).eq('id', userId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rol actualizado a $newRole')));
        _searchUsers(_searchController.text);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildVerificationList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('verification_requests')
          .stream(primaryKey: ['id'])
          .eq('status', 'pending'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!;
        if (requests.isEmpty) return const Center(child: Text('No hay solicitudes pendientes.'));

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text('Categoría: ${req['category']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(req['message'] ?? 'Sin mensaje'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _approveRequest(req['id']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _rejectRequest(req['id']),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReportsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client.from('moderation_dashboard').select().eq('status', 'pending'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final reports = snapshot.data!;
        if (reports.isEmpty) return const Center(child: Text('No hay reportes nuevos.'));

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final rep = reports[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text('Motivo: ${rep['reason']}', style: const TextStyle(color: Colors.redAccent)),
                subtitle: Text('Reportado: ${rep['reported_username']}\nContenido: ${rep['post_content'] ?? 'N/A'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.block, color: Colors.red),
                  onPressed: () => _banUser(rep['reported_user_id']),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _approveRequest(String id) async {
    try {
      await Supabase.instance.client.rpc('approve_verification', params: {'request_id': id});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario verificado.')));
    } catch (e) {
      dPrint('Error approving: $e');
    }
  }

  Future<void> _rejectRequest(String id) async {
    await Supabase.instance.client.from('verification_requests').update({'status': 'rejected'}).eq('id', id);
  }

  Future<void> _banUser(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Banear usuario?'),
        content: const Text('Esto impedirá que el usuario publique contenido.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Banear', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await Supabase.instance.client.from('profiles').update({'is_banned': true}).eq('id', userId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario baneado.')));
    }
  }
}
