import 'dart:io'; // Import this for exit(0)
import 'package:flutter/material.dart';
import 'package:mindspace/homepage.dart';
import 'package:mindspace/pages_course/course.dart';
import 'about_us.dart';
import 'terms.dart';
import 'mycert.dart';
import 'myprofile.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:mindspace/auth/auth_gate.dart'; // Import AuthGate for logout redirection

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 2; // Default selected index for Profile section
  final supabase = Supabase.instance.client; // Supabase client
  String fullName = "User"; // Default full name
  String profileImage = "assets/profile.png"; // Default profile image

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data on initialization
  }

  Future<void> _fetchUserData() async {
    try {
      final user = supabase.auth.currentUser; // Get current user
      if (user != null) {
        final response = await supabase
            .from('profiles') // Fetch data from profiles table
            .select('first_name, last_name, profile_image')
            .eq('id', user.id)
            .maybeSingle(); // Get single row or null if no match

        if (response != null) {
          setState(() {
            final firstName = response['first_name'] ?? "User";
            final lastName = response['last_name'] ?? "";
            fullName = "$firstName $lastName"; // Combine first and last names
            profileImage = response['profile_image'] ?? "assets/profile.png"; // Default to assets if null
          });
        } else {
          print("No profile data found for user.");
        }
      } else {
        print("No user is currently logged in.");
      }
    } catch (error) {
      print("Error fetching user data: $error");
    }
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut(); // Sign out the user
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()), // Redirect to AuthGate
      );
    } catch (error) {
      print("Error logging out: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Exit App"),
            content: const Text("Are you sure you want to exit?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // Stay in the app
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  exit(0); // Exit the app
                },
                child: const Text("Exit"),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: const Text(
            "Profile",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section with Picture on the Left
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: profileImage == "assets/profile.png"
                        ? AssetImage(profileImage) as ImageProvider
                        : NetworkImage(profileImage),
                  ),
                  const SizedBox(width: 16), // Space between image and name
                  Text(
                    fullName, // Display full name
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30), // Space below the profile section

              // Profile Options
              _buildOption(
                icon: Icons.person,
                label: "My Profile",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyProfilePage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20), // Adjust gap between sections
              _buildOption(
                icon: Icons.badge,
                label: "My Certifications",
                onTap: () {
                  // Handle My Certifications tap
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyCertificationsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20), // Adjust gap between sections
              _buildOption(
                icon: Icons.description_outlined,
                label: "Terms and Conditions",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TermsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20), // Adjust gap between sections
              _buildOption(
                icon: Icons.info_outline,
                label: "About Us",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutUsPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40), // Space below "About Us"

              // Logout Button
              Center(
                child: OutlinedButton(
                  onPressed: () async {
                    final shouldLogout = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Confirm Logout"),
                        content: const Text("Are you sure you want to logout?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Logout"),
                          ),
                        ],
                      ),
                    );
                    if (shouldLogout == true) {
                      _logout(); // Perform logout and redirect
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue), // Border color
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Colors.blue,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index; // Update the current index
            });

            // Navigate without animation
            switch (index) {
              case 1:
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => CoursePage(), // Replace with your home page widget
                    transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                  ),
                );
                break;
              case 0:
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => HomePage(), // Replace with your profile page widget
                    transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                  ),
                );
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: "Courses",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Adjust height by increasing vertical padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
