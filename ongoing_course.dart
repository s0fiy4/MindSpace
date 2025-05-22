// ignore_for_file: unused_import

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mindspace/pages_course/pdf_viewer.dart';
import 'package:mindspace/pages_course/quiz.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'course.dart';
import 'video_player.dart'; // Ensure to import your VideoPlayerPage

class OngoingCoursePage extends StatefulWidget {
  final int courseId;

  const OngoingCoursePage({Key? key, required this.courseId}) : super(key: key);

  @override
  _OngoingCoursePageState createState() => _OngoingCoursePageState();
}

class _OngoingCoursePageState extends State<OngoingCoursePage> {
  final supabase = Supabase.instance.client;
  bool _isExpanded = false;
  VideoPlayerController? _controller;
  bool _showControls = true;
  Timer? _hideTimer;
  double _currentPosition = 0.0;

  String title = "Loading...";
  String level = "";
  String categoryName = "";
  int chaptersCount = 0;
  int duration = 0;
  bool certificate = false;
  String imageUrl = "";
  String videoUrl = "";
  bool isLoading = false;
  String description = "";
  List<dynamic> chapters = [];
  Map<String, List<dynamic>> videosByChapter = {};
  final Map<String, bool> _chaptersExpanded = {};
  bool _lectureNotesExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchCourseDetails();
    _fetchChapters();
    _fetchPDFNotes();
    _fetchQuizzes(); // Fetch quizzes
  }

  Future<void> _fetchCourseDetails() async {
    setState(() {
      isLoading = true;
      _controller?.dispose();
      _controller = null;
    });
    try {
      final response = await supabase
          .from('courses')
          .select('title, level, chapters, duration, certificate, image_url, "Ads Video", category(name), description')
          .eq('id', widget.courseId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          title = response['title'] ?? "No Title";
          level = response['level'] ?? "";
          categoryName = response['category']['name'] ?? "";
          chaptersCount = response['chapters'] ?? 0;
          duration = response['duration'] ?? 0;
          certificate = response['certificate'] ?? false;
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

  Future<void> _fetchChapters() async {
    try {
      final response = await supabase
          .from('chapter')
          .select('id, title')
          .eq('course_id', widget.courseId);

      setState(() {
        chapters = response;
        for (var chapter in chapters) {
          _chaptersExpanded[chapter['title']] = false;
          videosByChapter[chapter['title']] = [];
          _fetchVideosForChapter(chapter['id'], chapter['title']);
        }
      });
    } catch (error) {
      print('Error fetching chapters: $error');
    }
  }

  Future<void> _fetchVideosForChapter(int chapterId, String chapterTitle) async {
    try {
      final response = await supabase
          .from('video')
          .select('id, title, video_url')
          .eq('chapter_id', chapterId);

      setState(() {
        videosByChapter[chapterTitle] = response;
      });
    } catch (error) {
      // ignore: avoid_print
      print('Error fetching videos for chapter $chapterId: $error');
    }
  }

  List<dynamic> quizzes = [];
  bool _quizExpanded = false;

  Future<void> _fetchQuizzes() async {
    try {
      final response = await supabase
          .from('quiz')
          .select('id, title')
          .eq('course_id', widget.courseId);

      setState(() {
        quizzes = response;
      });
    } catch (error) {
      print('Error fetching quizzes: $error');
    }
  }

  void _initializeVideoPlayer(String url) {
    _controller = VideoPlayerController.network(url)
      ..initialize().then((_) {
        setState(() {});
      }).catchError((error) {
        print('Error initializing video player: $error');
      });

    _controller?.addListener(() {
      setState(() {
        _currentPosition = _controller?.value.position.inSeconds.toDouble() ?? 0.0;
      });
    });
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

  List<dynamic> pdfNotes = [];
Map<String, bool> _notesExpanded = {};

Future<void> _fetchPDFNotes() async {
  try {
    final response = await supabase
        .from('pdf')
        .select('id, title')
        .eq('course_id', widget.courseId);

    setState(() {
      pdfNotes = response;
      for (var note in pdfNotes) {
        _notesExpanded[note['title']] = false;
      }
    });
  } catch (error) {
    print('Error fetching PDF notes: $error');
  }
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
            fontSize: 20,
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
        onRefresh: () async {
          await _fetchCourseDetails();
          await _fetchChapters();
        },
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
                    _buildInfoTile(Icons.menu_book, "$chaptersCount Chapters"),
                    _buildInfoTile(Icons.timer, "$duration hours"),
                    _buildInfoTile(Icons.language, "English"),
                    if (certificate)
                      _buildInfoTile(Icons.card_membership, "Certificate"),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (chapters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Chapters",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...chapters.map((chapter) => _buildChapterSection(
                            title: chapter['title'],
                            lessons: videosByChapter[chapter['title']] ?? [],
                          )),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              if (pdfNotes.isNotEmpty) _buildLectureNotesSection(),
              const SizedBox(height: 6),
              if (quizzes.isNotEmpty) _buildQuizSection(),
              const SizedBox(height: 56),
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

  Widget _buildChapterSection({
    required String title,
    required List<dynamic> lessons,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _chaptersExpanded[title] = !(_chaptersExpanded[title] ?? false);
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  _chaptersExpanded[title] ?? false ? Icons.remove : Icons.add,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
        if (_chaptersExpanded[title] ?? false)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: lessons.map((lesson) => _buildLessonItem(lesson['title'], lesson['id'])).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLessonItem(String title, int videoId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          _pauseVideoIfPlaying();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerPage(videoId: videoId),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
            const Icon(
              Icons.play_arrow,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureNotesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _lectureNotesExpanded = !_lectureNotesExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Lecture Notes",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _lectureNotesExpanded ? Icons.remove : Icons.add,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          if (_lectureNotesExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                children: pdfNotes.map((note) => _buildNoteItem(note)).toList(),
              ),
            ),
        ],
      ),
    );
  }


 Widget _buildNoteItem(Map<String, dynamic> note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          _pauseVideoIfPlaying();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerPage(pdfId: note['id']),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              note['title'] ?? 'Untitled',
              style: const TextStyle(fontSize: 14),
            ),
            const Icon(
              Icons.picture_as_pdf,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _quizExpanded = !_quizExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Quiz",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _quizExpanded ? Icons.remove : Icons.add,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          if (_quizExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                children: quizzes.map((quiz) => _buildQuizItem(quiz)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuizItem(Map<String, dynamic> quiz) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Add spacing between rows
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                quiz['title'],
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade100, // Light blue button background
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                elevation: 0,
              ),
              onPressed: () {
                _showQuizConfirmation(quiz['id']);
              },
              child: const Text(
                "Take Quiz",
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 0, 55, 255), // Text color matches button theme
                  
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showQuizConfirmation(int quizId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Take the quiz now?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pauseVideoIfPlaying();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(quizId: quizId),
                ),
              );
            },
            child: const Text("Yes"),
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
