import 'package:flutter/material.dart';
import '../homepage.dart'; // Import the homepage.dart file
import 'package:mindspace/pages_course/course_info.dart'; // Import CourseInfoPage for navigation
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  List<String> categories = [];
  Set<String> selectedCategories = {}; // Track selected categories
  List<Map<String, dynamic>> filteredCourses = []; // Filtered course data
  bool _isLoading = false; // Loading indicator

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Fetch categories on initialization
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('category')
          .select('name');

      setState(() {
        categories = (response as List<dynamic>)
            .map((e) => e['name'].toString())
            .toList();
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _fetchCourses({List<String>? categories, int? minPrice, int? maxPrice}) async {
    setState(() {
      _isLoading = true;
    });
    try {
      var query = Supabase.instance.client.from('courses').select('*');

      // Apply category filter for multiple categories
      if (categories != null && categories.isNotEmpty) {
        final categoryIdsResponse = await Supabase.instance.client
            .from('category')
            .select('id, name')
            .filter('name', 'in', '(${categories.join(",")})'); // Corrected here
        final categoryIds = (categoryIdsResponse as List<dynamic>)
            .map((e) => e['id'])
            .toList();
        if (categoryIds.isNotEmpty) {
          query = query.filter('category_id', 'in', '(${categoryIds.join(",")})');
        }
      }

      // Apply price range filter
      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }
      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      final response = await query;
      setState(() {
        filteredCourses = (response as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      print('Error fetching courses: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              color: Colors.white, // Set background to white
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Filter",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Price Range (RM)",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "MIN",
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 16.0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          "-",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _maxPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "MAX",
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 16.0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Categories",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : GridView.builder(
                            shrinkWrap: true,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 3.5,
                            ),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              String category = categories[index];
                              bool isSelected = selectedCategories.contains(category);
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      selectedCategories.remove(category);
                                    } else {
                                      selectedCategories.add(category);
                                    }
                                  });
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? Colors.blue : Colors.grey,
                                    ),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 36),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                _minPriceController.clear();
                                _maxPriceController.clear();
                                selectedCategories.clear();
                              });
                              setState(() {
                                filteredCourses.clear();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color.fromARGB(255, 17, 0, 255)),
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Clear All",
                              style: TextStyle(color: Color.fromARGB(255, 17, 0, 255)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (selectedCategories.isEmpty &&
                                  _minPriceController.text.isEmpty &&
                                  _maxPriceController.text.isEmpty) {
                                setState(() {
                                  filteredCourses.clear();
                                });
                              } else {
                                _fetchCourses(
                                  categories: selectedCategories.toList(),
                                  minPrice: int.tryParse(_minPriceController.text),
                                  maxPrice: int.tryParse(_maxPriceController.text),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 17, 0, 255),
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Apply",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
        title: const Text(
          'Search',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: _showFilterModal,
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : filteredCourses.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.info, size: 50, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No courses available. Use the filter to search.',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: filteredCourses.length,
                          itemBuilder: (context, index) {
                            final course = filteredCourses[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CourseInfoPage(courseId: course['id']),
                                  ),
                                );
                              },
                              child: _buildTrendingCourseCard(
                                course['image_url'] ?? "assets/course-image.png",
                                course['title'],
                                "${course['duration']} hours",
                                "RM ${course['price']}",
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildTrendingCourseCard(
      String imagePath, String title, String duration, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              image: DecorationImage(
                image: NetworkImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
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
    );
  }
}
