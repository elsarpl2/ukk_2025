import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProdukPage extends StatefulWidget {
  const ProdukPage({Key? key}) : super(key: key);

  @override
  _ProdukPageState createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> produkList = [];
  List<Map<String, dynamic>> filteredProdukList = [];
  bool isLoading = true;
  String searchQuery = '';

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
          produkList = List<Map<String, dynamic>>.from(response);
          filteredProdukList = produkList;
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

  void searchProduk(String query) {
  final searchQueryLower = query.toLowerCase();
  final isNumeric = double.tryParse(query) != null; // Cek apakah query angka

  final results = produkList.where((produk) {
    final namaProduk = produk['nama_produk']?.toLowerCase() ?? '';
    final hargaProduk = produk['harga']?.toString() ?? '';

    if (isNumeric) {
      return hargaProduk.contains(query); // Cari berdasarkan harga
    } else {
      return namaProduk.contains(searchQueryLower); // Cari berdasarkan nama
    }
  }).toList();

  setState(() {
    filteredProdukList = results;
    searchQuery = query; // Tidak error karena searchQuery sudah dideklarasikan
  });
}


  // void searchProduk(String query) {
  //   final results = produkList.where((produk) {
  //     final namaProduk = produk['nama_produk']?.toLowerCase() ?? '';
  //     final searchQuery = query.toLowerCase();
  //     return namaProduk.contains(searchQuery);
  //   }).toList();

  //   setState(() {
  //     filteredProdukList = results;
  //     searchQuery = query;
  //   });
  // }

  Future<bool> isProdukExists(String namaProduk) async {
    final response = await supabase.from('produk').select().eq('nama_produk', namaProduk);
    return response.isNotEmpty;
  }

  Future<void> addProduk(String namaProduk, String harga, String stok) async {
    if (await isProdukExists(namaProduk)) {
      _showError('Produk dengan nama tersebut sudah ada.');
      return;
    }

    try {
      await supabase.from('produk').insert({
        'nama_produk': namaProduk,
        'harga': int.parse(harga),
        'stok': int.parse(stok),
      });

      fetchProduk();
      _showSuccess('Produk berhasil ditambahkan');
    } catch (e) {
      _showError('Gagal menambahkan produk.');
    }
  }

  Future<void> editProduk(int produkId, String namaProduk, String harga, String stok) async {
    final produkLama = produkList.firstWhere((p) => p['produk_id'] == produkId, orElse: () => {});
    if (produkLama.isNotEmpty && produkLama['nama_produk'] != namaProduk) {
      if (await isProdukExists(namaProduk)) {
        _showError('Produk dengan nama tersebut sudah ada.');
        return;
      }
    }

    try {
      await supabase.from('produk').update({
        'nama_produk': namaProduk,
        'harga': int.parse(harga),
        'stok': int.parse(stok),
      }).eq('produk_id', produkId);

      fetchProduk();
      _showSuccess('Produk berhasil diperbarui');
    } catch (e) {
      _showError('Gagal mengedit produk.');
    }
  }

  Future<void> deleteProduk(int produkId) async {
    try {
      await supabase.from('produk').delete().eq('produk_id', produkId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Produk'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: searchProduk,
              decoration: InputDecoration(
                hintText: 'Cari Produk atau harga',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredProdukList.isEmpty
              ? const Center(child: Text('Tidak ada data produk.'))
              : ListView.builder(
                  itemCount: filteredProdukList.length,
                  itemBuilder: (context, index) {
                    final produk = filteredProdukList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(produk['nama_produk'] ?? 'Unknown'),
                        subtitle: Text(
                          'Harga: Rp${produk['harga']} | Stok: ${produk['stok']}',
                          style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showFormDialog(
                                  produkId: produk['produk_id'],
                                  namaProduk: produk['nama_produk'],
                                  harga: produk['harga'].toString(),
                                  stok: produk['stok'].toString(),
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

  void _showFormDialog({int? produkId, String? namaProduk, String? harga, String? stok}) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController namaProdukController = TextEditingController(text: namaProduk ?? '');
    final TextEditingController hargaController = TextEditingController(text: harga ?? '');
    final TextEditingController stokController = TextEditingController(text: stok ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(produkId == null ? 'Tambah Produk' : 'Edit Produk'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: namaProdukController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
                validator: (value) => value!.isEmpty ? 'Nama produk tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: hargaController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) <= 0
                    ? 'Harga harus berupa angka'
                    : null,
              ),
              TextFormField(
                controller: stokController,
                decoration: const InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) < 0
                    ? 'Stok harus berupa angka'
                    : null,
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
                produkId == null
                    ? addProduk(namaProdukController.text, hargaController.text, stokController.text)
                    : editProduk(produkId, namaProdukController.text, hargaController.text, stokController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
