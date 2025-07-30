import 'package:flutter/material.dart';
import 'package:scooby_app_new/views/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://gsvaodafizhljmohefgp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdzdmFvZGFmaXpobGptb2hlZmdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM1ODg1OTAsImV4cCI6MjA2OTE2NDU5MH0.ID--umSslQiaoR8s6RnzuCr2R291sN4zjugI8p34GJg',
  );
  
  runApp(ScoobyApp()); 
}


class ScoobyApp extends StatelessWidget {
  const ScoobyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scooby App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: LoginScreen(),

/* commented the below for routes management but used
      home: const Wrapper(),  // which decides which screen to show
      initialRoute: '/',  // Splash Screen will show first
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/registerPetOwner': (context) => const RegisterPetOwner(),
        '/registerServiceProvider': (context) => const RegisterServiceProvider(),
        '/petOwnerHome': (context) => const HomeScreen(),  
        '/serviceProviderHome': (context) => const ServiceProviderHomeScreen(),
      },
*/
    );
  }
}
