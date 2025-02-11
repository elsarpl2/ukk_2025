import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RiwayatPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const RiwayatPage({Key? key, this.onRefresh}) : super(key: key);

  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _transactionHistory = [];
  List<Map<String, dynamic>> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactionHistory();
  }

  Future<void> _fetchTransactionHistory() async {
    try {
      final response = await _supabase
          .from('penjualan')
          .select('''
            penjualan_id,
            tanggal_penjualan,
            total_harga,
            pelanggan_id,
            pelanggan (nama_pelanggan),
            detail_penjualan (
              detail_id,
              produk_id,
              jumlah_produk,
              subtotal,
              produk (nama_produk)
            )
          ''')
          .order('tanggal_penjualan', ascending: false);

      List<Map<String, dynamic>> transactions = List<Map<String, dynamic>>.from(response as List<dynamic>);

      setState(() {
        _transactionHistory = transactions;
        _filteredTransactions = transactions;
      });

      debugPrint('Total transaksi yang diambil: ${_transactionHistory.length}');
    } catch (error) {
      debugPrint('Error mengambil data: $error');
    }
  }

  void _filterTransactions(String query) {
    if (query.isEmpty) {
      setState(() => _filteredTransactions = _transactionHistory);
      return;
    }

    query = query.toLowerCase();

    setState(() {
      _filteredTransactions = _transactionHistory.where((transaction) {
        final String transactionId = transaction['penjualan_id'].toString().toLowerCase();

        // Ambil daftar produk dari detail_penjualan
        final List<dynamic> details = transaction['detail_penjualan'] ?? [];
        final List<String> productNames = details.map((detail) {
          return (detail['produk']?['nama_produk'] ?? '').toString().toLowerCase();
        }).toList();

        // Periksa apakah ID transaksi atau salah satu nama produk mengandung query
        return transactionId.contains(query) || productNames.any((name) => name.contains(query));
      }).toList();
    });

    debugPrint('Hasil pencarian: ${_filteredTransactions.length} transaksi ditemukan');
  }

  String _formatDateTime(String dateTime) {
    try {
      final parsedDate = DateTime.parse(dateTime);
      String day = parsedDate.day.toString().padLeft(2, '0');
      String month = _getMonthName(parsedDate.month);
      String year = parsedDate.year.toString();
      return '$day $month $year';
    } catch (e) {
      return 'Format tanggal tidak valid';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : 'Bulan Tidak Valid';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cari berdasarkan ID atau Nama Produk',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterTransactions,
            ),
          ),
          Expanded(
            child: _filteredTransactions.isEmpty
                ? const Center(child: Text('Belum ada riwayat transaksi.'))
                : ListView.builder(
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _filteredTransactions[index];
                      final formattedDate = _formatDateTime(transaction['tanggal_penjualan']);
                      final detailPenjualan = transaction['detail_penjualan'] ?? [];
                      final totalHarga = transaction['total_harga'];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ExpansionTile(
                          title: Text('Transaksi #${transaction['penjualan_id']}'), // Menampilkan ID transaksi
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tanggal: $formattedDate'),
                              Text('Total: Rp $totalHarga'),
                            ],
                          ),
                          children: detailPenjualan.isNotEmpty
                              ? detailPenjualan.map<Widget>((detail) {
                                  return ListTile(
                                    title: Text(detail['produk']?['nama_produk'] ?? 'Produk Tidak Diketahui'),
                                    subtitle: Text('Jumlah: ${detail['jumlah_produk']} | Subtotal: Rp ${detail['subtotal']}'),
                                  );
                                }).toList()
                              : [const ListTile(title: Text('Tidak ada detail produk'))],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
