import 'package:flutter/material.dart';
import 'package:mindspace/pages_course/course.dart';
import 'package:mindspace/pages_profile/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase package
import 'pages_home/search.dart'; // Import the SearchPage
import 'pages_home/category.dart'; // Import the CategoryPage
import 'pages_home/trending.dart';
import 'pages_course/course_info.dart';
// Import CourseCategoryPage for navigation
import 'pages_home/course_category.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(initialPage: 1000);
  int _currentBannerIndex = 0;
  final List<String> banners = [
    'assets/banner1.png',
    'assets/banner2.png',
    'assets/banner3.png',
  ];

  String? firstName = "User"; // Default name if data is not fetched
  String profileImage = "assets/profile.png"; // Default profile image
  final supabase = Supabase.instance.client; // Supabase client

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> trendingCourses = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data on initialization
    _fetchCategoriesAndTrending(); // Fetch categories and trending courses
  }

  Future<void> _fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('profiles')
            .select('first_name, profile_image')
            .eq('id', user.id)
            .maybeSingle();

        if (response != null) {
          print('Fetched user data: $response'); // Debugging
          setState(() {
            firstName = response['first_name'] ?? 'User';
            profileImage = response['profile_image'] ?? "assets/profile.png"; // Default to assets if null
          });
        } else {
          print('No data found for user');
        }
      } else {
        print('No user is currently logged in');
      }
    } catch (error) {
      print('Error fetching user data: $error');
    }
  }

  Future<void> _fetchCategoriesAndTrending() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Fetch categories
      final categoryResponse = await supabase
          .from('category')
          .select('id, name, image_url');

      // ignore: unnecessary_null_comparison
      if (categoryResponse != null) {
        print('Fetched categories: $categoryResponse'); // Debugging
        setState(() {
          categories = List<Map<String, dynamic>>.from(categoryResponse);
        });
      } else {
        print('No categories found');
      }

      // Fetch trending courses
      final trendingResponse = await supabase
          .from('trending')
          .select('courses(id, title, duration, price, image_url)');

      // ignore: unnecessary_null_comparison
      if (trendingResponse != null) {
        print('Fetched trending courses: $trendingResponse'); // Debugging
        setState(() {
          trendingCourses = List<Map<String, dynamic>>.from(trendingResponse);
        });
      } else {
        print('No trending courses found');
      }
    } catch (error) {
      print('Error fetching categories or trending courses: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => exit(0),
                child: const Text('Exit'),
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
          title: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: profileImage == "assets/profile.png"
                      ? AssetImage(profileImage) as ImageProvider
                      : NetworkImage(profileImage),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  "Welcome, $firstName",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          toolbarHeight: 80,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              color: Colors.white,
              child: TextField(
                readOnly: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchPage()),
                  );
                },
                decoration: InputDecoration(
                  hintText: "Search",
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: Icon(Icons.tune),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _fetchCategoriesAndTrending,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentBannerIndex = index % banners.length;
                              });
                            },
                            itemBuilder: (context, index) {
                              final bannerIndex = index % banners.length;
                              return Image.asset(
                                banners[bannerIndex],
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(banners.length, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentBannerIndex == index ? 12 : 8,
                              height: _currentBannerIndex == index ? 12 : 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentBannerIndex == index
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Category",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CategoryPage()),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color.fromARGB(255, 8, 0, 255),
                        ),
                        child: const Text("See All"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 150,
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : categories.isNotEmpty
                            ? ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CourseCategoryPage(
                                            categoryId: category['id'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: _buildCategoryItem(
                                      category['name'],
                                      category['image_url'],
                                    ),
                                  );
                                },
                              )
                            : const Center(
                                child: Text(
                                  "No categories found.",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Trending Course",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TrendingPage()),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color.fromARGB(255, 8, 0, 255),
                        ),
                        child: const Text("See All"),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 250,
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : trendingCourses.isNotEmpty
                            ? ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: trendingCourses.length,
                                itemBuilder: (context, index) {
                                  final course = trendingCourses[index]['courses'];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CourseInfoPage(
                                            courseId: course['id'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: _buildTrendingCourseCard(
                                      course['image_url'] ?? '',
                                      course['title'] ?? 'No Title',
                                      '${course['duration'] ?? 0} hours',
                                      'RM ${course['price'] ?? 0}',
                                    ),
                                  );
                                },
                              )
                            : const Center(
                                child: Text(
                                  "No trending courses found.",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Colors.blue,
          currentIndex: _currentBannerIndex,
          onTap: (index) {
            setState(() {
              _currentBannerIndex = index; // Update the current index
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
              case 2:
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => ProfilePage(), // Replace with your profile page widget
                    transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                  ),
                );
                break;
            }
          },
          items: [
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

  Widget _buildCategoryItem(String title, String imageUrl) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(8),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(imageUrl),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCourseCard(String imagePath, String title, String hours, String price) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: imagePath.isNotEmpty
                    ? NetworkImage(imagePath)
                    : const AssetImage('assets/placeholder.png') as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          hours,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
