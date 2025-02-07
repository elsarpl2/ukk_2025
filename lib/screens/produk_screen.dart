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
      _showError('Gagal memuat data produk.');
    }
  }

  Future<bool> isProdukExist(String nama_produk) async {
    final response = await supabase.from('produk').select().eq('nama_produk', nama_produk);
    return response.isNotEmpty; 
  }

  Future<void> addProduk(String nama_produk, String harga, String stok) async {
  try {
    // Cek apakah username sudah ada
    final existingUser = await supabase
        .from('produk')
        .select('nama_produk')
        .eq('nama_produk', nama_produk)
        .maybeSingle();

    if (existingUser != null) {
      _showError('nama_produk sudah digunakan. Gunakan nama lain.');
      return;
    }

    // Tambahkan produk jika username belum ada
    await supabase.from('produk').insert({
      'nama_produk': nama_produk,
      'harga': harga,
      'stok': stok
    }).select();

    fetchProduk();
    _showSuccess('Produk berhasil ditambahkan');
  } catch (e) {
    _showError('Gagal menambahkan produk.');
  }
}

   Future<void> editProduk(int produk_id, String nama_produk, String harga, String stok) async {
    try {
      await supabase.from('produk').update({
        'nama_produk': nama_produk,
        'harga': harga,
        'stok': stok,
      }).eq('id', produk_id).select();
      fetchProduk();
      _showSuccess('Produk berhasil diperbarui');
    } catch (e) {
      _showError('Gagal mengedit produk.');
    }
  }

  Future<void> deleteProduk(int id) async {
    try {
      await supabase.from('produk').delete().eq('produk_id', id).select();
      fetchProduk();
      _showSuccess('Produk berhasil dihapus');
    } catch (e) {
      _showError('Gagal menghapus produk.');
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
    final TextEditingController stokController = TextEditingController(text: stok ?? '');

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
                decoration: const InputDecoration(labelText: 'Nama Produk'),
                validator: (value) => value!.isEmpty ? 'Nama produk tidak boleh kosong' : null,
              ),
              TextFormField(
                 controller: hargaController,
                 decoration: const InputDecoration(labelText: 'Harga'),
                 keyboardType: TextInputType.number,
                 validator: (value) {
                   if (value == null || value.isEmpty) {
                     return 'Harga tidak boleh kosong';
                   }
                   if (double.tryParse(value) == null) {
                     return 'Harga harus berupa angka';
                   }
                   if (double.parse(value) <= 0) {
                     return 'Harga harus lebih besar dari 0';
                 }
                   return null;
                 },
               ),
             TextFormField(
                 controller: stokController,
                 decoration: const InputDecoration(labelText: 'Stok'),
                 keyboardType: TextInputType.number,
                 validator: (value) {
                   if (value == null || value.isEmpty) {
                     return 'Stok tidak boleh kosong';
                   }
                   if (int.tryParse(value) == null) {
                     return 'Stok harus berupa angka';
                   }
                   if (int.parse(value) <= 0) {
                     return 'Stok harus lebih besar dari 0';
                   }
                   return null;
                 },
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
                        subtitle: Text(
                          'Harga: Rp${produk['harga']} | Stok: ${produk['stok']}',
                          style: const TextStyle(color: Colors.grey),
                        ),
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
