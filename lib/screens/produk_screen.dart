import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProdukPage extends StatefulWidget {
  const ProdukPage({Key? key}) : super(key: key);

  @override
  _ProdukPageState createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> userList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProduk();
  }

  Future<void> fetchProduk() async {
    try {
      final response = await supabase.from('produk').select().order('produk_id');
      if (response is List) {
        setState(() {
          userList = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('Gagal memuat data pengguna.');
    }
  }

  Future<void> addProduk(String nama_produk, String harga, String stok) async {
    try {
      await supabase.from('produk').insert({
        'nama_produk': nama_produk,
        'harga': harga,
        'stok': stok,
      }).select();
      fetchProduk();
      _showSuccess('User berhasil ditambahkan');
    } catch (e) {
      _showError('Gagal menambahkan user.');
    }
  }

  Future<void> editProduk(int produk_id, String nama_produk, String harga, String stok) async {
    try {
      await supabase.from('peroduk').update({
        'nama_produk': nama_produk,
        'harga': harga,
        'stok': stok,
      }).eq('produk_id', produk_id).select();
      fetchProduk();
      _showSuccess('User berhasil diperbarui');
    } catch (e) {
      _showError('Gagal mengedit user.');
    }
  }

  Future<void> deleteProduk(int id) async {
    try {
      await supabase.from('produk').delete().eq('produk_id', id).select();
      fetchProduk();
      _showSuccess('User berhasil dihapus');
    } catch (e) {
      _showError('Gagal menghapus user.');
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

  void _showFormDialog({int? produk_id, String? nama_produk, String? harga, String? stok}) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController nama_produkController = TextEditingController(text: nama_produk ?? '');
    final TextEditingController hargaController = TextEditingController(text: harga ?? '');
    final TextEditingController stokController = TextEditingController(text: stok?? '' );
    bool obscureText = true;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(produk_id == null ? 'Tambah Produk' : 'Edit Produk'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nama_produkController,
                decoration: const InputDecoration(labelText: 'nama_produk'),
                validator: (value) => value!.isEmpty ? 'nama_produk tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: hargaController,
                obscureText: obscureText,
                decoration: InputDecoration(
                  labelText: 'harga',
                  suffixIcon: IconButton(
                    icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'harga tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: stokController,
                decoration: const InputDecoration(labelText: 'stok'),
                validator: (value) => value!.isEmpty ? 'stok tidak boleh kosong' : null,
              ),
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
                if (produk_id == null) {
                  addProduk(nama_produkController.text, hargaController.text, stokController.text);
                } else {
                  editProduk(produk_id, nama_produkController.text, hargaController.text, stokController.text);
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
      appBar: AppBar(title: const Text('Data Produk')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userList.isEmpty
              ? const Center(child: Text('Tidak ada data produk.'))
              : ListView.builder(
                  itemCount: userList.length,
                  itemBuilder: (context, index) {
                    final produk = userList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(produk['nama_produk'] ?? 'Unknown'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showFormDialog(
                                  produk_id: produk['produk_id'],
                                  nama_produk: produk['nama_produk'],
                                  harga: produk['harga'],
                                  stok: produk['stok'],
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                deleteProduk(produk['produk_id']);
                              },
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
