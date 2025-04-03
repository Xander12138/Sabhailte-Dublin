import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/sign_up_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/dashboard/presentation/dashboard_page.dart';
import 'features/dashboard/presentation/news_page.dart';
import 'features/dashboard/presentation/map_page.dart';
import 'features/dashboard/presentation/go_live_page.dart';
import 'features/dashboard/presentation/ultra_911_page.dart';
import 'features/dashboard/presentation/user_profile_page.dart';
import 'features/dashboard/presentation/camera.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/welcome/welcome_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sábháilte Dublin',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/', // Start with the Welcome Page
        routes: {
          '/': (context) => WelcomePage(), // Welcome Page
          '/login': (context) => LoginPage(), // Login Page
          '/sign-up': (context) => SignUpPage(), // Sign-Up Page
          '/home': (context) => HomePage(), // Main Home Page

          // Individual pages for debugging (optional, can be removed for production)
          '/news': (context) => NewsPage(), // News Tab
          '/map': (context) => MapPage(), // Map Tab
          '/go-live': (context) => GoLivePage(), // Go Live Tab
          '/ultra-911': (context) => Ultra911Page(), // Ultra 911 Tab
          '/profile': (context) => UserProfilePage(), // Profile Tab
          '/camera': (context) => CameraPage(),
        },
      ),
    );
  }
}
