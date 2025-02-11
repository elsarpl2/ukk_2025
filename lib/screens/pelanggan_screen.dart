import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PelangganPage extends StatefulWidget {
  const PelangganPage({Key? key}) : super(key: key);

  @override
  _PelangganPageState createState() => _PelangganPageState();
}

class _PelangganPageState extends State<PelangganPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> userList = [];
  List<Map<String, dynamic>> filteredList = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchPelanggan();
  }

  Future<void> fetchPelanggan() async {
    try {
      final response = await supabase.from('pelanggan').select().order('pelanggan_id');
      if (response is List) {
        setState(() {
          userList = List<Map<String, dynamic>>.from(response);
          filteredList = userList; // Initialize filteredList with all users
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('Gagal memuat data pelanggan.');
    }
  }

  void _filterPelanggan(String query) {
    setState(() {
      searchQuery = query;
      filteredList = userList.where((pelanggan) {
        return (pelanggan['nama_pelanggan'] as String).toLowerCase().contains(query.toLowerCase()) ||
               (pelanggan['alamat'] as String).toLowerCase().contains(query.toLowerCase()) ||
               (pelanggan['no_telp'] as String).toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> addPelanggan(String nama_pelanggan, String alamat, String no_telp) async {
    try {
      final existingUser    = await supabase
          .from('pelanggan')
          .select('nama_pelanggan')
          .eq('nama_pelanggan', nama_pelanggan)
          .maybeSingle();

      if (existingUser    != null) {
        _showError('Nama pelanggan sudah digunakan. Gunakan nama lain.');
        return;
      }

      await supabase.from('pelanggan').insert({
        'nama_pelanggan': nama_pelanggan,
        'alamat': alamat,
        'no_telp': no_telp
      }).select();

      fetchPelanggan();
      _showSuccess('Pelanggan berhasil ditambahkan');
    } catch (e) {
      _showError('Gagal menambahkan pelanggan.');
    }
  }

  Future<void> editPelanggan(int pelanggan_id, String nama_pelanggan, String alamat, String no_telp) async {
    try {
      await supabase.from('pelanggan').update({
        'nama_pelanggan': nama_pelanggan,
        'alamat': alamat,
        'no_telp': no_telp,
      }).eq('pelanggan_id', pelanggan_id);

      fetchPelanggan();
      _showSuccess('Pelanggan berhasil diperbarui');
    } catch (e) {
      _showError('Gagal mengedit pelanggan.');
    }
  }

  Future<void> deletePelanggan(int id) async {
    try {
      await supabase.from('pelanggan').delete().eq('pelanggan_id', id).select();
      fetchPelanggan();
      _showSuccess('Pelanggan berhasil dihapus');
    } catch (e) {
      _showError('Gagal menghapus pelanggan.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showFormDialog({int? pelanggan_id, String? nama_pelanggan, String? alamat, String? no_telp}) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController nama_pelangganController = TextEditingController(text: nama_pelanggan ?? '');
    final TextEditingController alamatController = TextEditingController(text: alamat ?? '');
    final TextEditingController no_telpController = TextEditingController(text: no_telp ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(pelanggan_id == null ? 'Tambah Pelanggan' : 'Edit Pelanggan'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nama_pelangganController,
                decoration: const InputDecoration(labelText: 'Nama pelanggan'),
                validator: (value) => value!.isEmpty ? 'Nama pelanggan tidak boleh kosong' : null,
                style: TextStyle(fontSize: 16), // Mengubah ukuran font
              ),
              TextFormField(
                controller: alamatController,
                decoration: const InputDecoration(labelText: 'Alamat'),
                validator: (value) => value!.isEmpty ? 'Alamat tidak boleh kosong' : null,
                style: TextStyle(fontSize: 16), // Mengubah ukuran font
              ),
              TextFormField(
                controller: no_telpController,
                decoration: const InputDecoration(labelText: 'No. Telp'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'No. Telp tidak boleh kosong';
                  }
                  if (int.tryParse(value) == null) {
                    return 'No. Telp harus berupa angka';
                  }
                  if (value.length > 13) {
                    return 'No. Telp maksimal 13 angka';
                  }
                  return null;
                },
                style: TextStyle(fontSize: 16), // Mengubah ukuran font
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (pelanggan_id == null) {
                  addPelanggan(nama_pelangganController.text, alamatController.text, no_telpController.text);
                } else {
                  editPelanggan(pelanggan_id, nama_pelangganController.text, alamatController.text, no_telpController.text);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Pelanggan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterPelanggan,
              decoration: InputDecoration(
                labelText: 'Cari berdasarkan nama, alamat, no_telp',
                border: OutlineInputBorder(),
              ),
              style: TextStyle(fontSize: 16), // Mengubah ukuran font
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? const Center(child: Text('Tidak ada data pelanggan.'))
                    : ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final pelanggan = filteredList[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: ListTile(
                              title: Text(
                                pelanggan['nama_pelanggan'] ?? 'Unknown',
                                style: TextStyle(fontSize: 18), // Mengubah ukuran font
                              ),
                              subtitle: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: "Alamat: ${pelanggan['alamat'] ?? '-'}\n"),
                                    TextSpan(text: "No. Telp: ${pelanggan['no_telp'] ?? '-'}"),
                                  ],
                                ),
                                style: TextStyle(fontSize: 16), // Mengubah ukuran font
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      _showFormDialog(
                                        pelanggan_id: pelanggan['pelanggan_id'],
                                        nama_pelanggan: pelanggan['nama_pelanggan'],
                                        alamat: pelanggan['alamat'],
                                        no_telp: pelanggan['no_telp'],
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      deletePelanggan(pelanggan['pelanggan_id']);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}