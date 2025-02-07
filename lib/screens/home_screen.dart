import 'package:aplikasi/screens/pelanggan_screen.dart';
import 'package:aplikasi/screens/produk_screen.dart';
import 'package:flutter/material.dart';
import 'user_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  List<Widget> _getPages() {
    return [
      const RegistrasiPage(), // Placeholder untuk halaman User
      const ProdukPage(), 
      // const PelangganPage()
    ];
  }

  List<BottomNavigationBarItem> _getBottomNavItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'User',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart),
        label: 'Produk',
      ),
      // BottomNavigationBarItem(
      //   icon: Icon(Icons.person),
      //   label: 'Pelanggan',
      // ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Kasir-Elsa",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 79, 186),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _getPages(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.jumpToPage(index);
        },
        backgroundColor: const Color.fromARGB(255, 7, 80, 190),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: _getBottomNavItems(),
      ),
    );
  }
}