import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindspace/pages_payment/payment.dart';
import 'course.dart';

class CourseInfoPage extends StatefulWidget {
  final int courseId;

  const CourseInfoPage({Key? key, required this.courseId}) : super(key: key);

  @override
  _CourseInfoPageState createState() => _CourseInfoPageState();
}

class _CourseInfoPageState extends State<CourseInfoPage> {
  final supabase = Supabase.instance.client;
  bool _isExpanded = false;
  VideoPlayerController? _controller;
  bool _showControls = true;
  Timer? _hideTimer;
  double _currentPosition = 0.0; // Track the current position for the slider

  String title = "Loading...";
  String level = "";
  String categoryName = "";
  int chapters = 0;
  int duration = 0;
  bool certificate = false;
  double price = 0.0;
  String imageUrl = "";
  String videoUrl = "";
  String description = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCourseDetails();
  }

  Future<void> _fetchCourseDetails() async {
    setState(() {
      isLoading = true;
      // Dispose the previous video controller if it exists
      _controller?.dispose();
      _controller = null;
    });
    try {
      final response = await supabase
          .from('courses')
          .select('title, level, chapters, duration, certificate, price, image_url, "Ads Video", description, category(name)')
          .eq('id', widget.courseId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          title = response['title'] ?? "No Title";
          level = response['level'] ?? "";
          categoryName = response['category']['name'] ?? "";
          chapters = response['chapters'] ?? 0;
          duration = response['duration'] ?? 0;
          certificate = response['certificate'] ?? false;
          price = response['price'] ?? 0.0;
          imageUrl = response['image_url'] ?? "assets/placeholder.png";
          videoUrl = response['Ads Video'] ?? "";
          description = response['description'] ?? "";
        });

        if (videoUrl.isNotEmpty) {
          _initializeVideoPlayer(videoUrl);
        }
      }
    } catch (error) {
      print('Error fetching course details: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _initializeVideoPlayer(String url) {
    _controller = VideoPlayerController.network(url)
      ..initialize().then((_) {
        setState(() {});
      }).catchError((error) {
        print('Error initializing video player: $error');
      });

    // Update the slider value as the video plays
    _controller?.addListener(() {
      setState(() {
        _currentPosition = _controller?.value.position.inSeconds.toDouble() ?? 0.0;
      });
    });
  }

  Future<void> _checkIfUserPurchasedCourse() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('user_courses')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', widget.courseId)
          .maybeSingle();

      if (response != null) {
        // User has purchased the course
        final result = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Course Already Purchased"),
            content: const Text("You have purchased this course. Go to My Course?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Yes"),
              ),
            ],
          ),
        );

        if (result == true) {
          _pauseVideoIfPlaying();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CoursePage()),
          );
        }
      } else {
        // User has not purchased the course
        _pauseVideoIfPlaying();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPage(courseId: widget.courseId),
          ),
        );
      }
    } catch (error) {
      print('Error checking course purchase: $error');
    }
  }

  void _startHideControlsTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _showControls = false;
      });
    });
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller != null) {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
      }
      _showControls = true;
      _startHideControlsTimer();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _pauseVideoIfPlaying() {
    if (_controller != null && _controller!.value.isPlaying) {
      _controller!.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Course Details',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20, // Optional: Adjust font size if needed
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCourseDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _togglePlayPause,
                child: Stack(
                  children: [
                    _controller != null && _controller!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio,
                            child: VideoPlayer(_controller!),
                          )
                        : videoUrl.isNotEmpty
                            ? Container(
                                height: 240,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : const SizedBox(),
                    if (_showControls && videoUrl.isNotEmpty)
                      Positioned.fill(
                        child: Center(
                          child: IconButton(
                            icon: Icon(
                              _controller != null && _controller!.value.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              size: 60,
                              color: Colors.white,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_controller != null && _controller!.value.isInitialized)
                Column(
                  children: [
                    Slider(
                      value: _currentPosition,
                      max: _controller?.value.duration.inSeconds.toDouble() ?? 0.0,
                      onChanged: (value) {
                        setState(() {
                          _currentPosition = value;
                          _controller?.seekTo(Duration(seconds: value.toInt()));
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_controller!.value.position),
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            _formatDuration(_controller!.value.duration),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (level.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          level,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (categoryName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Description",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isExpanded
                          ? description
                          : "${description.substring(0, description.length > 100 ? 100 : description.length)}...",
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Text(
                        _isExpanded ? "Read Less" : "Read More",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildInfoTile(Icons.menu_book, "$chapters Chapters"),
                    _buildInfoTile(Icons.timer, "$duration hours"),
                    _buildInfoTile(Icons.language, "English"),
                    if (certificate)
                      _buildInfoTile(Icons.card_membership, "Certificate"),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Price",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "RM$price",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    Center(
                      child: ElevatedButton(
                        onPressed: _checkIfUserPurchasedCourse,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 17, 0, 255),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 100),
                        ),
                        child: const Text(
                          "Buy Course",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 46),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String text) {
    return Container(
      width: 150,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: const Color.fromARGB(255, 17, 0, 255)),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
