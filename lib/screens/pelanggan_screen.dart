// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class PelangganPage extends StatefulWidget {
//   const PelangganPage({Key? key}) : super(key: key);

//   @override
//   _PelangganPageState createState() => _PelangganPageState();
// }

// class _PelangganPageState extends State<PelangganPage> {
//   final SupabaseClient supabase = Supabase.instance.client;
//   List<Map<String, dynamic>> userList = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchPelanggan();
//   }

//   Future<void> fetchPelanggan() async {
//     try {
//       final response = await supabase.from('pelanggan').select().order('pelanggan_id');
//       if (response is List) {
//         setState(() {
//           userList = List<Map<String, dynamic>>.from(response);
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       _showError('Gagal memuat data pelanggan.');
//     }
//   }

//   Future<bool> isPelangganExist(String nama_pelanggan) async {
//     final response = await supabase.from('pelanggan').select().eq('nama_pelanggan', nama_pelanggan);
//     return response.isNotEmpty; 
//   }

//   Future<void> addPelanggan(String nama_pelanggan, String alamat, String no_telp) async {
//   try {
//     // Cek apakah username sudah ada
//     final existingUser = await supabase
//         .from('pelanggan')
//         .select('nama_pelanggan')
//         .eq('nama_pelanggan', nama_pelanggan)
//         .maybeSingle();

//     if (existingUser != null) {
//       _showError('nama_pelanggan sudah digunakan. Gunakan nama lain.');
//       return;
//     }

//     // Tambahkan pelanggan jika username belum ada
//     await supabase.from('pelanggan').insert({
//       'nama_pelanggan': nama_pelanggan,
//       'alamat': alamat,
//       'no_telp': no_telp
//     }).select();

//     fetchPelanggan();
//     _showSuccess('Pelanggan berhasil ditambahkan');
//   } catch (e) {
//     _showError('Gagal menambahkan pelanggan.');
//   }
// }

//   Future<void> editPelanggan(int pelanggan_id, String nama_pelanggan, String alamat, String no_telp) async {
//     try {
//       await supabase.from('pelanggan').update({
//         'nama_pelanggan': nama_pelanggan,
//         'alamat': alamat,
//         'no_telp': no_telp,
//       }).eq('pelanggan_id', pelanggan_id).select();
//       fetchPelanggan();
//       _showSuccess('Pelanggan berhasil diperbarui');
//     } catch (e) {
//       _showError('Gagal mengedit pelanggan.');
//     }
//   }

//   Future<void> deletePelanggan(int id) async {
//     try {
//       await supabase.from('pelanggan').delete().eq('pelanggan_id', id).select();
//       fetchPelanggan();
//       _showSuccess('Pelanggan berhasil dihapus');
//     } catch (e) {
//       _showError('Gagal menghapus pelanggan.');
//     }
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//   }

//   void _showSuccess(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   void _showFormDialog({int? pelanggan_id, String? nama_pelanggan, String? alamat, String? no_telp}) {
//     final _formKey = GlobalKey<FormState>();
//     final TextEditingController nama_pelangganController = TextEditingController(text: nama_pelanggan ?? '');
//     final TextEditingController alamatController = TextEditingController(text: alamat ?? '');
//     final TextEditingController no_telpController = TextEditingController(text: no_telp ?? '');

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text(pelanggan_id == null ? 'Tambah Pelanggan' : 'Edit Pelanggan'),
//         content: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextFormField(
//                 controller: nama_pelangganController,
//                 decoration: const InputDecoration(labelText: 'Nama pelanggan'),
//                 validator: (value) => value!.isEmpty ? 'Nama pelanggan tidak boleh kosong' : null,
//               ),
//               TextFormField(
//                  controller: alamatController,
//                  decoration: const InputDecoration(labelText: 'alamat'),
//                  keyboardType: TextInputType.number,
//                  validator: (value) {
//                    if (value == null || value.isEmpty) {
//                      return 'Alamat tidak boleh kosong';
//                    }
//                  },
//                ),
//              TextFormField(
//                  controller: no_telpController,
//                  decoration: const InputDecoration(labelText: 'no_telp'),
//                  keyboardType: TextInputType.number,
//                  validator: (value) {
//                    if (value == null || value.isEmpty) {
//                      return 'no_telp tidak boleh kosong';
//                    }
//                    if (int.tryParse(value) == null) {
//                      return 'no_telp harus berupa angka';
//                    }
//                    return null;
//                  },
//              )
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             style: TextButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Batal'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
//             onPressed: () {
//               if (_formKey.currentState!.validate()) {
//                 if (pelanggan_id == null) {
//                   addPelanggan(nama_pelangganController.text, alamatController.text, no_telpController.text);
//                 } else {
//                   editPelanggan(pelanggan_id, nama_pelangganController.text, alamatController.text, no_telpController.text);
//                 }
//                 Navigator.pop(context);
//               }
//             },
//             child: const Text('Simpan'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Data Pelanggan')),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : userList.isEmpty
//               ? const Center(child: Text('Tidak ada data pelanggan.'))
//               : ListView.builder(
//                   itemCount: userList.length,
//                   itemBuilder: (context, index) {
//                     final pelanggan = userList[index];
//                     return Card(
//                       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                       child: ListTile(
//                         title: Text(pelanggan['nama_pelanggan'] ?? 'Unknown'),
//                         trailing: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             IconButton(
//                               icon: const Icon(Icons.edit, color: Colors.blue),
//                               onPressed: () {
//                                 _showFormDialog(
//                                   pelanggan_id: pelanggan['pelanggan_id'],
//                                   nama_pelanggan: pelanggan['nama_pelanggan'],
//                                   alamat: pelanggan['alamat'],
//                                   no_telp: pelanggan['no_telp'],
//                                 );
//                               },
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.delete, color: Colors.red),
//                               onPressed: () {
//                                 deletePelanggan(pelanggan['pelanggan_id']);
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showFormDialog(),
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
