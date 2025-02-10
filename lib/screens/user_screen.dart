import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrasiPage extends StatefulWidget {
  const RegistrasiPage({Key? key}) : super(key: key);

  @override
  _RegistrasiPageState createState() => _RegistrasiPageState();
}

class _RegistrasiPageState extends State<RegistrasiPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> userList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await supabase.from('user').select('id, username, password').order('id');
      setState(() {
        userList = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showMessage('Gagal memuat data pengguna.', false);
    }
  }

  Future<void> addUser(String username, String password) async {
    if (password.isEmpty) {
      _showMessage('Password harus diisi.', false);
      return;
    }
    try {
      final existingUser = await supabase
          .from('user')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (existingUser != null) {
        _showMessage('Username sudah digunakan.', false);
        return;
      }

      await supabase.from('user').insert({'username': username, 'password': password});
      fetchUsers();
      _showMessage('User berhasil ditambahkan', true);
    } catch (e) {
      _showMessage('Gagal menambahkan user.', false);
    }
  }

  Future<void> editUser(int id, String username, String password) async {
    try {
      final data = {'username': username, 'password': password};
      await supabase.from('user').update(data).eq('id', id);
      fetchUsers();
      _showMessage('User berhasil diperbarui', true);
    } catch (e) {
      _showMessage('Gagal mengedit user.', false);
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await supabase.from('user').delete().eq('id', id);
      fetchUsers();
      _showMessage('User berhasil dihapus', true);
    } catch (e) {
      _showMessage('Gagal menghapus user.', false);
    }
  }

  void _showMessage(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: success ? Colors.green : Colors.red),
    );
  }

  void _showFormDialog({int? id, String? username, String? password}) {
    final _formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController(text: username ?? '');
    final passwordController = TextEditingController(text: password ?? '');

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(id == null ? 'Tambah User' : 'Edit User'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) => value!.isEmpty ? 'Username tidak boleh kosong' : null,
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) => id == null && value!.isEmpty ? 'Password harus diisi' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (id == null) {
                    addUser(usernameController.text, passwordController.text);
                  } else {
                    editUser(id, usernameController.text, passwordController.text);
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data User')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userList.isEmpty
              ? const Center(child: Text('Tidak ada data user.'))
              : ListView.builder(
                  itemCount: userList.length,
                  itemBuilder: (context, index) {
                    final user = userList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(user['username'] ?? 'Unknown'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showFormDialog(
                                id: user['id'],
                                username: user['username'],
                                password: user['password'],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteUser(user['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
