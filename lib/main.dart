import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/customer/customer_shell.dart';
import 'screens/team/team_shell.dart';
import 'screens/sales/sales_shell.dart';
import 'services/auth_service.dart';
import 'providers/tab_refresh_provider.dart';
import 'models/sales_person.dart';
import 'models/customer.dart';

void main() {
  runApp(const SampoornaFeedsApp());
}

class SampoornaFeedsApp extends StatelessWidget {
  const SampoornaFeedsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => TabRefreshProvider()),
      ],
      child: MaterialApp(
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
        ),        initialRoute: '/',
        routes: {
          '/': (context) => const AppInitializer(),
          '/login': (context) => const ExitWarningWrapper(child: LoginScreen()),
          '/customer': (context) => const ExitWarningWrapper(child: CustomerShell()),
          '/team': (context) => const ExitWarningWrapper(child: TeamShell()),
          '/sales': (context) => const ExitWarningWrapper(child: SalesShell()),
        },
      ),
    );
  }
}

class ExitWarningWrapper extends StatelessWidget {
  final Widget child;

  const ExitWarningWrapper({super.key, required this.child});

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit Sampoorna Feeds?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    ) ?? false;
  }  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final shouldPop = await _showExitDialog(context);
        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.checkExistingSession();

    if (mounted) {
      if (authService.isAuthenticated) {
        // Route based on saved persona, not just user type
        final savedPersona = await authService.savedPersona;
        final user = authService.currentUser;
        
        if (user is Customer) {
          Navigator.of(context).pushReplacementNamed('/customer');
        } else if (user is SalesPerson) {
          // For SalesPerson, check the saved persona to determine the correct route
          if (savedPersona == 'team') {
            Navigator.of(context).pushReplacementNamed('/team');
          } else {
            // Default to sales for 'sales' persona or if no persona is saved
            Navigator.of(context).pushReplacementNamed('/sales');
          }
        } else {
          // fallback to login if unknown type
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        // No existing session, go to login
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF008000),
        ),
      ),
    );
  }
}