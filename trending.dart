import 'package:flutter/material.dart';
import 'package:mindspace/pages_course/course_info.dart'; // Import CourseInfoPage for navigation
import 'package:supabase_flutter/supabase_flutter.dart';

class TrendingPage extends StatefulWidget {
  const TrendingPage({Key? key}) : super(key: key);

  @override
  _TrendingPageState createState() => _TrendingPageState();
}

class _TrendingPageState extends State<TrendingPage> {
  final supabase = Supabase.instance.client; // Supabase client
  List<Map<String, dynamic>> trendingCourses = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTrendingCourses();
  }

  Future<void> _fetchTrendingCourses() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch data with JOIN SQL (trending joined with courses)
      final response = await supabase
          .from('trending')
          .select('courses(id, title, duration, price, image_url, category_id)');

      // ignore: unnecessary_null_comparison
      if (response != null) {
        setState(() {
          trendingCourses = List<Map<String, dynamic>>.from(response);
        });
      } else {
        print('No trending courses found.');
      }
    } catch (error) {
      print('Error fetching trending courses: $error');
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
        title: const Text(
          'Trending Course',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTrendingCourses, // Refresh feature
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : trendingCourses.isNotEmpty
                  ? ListView.builder(
                      itemCount: trendingCourses.length,
                      itemBuilder: (context, index) {
                        final course = trendingCourses[index]['courses'];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CourseInfoPage(
                                  courseId: course['id'], // Pass category ID
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
                        'No trending courses available.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildTrendingCourseCard(
    String imagePath, String title, String duration, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26.0), // Add bottom padding for spacing
      child: Container(
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
                  image: imagePath.isNotEmpty
                      ? NetworkImage(imagePath)
                      : const AssetImage('assets/placeholder.png')
                          as ImageProvider,
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
                        duration,
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
      ),
    );
  }
}
