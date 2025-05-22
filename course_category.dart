import 'package:flutter/material.dart';
import 'package:mindspace/pages_course/course_info.dart'; // Import CourseInfoPage for navigation
import 'package:supabase_flutter/supabase_flutter.dart';

class CourseCategoryPage extends StatefulWidget {
  final String categoryId; // Get id from the previous page

  const CourseCategoryPage({Key? key, required this.categoryId}) : super(key: key);

  @override
  _CourseCategoryPageState createState() => _CourseCategoryPageState();
}

class _CourseCategoryPageState extends State<CourseCategoryPage> {
  final supabase = Supabase.instance.client; // Supabase client
  List<Map<String, dynamic>> courses = [];
  String categoryTitle = ""; // Title for the category
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCategoryAndCourses();
  }

  Future<void> _fetchCategoryAndCourses() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Fetch category title
      final categoryResponse = await supabase
          .from('category')
          .select('name')
          .eq('id', widget.categoryId)
          .maybeSingle();

      if (categoryResponse != null) {
        setState(() {
          categoryTitle = categoryResponse['name'] ?? "Category";
        });
      }

      // Fetch courses within the category
      final coursesResponse = await supabase
          .from('courses')
          .select('id, title, duration, price, image_url')
          .eq('category_id', widget.categoryId);

      // ignore: unnecessary_null_comparison
      if (coursesResponse != null) {
        setState(() {
          courses = List<Map<String, dynamic>>.from(coursesResponse);
        });
      }
    } catch (error) {
      print('Error fetching category or courses: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous page
          },
        ),
        title: Text(
          categoryTitle,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCategoryAndCourses,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : courses.isNotEmpty
                  ? ListView.builder(
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CourseInfoPage(
                                  courseId: course['id'], // Pass courseId here
                                ),
                              ),
                            );
                          },
                          child: _buildCourseCard(
                            course['image_url'] ?? '', // Handle null image URL
                            course['title'] ?? 'No Title', // Handle null title
                            course['duration'] ?? 0, // Handle null duration
                            course['price'] != null ? "RM ${course['price']}" : "No Price", // Handle null price
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'No courses available.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildCourseCard(
      String imagePath, String title, int duration, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              image: DecorationImage(
                image: imagePath.isNotEmpty ? NetworkImage(imagePath) : const AssetImage('assets/placeholder.png') as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Course Info
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.black),
                    const SizedBox(width: 4),
                    Text(
                      '$duration hours', // Convert int to String and append "hours"
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        price,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
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
