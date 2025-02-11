import 'package:aplikasi/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://opzpuixvqpswtwlfkedg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9wenB1aXh2cXBzd3R3bGZrZWRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg3MTQ1OTksImV4cCI6MjA1NDI5MDU5OX0.FFjLq9yDbSoUMcr7oD6KmyqBXnd2ZwQGO7rRK1VOzDo',
  );
  runApp(MyApp());
}
        
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplikasi kasir',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: LoginScreen(),
    );
  }
}
  