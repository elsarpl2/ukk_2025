import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart'; // Mengimpor halaman utama setelah login

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Kunci untuk validasi formulir
  final TextEditingController nameController = TextEditingController(); // Controller untuk input username
  final TextEditingController passwordController = TextEditingController(); // Controller untuk input password
  bool _isPasswordVisible = false; // Status untuk menampilkan atau menyembunyikan password
  bool _isLoading = false; // Status untuk menampilkan loading saat login berlangsung

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEAEAEA), // Warna latar belakang layar
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20), // Membuat border radius
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Efek bayangan
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey, // Menggunakan kunci formulir untuk validasi
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xff1F509A),
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 20), // Jarak antara elemen
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Username tidak boleh kosong'; // Validasi input
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible, // Menyembunyikan password
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible; // Mengubah status visibilitas password
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong'; // Validasi input password
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login, // Menjalankan fungsi login jika tidak sedang loading
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff1F509A),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white) // Menampilkan indikator loading saat proses login
                          : const Text(
                              'Login',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Fungsi untuk validasi login dengan Supabase
  void _login() async {
    if (_formKey.currentState!.validate()) { // Validasi form sebelum login
      setState(() {
        _isLoading = true;
      });

      final supabase = Supabase.instance.client; // Inisialisasi Supabase
      final String username = nameController.text;
      final String password = passwordController.text;

      try {
        // Mengambil data user berdasarkan username
        final response = await supabase
            .from('user')
            .select('username, password')
            .eq('username', username)
            .maybeSingle();

        if (response == null) {
          _showErrorDialog("Username atau password salah!");
        } else {
          final dbPassword = response['password'] as String?;

          if (dbPassword == null) {
            _showErrorDialog("Data user tidak valid.");
          } else if (dbPassword != password) {
            _showErrorDialog("Username atau password salah!");
          } else {
            // Menyimpan username ke SharedPreferences
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('username', username);

            // Navigasi ke HomeScreen setelah login berhasil
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          }
        }
      } catch (e) {
        _showErrorDialog("Terjadi kesalahan saat login."); // Menampilkan error jika terjadi kesalahan
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk menampilkan pesan error dalam dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Gagal"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Menutup dialog
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
