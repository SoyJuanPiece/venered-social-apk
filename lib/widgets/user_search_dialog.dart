import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A dialog that allows searching for users by username and returns the selected
/// profile map when the user taps a result.
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
    setState(() {
      _loading = true;
    });

    final response = await supabase
        .from('profiles')
        .select('id,username,avatar_url')
        .ilike('username', '%$query%')
        .limit(10)
        .execute();

    setState(() {
      _loading = false;
      if (response.error == null) {
        _results = List<Map<String, dynamic>>.from(response.data as List);
      } else {
        _results = [];
      }
    });
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
                          backgroundImage: item['avatar_url'] != null
                              ? NetworkImage(item['avatar_url']) as ImageProvider
                              : null,
                          child: item['avatar_url'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(item['username'] ?? ''),
                        onTap: () => Navigator.pop(context, item),
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
