import 'package:aplikasi/screens/pelanggan_screen.dart'; // Import halaman pelanggan
import 'package:aplikasi/screens/produk_screen.dart'; // Import halaman produk
import 'package:aplikasi/screens/riwayat_screen.dart';
import 'package:aplikasi/screens/transaksi_screen.dart';
import 'package:flutter/material.dart';
import 'user_screen.dart'; // Import halaman user
import 'login_screen.dart'; // Import halaman login

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Menyimpan indeks halaman yang aktif
  final PageController _pageController = PageController(); // Controller untuk mengontrol perpindahan halaman

  // Fungsi untuk mendapatkan daftar halaman yang tersedia di aplikasi
  List<Widget> _getPages() {
    return [
      const RegistrasiPage(), // Halaman user (registrasi)
      const ProdukPage(), // Halaman produk
      const PelangganPage(), // Halaman pelanggan
      const TransaksiPage(),
      const RiwayatPage(),
    ];
  }

  // Fungsi untuk mendapatkan daftar item pada BottomNavigationBar
  List<BottomNavigationBarItem> _getBottomNavItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.person), // Ikon untuk halaman user
        label: 'User',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart), // Ikon untuk halaman produk
        label: 'Produk',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person), // Ikon untuk halaman pelanggan
        label: 'Pelanggan',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart), // Ikon untuk halaman transaksi
        label: 'Transaksi',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.history), // Ikon untuk halaman riwayat transaksi
        label: 'History',
      ),
    ];
  }

  // Fungsi untuk logout dan kembali ke halaman login
  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()), // Navigasi ke halaman login
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Kasir-Skincare", // Judul aplikasi
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 79, 186), // Warna latar belakang AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white), // Ikon logout
            onPressed: _logout, // Memanggil fungsi logout
          ),
        ],
      ),
      body: PageView(
        controller: _pageController, // Menggunakan PageController untuk navigasi halaman
        onPageChanged: (index) { // Fungsi saat halaman digeser
          setState(() {
            _currentIndex = index; // Mengubah indeks halaman aktif
          });
        },
        children: _getPages(), // Menampilkan halaman berdasarkan daftar yang telah dibuat
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Indeks halaman yang aktif di navigasi bawah
        type: BottomNavigationBarType.fixed, // Tipe navigasi agar tetap terlihat
        onTap: (index) { // Fungsi saat item navigasi diklik
          setState(() {
            _currentIndex = index; // Mengubah indeks halaman aktif
          });
          _pageController.jumpToPage(index); // Berpindah ke halaman yang dipilih
        },
        backgroundColor: const Color.fromARGB(255, 7, 80, 190), // Warna latar belakang navigasi bawah
        selectedItemColor: Colors.white, // Warna ikon yang dipilih
        unselectedItemColor: Colors.white70, // Warna ikon yang tidak dipilih
        items: _getBottomNavItems(), // Menampilkan item navigasi yang sudah dibuat
      ),
    );
  }
}
