import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/customer/customer_shell.dart';
import 'screens/vendor/vendor_shell.dart';
import 'screens/sales/sales_shell.dart';
import 'services/auth_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const SampoornaFeedsApp(),
    ),
  );
}

class SampoornaFeedsApp extends StatelessWidget {
  const SampoornaFeedsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sampoorna Feeds',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF008000),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008000),
          primary: const Color(0xFF008000),
          background: Colors.white,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/customer': (context) => const CustomerShell(),
        '/vendor': (context) => const VendorShell(),
        '/sales': (context) => const SalesShell(),
      },
    );
  }
}