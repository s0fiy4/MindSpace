import 'package:flutter/material.dart';
import 'editprofile.dart';
import 'profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyProfilePage extends StatefulWidget {
  @override
  _MyProfilePageState createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final supabase = Supabase.instance.client; // Supabase client
  String fullName = "User"; // Default full name
  String email = "example@example.com"; // Default email
  String phone = "No Data"; // Default phone number
  String profileImage = "assets/profile.png"; // Default profile image

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = supabase.auth.currentUser; // Get current user
      if (user != null) {
        // Fetch email directly from authentication
        setState(() {
          email = user.email ?? "example@example.com"; // Fallback to default
        });

        // Fetch additional details from profiles table
        final response = await supabase
            .from('profiles') // Table name in Supabase
            .select('first_name, last_name, phone, profile_image')
            .eq('id', user.id)
            .maybeSingle(); // Fetch single user row

        if (response != null) {
          setState(() {
            final firstName = response['first_name'] ?? "User";
            final lastName = response['last_name'] ?? "";
            fullName = "$firstName $lastName";
            phone = response['phone'] ?? "No Data"; // Use "No Data" if null
            profileImage = response['profile_image'] ?? "assets/profile.png";
          });
        }
      } else {
        print("No user is currently logged in.");
      }
    } catch (error) {
      print("Error fetching user profile: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to profile page when the back button is pressed
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
          (route) => false,
        );
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "My Profile",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(),
                ),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigate to edit profile page or handle edit action
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(),
                  ),
                );
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _fetchUserProfile, // Refresh profile data
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImage == "assets/profile.png"
                        ? AssetImage(profileImage) as ImageProvider
                        : NetworkImage(profileImage),
                  ),
                  const SizedBox(height: 40), // Added more space below the avatar
                  _buildProfileField(Icons.person, fullName),
                  const SizedBox(height: 30), // Increased spacing between sections
                  _buildProfileField(Icons.email, email),
                  const SizedBox(height: 30), // Increased spacing between sections
                  _buildProfileField(Icons.phone, phone),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildProfileField(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey,
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
