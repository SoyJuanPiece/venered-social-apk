import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ModerationPanelScreen extends StatefulWidget {
  const ModerationPanelScreen({super.key});

  @override
  State<ModerationPanelScreen> createState() => _ModerationPanelScreenState();
}

class _ModerationPanelScreenState extends State<ModerationPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Moderación'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Verificaciones', icon: Icon(Icons.verified_user)),
            Tab(text: 'Reportes', icon: Icon(Icons.report)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVerificationList(),
          _buildReportsList(),
        ],
      ),
    );
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
                subtitle: Text('Reportado: ${rep['reported_username']}
Contenido: ${rep['post_content'] ?? 'N/A'}'),
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
