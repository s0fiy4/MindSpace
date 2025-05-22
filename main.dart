import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart'; // Import the LoginPage
import 'homepage.dart'; // Import the HomePage
import 'pages_profile/profile.dart'; // Import the ProfilePage
import 'pages_course/course.dart'; // Import the ProfilePage
// ignore: unused_import
import 'auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://hszxefcgeahrybiikwwl.supabase.co', // Replace with your Supabase project URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhzenhlZmNnZWFocnliaWlrd3dsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcwNjkwMDQsImV4cCI6MjA1MjY0NTAwNH0.ryQMueirdtbPEhsU2Op1JPyeUG29bxZwWNNmSkQGyEo',           // Replace with your Supabase anon key
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindSpace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/onboarding', // Set initial route
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/courses': (context) => CoursePage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/mindspace_logo.png', // Replace with the path to your image
              height: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'MindSpace',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Text color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
