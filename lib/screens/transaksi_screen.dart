import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
  String? _selectedCustomerId; // Menyimpan ID pelanggan
  String? _selectedCustomerName; // Menyimpan nama pelanggan
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
      final existingProduct = _cart.firstWhere(
        (item) => item['produk_id'] == product['produk_id'],
        orElse: () => {},
      );

      if (existingProduct.isNotEmpty) {
        final index = _cart.indexWhere((item) => item['produk_id'] == product['produk_id']);
        if (_cart[index]['quantity'] < product['stok']) {
          _cart[index]['quantity'] += 1;
        }
      } else {
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
    if (_cart.isEmpty || _selectedCustomerId == null) return;

    List<Map<String, dynamic>> purchasedItems = List.from(_cart);

    try {
      final response = await _supabase.from('penjualan').insert({
        'tanggal_penjualan': DateTime.now().toIso8601String(),
        'total_harga': _totalPrice,
        'pelanggan_id': int.parse(_selectedCustomerId!),
      }).select();
      final penjualanId = response[0]['penjualan_id'];

      await Future.wait(purchasedItems.map((item) async {
        await _supabase.from('detail_penjualan').insert({
          'penjualan_id': penjualanId,
          'produk_id': item['produk_id'],
          'jumlah_produk': item['quantity'],
          'subtotal': item['harga'] * item['quantity'],
        });

        final produk = await _supabase.from('produk').select().eq('produk_id', item['produk_id']).single();
        item['nama_produk'] = produk['nama_produk'];

        await _supabase.from('produk').update({
          'stok': produk['stok'] - item['quantity'],
        }).eq('produk_id', item['produk_id']);
      }).toList());

      setState(() {
        _cart.clear();
        _selectedCustomerId = null;
        _selectedCustomerName = null; // Reset nama pelanggan
        _totalPrice = 0;
      });

      _fetchProduk();
      _showSuccessAlert(purchasedItems);

    } catch (error) {
      debugPrint('Error during checkout: $error');
    }
  }

  Future<void> _generatePDF(List<Map<String, dynamic>> purchasedItems) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Struk Pembelian", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text("Nama Pelanggan: $_selectedCustomerName", style: pw.TextStyle(fontSize: 16)), // Menggunakan nama pelanggan
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text("Produk", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("Harga", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("Jumlah", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("Subtotal", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ...purchasedItems.map(
                    (item) => pw.TableRow(
                      children: [
                        pw.Text(item['nama_produk']),
                        pw.Text("Rp ${item['harga']}"),
                        pw.Text("${item['quantity']}"),
                        pw.Text("Rp ${item['harga'] * item['quantity']}"),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Divider(),
              pw.Text("Total Harga: Rp $_totalPrice", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    // Simpan sebagai ByteData
    final Uint8List pdfBytes = await pdf.save();

    // Buat file di browser untuk diunduh
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'struk_pembelian.pdf')
      ..click();

    html.Url.revokeObjectUrl(url);
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
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                _generatePDF(purchasedItems); // Panggil fungsi untuk menghasilkan PDF
                Navigator.pop(context);
              },
            ),
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
              value: _selectedCustomerId,
              hint: const Text('Pilih Pelanggan'),
              isExpanded: true,
              items: _customers.map((customer) {
                return DropdownMenuItem(
                  value: customer['pelanggan_id'].toString(),
                  child: Text(customer['nama_pelanggan']),
                );
              }).toList(),
              onChanged: (value) {
    setState(() {
      _selectedCustomerId = value;
      var selectedCustomer = _customers.firstWhere(
        (customer) => customer['pelanggan_id'].toString() == value,
        orElse: () => {},
      );

      if (selectedCustomer.isNotEmpty) {
        _selectedCustomerName = selectedCustomer['nama_pelanggan'];
      }
    });
              },
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
                    subtitle: Text('Rp ${product['harga']} | Stok: ${product['stok']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: product['stok'] > 0 ? () => _addToCart(product) : null,
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
                              : null,
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
