import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cert.dart'; // Import the cert.dart file

class MyCertificationsPage extends StatefulWidget {
  const MyCertificationsPage({Key? key}) : super(key: key);

  @override
  _MyCertificationsPageState createState() => _MyCertificationsPageState();
}

class _MyCertificationsPageState extends State<MyCertificationsPage> {
  List<Map<String, dynamic>> userCertificates = [];
  String? iconUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserCertificates();
    fetchIconUrl();
  }

  Future<void> fetchIconUrl() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('pdf_resources') // Table name containing the icon URL
        .select('icon_url')
        .limit(1)
        .single();

    // ignore: unnecessary_null_comparison
    if (response != null && response['icon_url'] != null) {
      setState(() {
        iconUrl = response['icon_url'];
      });
    }
  }

  Future<void> fetchUserCertificates() async {
    setState(() {
      isLoading = true;
    });

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId != null) {
      final response = await supabase
          .from('user_cert')
          .select('course_id, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // ignore: unnecessary_null_comparison
      if (response != null) {
        final coursesResponse = await supabase
            .from('courses')
            .select('id, title, certificate, created_at');

        // ignore: unnecessary_null_comparison
        if (coursesResponse != null) {
          List<Map<String, dynamic>> certificates = [];
          for (var cert in response) {
            final course = coursesResponse.firstWhere(
                (course) => course['id'] == cert['course_id'],
                orElse: () => <String, dynamic>{}); // Return an empty map instead of null

            if (course.isNotEmpty && course['certificate'] == true) {
              certificates.add({
                'title': course['title'],
                'obtained_at': cert['created_at'],
              });
            }
          }

          setState(() {
            userCertificates = certificates;
          });
        }
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Certificate",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous page
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchIconUrl();
          await fetchUserCertificates();
        },
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : userCertificates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.school,
                          size: 80,
                          color: Colors.blue,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No certificate available for now.",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Go enroll to courses now",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
                      itemCount: userCertificates.length,
                      itemBuilder: (context, index) {
                        final cert = userCertificates[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const CertViewerPage()),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
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
                                Container(
                                  height: 80,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    image: iconUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(iconUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: iconUrl == null
                                      ? const Icon(
                                          Icons.insert_drive_file,
                                          color: Colors.blue,
                                          size: 40,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cert['title'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Obtained on ${cert['obtained_at']}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
      backgroundColor: Colors.white,
    );
  }
