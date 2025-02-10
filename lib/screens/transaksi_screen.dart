import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({Key? key}) : super(key: key);

  @override
  _TransaksiPageState createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _cart = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _customers = [];
  String? _selectedCustomer;
  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _fetchProduk();
    _fetchCustomer();
  }

  Future<void> _fetchProduk() async {
    final response = await _supabase.from('produk').select();
    setState(() {
      _products = List<Map<String, dynamic>>.from(response as List<dynamic>);
      _filteredProducts = _products;
    });
  }

  Future<void> _fetchCustomer() async {
    final response = await _supabase.from('pelanggan').select();
    setState(() {
      _customers = List<Map<String, dynamic>>.from(response as List<dynamic>);
    });
  }

 void _addToCart(Map<String, dynamic> product) {
  setState(() {
    // Cek apakah produk sudah ada di dalam keranjang
    final existingProduct = _cart.firstWhere(
      (item) => item['produk_id'] == product['produk_id'],
      orElse: () => {},
    );

    if (existingProduct.isNotEmpty) {
      // Jika produk sudah ada, tambahkan jumlahnya jika belum melebihi stok
      final index = _cart.indexWhere((item) => item['produk_id'] == product['produk_id']);
      if (_cart[index]['quantity'] < product['stok']) {
        _cart[index]['quantity'] += 1;
      }
    } else {
      // Jika produk belum ada, tambahkan sebagai item baru dengan jumlah 1
      _cart.add({...product, 'quantity': 1});
    }

    _calculateTotal();
  });
}

  void _updateCart(Map<String, dynamic> product, int quantity) {
    setState(() {
      final index = _cart.indexWhere((item) => item['produk_id'] == product['produk_id']);
      if (index != -1) {
        if (quantity > 0) {
          _cart[index]['quantity'] = quantity;
        } else {
          _cart.removeAt(index);
        }
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    setState(() {
      _totalPrice = _cart.fold(0, (sum, item) => sum + (item['harga'] * item['quantity']));
    });
  }

 Future<void> _checkout() async {
  if (_cart.isEmpty || _selectedCustomer == null) return;

  // Salin data _cart sebelum dikosongkan
  List<Map<String, dynamic>> purchasedItems = List.from(_cart);

  try {
    final response = await _supabase.from('penjualan').insert({
      'tanggal_penjualan': DateTime.now().toIso8601String(),
      'total_harga': _totalPrice,
      'pelanggan_id': int.parse(_selectedCustomer!),
    }).select();
    final penjualanId = response[0]['penjualan_id'];

    // Simpan transaksi detail dan update stok
    await Future.wait(purchasedItems.map((item) async {
      await _supabase.from('detail_penjualan').insert({
        'penjualan_id': penjualanId,
        'produk_id': item['produk_id'],
        'jumlah_produk': item['quantity'],
        'subtotal': item['harga'] * item['quantity'],
      });

      // Ambil data produk untuk mendapatkan nama_produk yang valid
      final produk = await _supabase.from('produk').select().eq('produk_id', item['produk_id']).single();
      
      item['nama_produk'] = produk['nama_produk']; // Pastikan nama produk disimpan

      // Update stok di database
      await _supabase.from('produk').update({
        'stok': produk['stok'] - item['quantity'],
      }).eq('produk_id', item['produk_id']);
    }).toList());

    // Kosongkan keranjang setelah transaksi selesai
    setState(() {
      _cart.clear();
      _selectedCustomer = null;
      _totalPrice = 0;
    });

    _fetchProduk(); // Perbarui stok setelah transaksi
    _showSuccessAlert(purchasedItems); // Tampilkan alert dengan produk yang dibeli

  } catch (error) {
    debugPrint('Error during checkout: $error');
  }
}

 void _showSuccessAlert(List<Map<String, dynamic>> purchasedItems) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Transaksi Berhasil'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              const Text('Detail pembelian:'),
              const SizedBox(height: 8),
              ...purchasedItems.map((item) => Text('${item['nama_produk']} - ${item['quantity']}x')).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedCustomer,
              hint: const Text('Pilih Pelanggan'),
              isExpanded: true,
              items: _customers.map((customer) {
                return DropdownMenuItem(
                  value: customer['pelanggan_id'].toString(),
                  child: Text(customer['nama_pelanggan']),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCustomer = value),
            ),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(labelText: 'Cari Produk'),
              onChanged: (query) {
                setState(() {
                  _filteredProducts = _products
                      .where((product) => product['nama_produk'].toLowerCase().contains(query.toLowerCase()))
                      .toList();
                });
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return ListTile(
                    title: Text(product['nama_produk']),
                    subtitle: Text('Rp ${product['harga']} | Stok: ${product['stok']}'), // Menampilkan stok
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: product['stok'] > 0 ? () => _addToCart(product) : null, // Cegah jika stok habis
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _cart.length,
                itemBuilder: (context, index) {
                  final item = _cart[index];
                  return ListTile(
                    title: Text(item['nama_produk']),
                    subtitle: Text('Rp ${item['harga']} x ${item['quantity']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: item['quantity'] > 1 ? () => _updateCart(item, item['quantity'] - 1) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: item['quantity'] < item['stok']
                              ? () => _updateCart(item, item['quantity'] + 1)
                              : null, // Cegah jika stok habis
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Text('Total: Rp ${_totalPrice.toStringAsFixed(2)}'),
            ElevatedButton(
              onPressed: _checkout,
              child: const Text('Bayar'),
            ),
          ],
        ),
      ),
    );
  }
}
