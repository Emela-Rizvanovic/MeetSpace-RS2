import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart'; 

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future _autoLoginFuture;

  @override
  void initState() {
    super.initState();

    _autoLoginFuture =
        Provider.of<AuthProvider>(
          context,
          listen: false,
        ).tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _autoLoginFuture,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final auth = Provider.of<AuthProvider>(context);

        if (auth.isLoggedIn) {
          return const DashboardPage(); 
        }

        return const LoginPage();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
   return MaterialApp(
  debugShowCheckedModeBanner: false,
  navigatorKey: navigatorKey,
  home: const AuthWrapper(),
  routes: {
    '/login': (_) => const LoginPage(),
  },
);
  }
}