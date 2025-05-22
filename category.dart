import 'package:flutter/material.dart';
import '../pages_home/course_category.dart'; // Import CourseCategoryPage for navigation
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final supabase = Supabase.instance.client; // Supabase client
  List<Map<String, dynamic>> categories = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await supabase
          .from('category') // Ensure this matches your Supabase table name
          .select('id, name, image_url');

      // ignore: unnecessary_null_comparison
      if (response != null) {
        print('Fetched categories: $response');
        setState(() {
          categories = List<Map<String, dynamic>>.from(response);
        });
      } else {
        print('No categories found');
      }
    } catch (error) {
      print('Error fetching categories: $error');
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
          'Category',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCategories,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : GridView.count(
                  crossAxisCount: 2, // Two items per row
                  crossAxisSpacing: 16, // Horizontal space between items
                  mainAxisSpacing: 16, // Vertical space between items
                  children: categories.isNotEmpty
                      ? categories.map((category) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CourseCategoryPage(categoryId: category['id']),
                                ),
                              );
                            },
                            child: _buildCategoryItem(
                              category['name'],
                              category['image_url'],
                            ),
                          );
                        }).toList()
                      : [
                          const Center(
                            child: Text(
                              'No categories available.',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  // Helper function to build category items
  Widget _buildCategoryItem(String title, String imageUrl) {
    return Container(
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
          const SizedBox(height: 10), // Space between icon and text
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
