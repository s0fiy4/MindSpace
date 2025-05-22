import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mindspace/homepage.dart';
import 'package:mindspace/pages_profile/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ongoing_course.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({Key? key}) : super(key: key);

  @override
  _CoursePageState createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 1;
  bool _isLoading = false;
  List<dynamic> _ongoingCourses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOngoingCourses();
  }

  Future<void> _fetchOngoingCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _ongoingCourses = [];
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('user_courses')
          .select('course_id, courses(title, duration, image_url)')
          .eq('user_id', userId);

      // ignore: unnecessary_null_comparison, unnecessary_type_check
      if (response != null && response is List) {
        setState(() {
          _ongoingCourses = response;
        });
      } else {
        setState(() {
          _ongoingCourses = [];
        });
      }
    } catch (error) {
      print('Error fetching courses: $error');
      setState(() {
        _ongoingCourses = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Exit App"),
            content: const Text("Are you sure you want to exit the app?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  exit(0);
                },
                child: const Text("Exit"),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Course',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: "Ongoing"),
              Tab(text: "Completed"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            RefreshIndicator(
              onRefresh: _fetchOngoingCourses,
              child: _buildOngoingCourses(),
            ),
            RefreshIndicator(
              onRefresh: _fetchOngoingCourses, // Adding refresh on the completed tab as well
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: _buildNoCourses(
                    title: "No Completed Courses Yet!",
                    description: "You have not completed any courses at this time.",
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index; // Update the current index
            });

            // Navigate without animation
            switch (index) {
              case 0:
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => HomePage(), // Replace with your home page widget
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

          selectedItemColor: Colors.blue,
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

  Widget _buildOngoingCourses() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ongoingCourses.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchOngoingCourses,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _buildNoCourses(
              title: "No Courses Enrolled Yet!",
              description: "You have not enrolled in any courses yet.",
            ),
          ),
        ),
      );
    }

    // This part builds the cards if there are ongoing courses
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _ongoingCourses.length,
      itemBuilder: (context, index) {
        final course = _ongoingCourses[index]['courses'];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OngoingCoursePage(courseId: _ongoingCourses[index]['course_id']),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    course['image_url'],
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  course['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${course['duration']} hours",
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: LinearProgressIndicator(
                          value: 0.5,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          minHeight: 10.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "5/10 hours",
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OngoingCoursePage(courseId: _ongoingCourses[index]['course_id']),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        "Start",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoCourses({required String title, required String description}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.school,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
