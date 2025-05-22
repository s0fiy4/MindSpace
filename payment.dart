// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:mindspace/pages_payment/payment_method.dart';

class PaymentPage extends StatelessWidget {
  final int courseId;

  const PaymentPage({Key? key, required this.courseId}) : super(key: key);

  Future<Map<String, dynamic>> _fetchCourseDetails(int courseId) async {
    final supabase = Supabase.instance.client;

    // Fetch course details
    final courseResponse = await supabase
        .from('courses')
        .select('title, chapters, certificate, price')
        .eq('id', courseId)
        .maybeSingle();

    if (courseResponse == null) {
      throw Exception("Course not found");
    }

    // Fetch user details
    final userResponse = await supabase
        .from('profiles')
        .select('first_name, last_name, id')
        .eq('id', supabase.auth.currentUser!.id)
        .maybeSingle();

    if (userResponse == null) {
      throw Exception("User not found");
    }

    return {
      'course': courseResponse,
      'user': {
        'first_name': userResponse['first_name'],
        'last_name': userResponse['last_name'],
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      appBar: AppBar(
        backgroundColor: Colors.white, // Set AppBar background color to white
        elevation: 0,
        title: const Text(
          "Purchase Review",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchCourseDetails(courseId);
        },
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchCourseDetails(courseId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData) {
              return const Center(child: Text("No data available"));
            }

            final course = snapshot.data!['course'];
            final user = snapshot.data!['user'];

            final String userName =
                "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".trim();
            final String title = course['title'] ?? 'N/A';
            final int chapters = course['chapters'] ?? 0;
            final bool certificate = course['certificate'] ?? false;
            final double price = course['price'] ?? 0.0;
            final String purchaseDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 0),
                    // Name section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(userName),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // Course information
                    const Text("Course", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(title),
                    const SizedBox(height: 36),

                    // Including section
                    const Text("Including", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 3,
                        ),
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.menu_book, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text("$chapters Chapter${chapters > 1 ? 's' : ''}"),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.play_circle_fill, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text("HD Video Quality"),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.card_membership, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text("Certificate"),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text("Quiz"),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 44),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Purchase details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Purchase Date", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(purchaseDate),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Price", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("RM ${price.toStringAsFixed(2)}"),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Total price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Price", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("RM ${price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 74),

                    // Continue button
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentMethodPage(courseId: courseId),
                            ),
                          );
                        },
                        child: const Text(
                          "Continue",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 17, 0, 255),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 100),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
