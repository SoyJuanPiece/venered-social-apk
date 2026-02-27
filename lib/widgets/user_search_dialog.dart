import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:venered_social/screens/profile_screen.dart';

class UserSearchDialog extends StatefulWidget {
  const UserSearchDialog({super.key});

  @override
  State<UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<UserSearchDialog> {
  final _controller = TextEditingController();
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);

    try {
      final results = await supabase
          .from('profiles')
          .select('id,username,profile_pic_url')
          .ilike('username', '%$query%')
          .limit(10);
      setState(() {
        _loading = false;
        _results = List<Map<String, dynamic>>.from(results as List);
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _results = [];
      });
    }
  }

  void _navigateToProfile(String userId) {
    // First pop the dialog, then push the profile screen.
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ProfileScreen(userId: userId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buscar usuario'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nombre de usuario'),
            onChanged: _performSearch,
          ),
          const SizedBox(height: 8),
          if (_loading) const LinearProgressIndicator(),
          if (_results.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = _results[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: item['profile_pic_url'] != null
                              ? NetworkImage(item['profile_pic_url'])
                              : null,
                          child: item['profile_pic_url'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(item['username'] ?? ''),
                        onTap: () => _navigateToProfile(item['id']),
                      ),
                    );
                },
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ],
    );
  }
}
