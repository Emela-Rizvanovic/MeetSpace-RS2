import 'package:flutter/material.dart';
import 'package:meetspace_mobile/pages/register_page.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/menu_page.dart';
import 'pages/my_profile_page.dart';
import 'pages/extra_services_page.dart';
import 'pages/explore_spaces_page.dart';
import 'pages/about_us_page.dart';
import 'pages/contact_page.dart';
import 'pages/settings_page.dart';
import 'pages/edit_profile_page.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'providers/notification_provider.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Stripe.publishableKey = "pk_test_51R5meHR9NYFfZVzXMEoPGifu3MmL3YikWaErXwfPgBMZHuSpytfodAe0YUMkcmwarmsboT2lMDfAb34WEWFovWt400IHjNPTo7";
  await Stripe.instance.applySettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
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
        Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _autoLoginFuture,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final auth = Provider.of<AuthProvider>(context);

        if (auth.isLoggedIn) {
          return const HomePage();
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
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const HomePage(),
        '/forgot-password': (_) => const ForgotPasswordPage(),
        '/reset-password': (_) => const ResetPasswordPage(),
        '/menu': (_) => const MenuPage(),
        '/my-profile': (_) => const MyProfilePage(),
        '/extra-services': (_) => const ExtraServicesPage(),
        '/explore-spaces': (_) => const ExploreSpacesPage(),
        '/about-us': (_) => const AboutUsPage(),
        '/contact': (_) => const ContactPage(),
        '/settings': (_) => const SettingsPage(),
        '/edit-profile': (_) => const EditProfilePage(),
      },
    );
  }
}

