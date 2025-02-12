import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'dart:html' as html;
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

  String? _selectedCustomerId; // ID of the selected customer
  String? _selectedCustomerName; // Name of the selected customer
  double _totalPrice = 0; // Total price of the cart

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchCustomers();
  }

  Future<void> _fetchProducts() async {
    final response = await _supabase.from('produk').select();
    setState(() {
      _products = List<Map<String, dynamic>>.from(response as List<dynamic>);
      _filteredProducts = _products; // Initialize filtered products
    });
  }

  Future<void> _fetchCustomers() async {
    final response = await _supabase.from('pelanggan').select('pelanggan_id, nama_pelanggan');
    setState(() {
      _customers = List<Map<String, dynamic>>.from(response as List<dynamic>);
      print("Customers List: $_customers"); // Debugging
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
          _cart[index]['quantity'] += 1; // Increase quantity if stock allows
        }
      } else {
        _cart.add({...product, 'quantity': 1}); // Add new product to cart
      }

      _calculateTotal(); // Recalculate total price
    });
  }

  void _updateCart(Map<String, dynamic> product, int quantity) {
    setState(() {
      final index = _cart.indexWhere((item) => item['produk_id'] == product['produk_id']);
      if (index != -1) {
        if (quantity > 0) {
          _cart[index]['quantity'] = quantity; // Update quantity
        } else {
          _cart.removeAt(index); // Remove product if quantity is zero
        }
      }
      _calculateTotal(); // Recalculate total price
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
        _selectedCustomerId = null; // Reset customer ID
        _selectedCustomerName = null; // Reset customer name
        _totalPrice = 0; // Reset total price
      });

      _fetchProducts(); // Refresh product list
      _showSuccessAlert(purchasedItems); // Show success alert

    } catch (error) {
      debugPrint('Error during checkout: $error');
    }
  }

  void _showSuccessAlert(List<Map<String, dynamic>> purchasedItems) {
    final DateTime now = DateTime.now();
    final String formattedDateTime =
        "${now.day}-${now.month}-${now.year} ${now.hour}:${now.minute}";

    // Calculate total price for alert dialog
    double totalPrice = purchasedItems.fold(0, (sum, item) => sum + (item['harga'] * item['quantity']));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Transaksi Berhasil'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tanggal: $formattedDateTime",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Pelanggan: $_selectedCustomerName", // Display customer name
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Total: Rp ${totalPrice.toStringAsFixed(0)}"),
                const SizedBox(height: 10),
                const Text("Detail Produk:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                ...purchasedItems.map((item) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['nama_produk'],
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Jumlah: ${item['quantity']} | Subtotal: Rp ${(item['harga'] * item['quantity']).toStringAsFixed(0)}"),
                        const Divider(),
                      ],
                    )),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                _generatePDF(purchasedItems, formattedDateTime, totalPrice);
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

  Future<void> _generatePDF(List<Map<String, dynamic>> purchasedItems, String formattedDateTime, double totalPrice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text("TOKO SKINCARE",
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Center(
                child: pw.Text("Jl. Contoh No. 123, Kota", style: pw.TextStyle(fontSize: 12)),
              ),
              pw.Center(
                child: pw.Text("--------------------------------------"),
              ),
              pw.Text("Tanggal: $formattedDateTime",
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text("Pelanggan: $_selectedCustomerName", // Include customer name in PDF
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text("--------------------------------------"),
              ...purchasedItems.map(
                (item) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item['nama_produk'], style: pw.TextStyle(fontSize: 12)),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("${item['quantity']} x Rp ${item['harga'].toStringAsFixed(0)}", style: pw.TextStyle(fontSize: 12)),
                        pw.Text("Rp ${(item['harga'] * item['quantity']).toStringAsFixed(0)}", style: pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    pw.Text("--------------------------------------"),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("TOTAL", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Rp ${totalPrice.toStringAsFixed(0)}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text("Terima Kasih Telah Berbelanja!", style: pw.TextStyle(fontSize: 12)),
              ),
              pw.Center(
                child: pw.Text("--------------------------------------"),
              ),
            ],
          );
        },
      ),
    );

    final Uint8List pdfBytes = await pdf.save();
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'struk_pembelian.pdf')
      ..click();

    html.Url.revokeObjectUrl(url);
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
                  // Find the selected customer and set the name
                  final selectedCustomer = _customers.firstWhere((customer) => customer['pelanggan_id'].toString() == value);
                  _selectedCustomerName = selectedCustomer['nama_pelanggan'];
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
            Text('Total: Rp ${_totalPrice.toStringAsFixed(0)}'),
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