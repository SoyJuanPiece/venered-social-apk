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
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);

    try {
      final results = await supabase
          .from('profiles')
          .select('id,username,display_name,avatar_url')
          .or('username.ilike.%$q%,display_name.ilike.%$q%')
          .limit(10);
      setState(() {
        _loading = false;
        _results = List<Map<String, dynamic>>.from(results as List);
      });
    } catch (e) {
      debugPrint('Error buscando usuario: $e'); // AHORA VEREMOS EL ERROR REAL
      setState(() {
        _loading = false;
        _results = [];
      });
    }
  }

  void _selectUser(Map<String, dynamic> user) {
    Navigator.pop(context, user);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              width: double.maxFinite,
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = _results[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: item['avatar_url'] != null
                            ? NetworkImage(item['avatar_url'])
                            : null,
                        child: item['avatar_url'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(item['username'] ?? ''),
                      subtitle: (item['display_name'] != null && item['display_name'].toString().isNotEmpty)
                          ? Text(item['display_name'])
                          : null,
                      onTap: () => _selectUser(item),
                    );
                },
              ),
            ),
          if (!_loading && _controller.text.trim().isNotEmpty && _results.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Sin resultados'),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ],
    );
  }
}
