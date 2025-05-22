import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VideoPlayerPage extends StatefulWidget {
  final int videoId;

  const VideoPlayerPage({Key? key, required this.videoId}) : super(key: key);

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  bool _isExpanded = false; // Track if the description is expanded
  VideoPlayerController? _videoController;
  bool _showControls = true;
  Duration _currentPosition = Duration.zero;
  bool _isFullScreen = false;
  String videoTitle = "";
  String videoDescription = "";
  String videoUrl = "";

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchVideoDetails();
  }

  Future<void> _fetchVideoDetails() async {
    try {
      final response = await supabase
          .from('video')
          .select('title, description, video_url')
          .eq('id', widget.videoId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          videoTitle = response['title'] ?? "No Title";
          videoDescription =
              response['description'] ?? "No Description Available";
          videoUrl = response['video_url'] ?? "";
        });

        if (videoUrl.isNotEmpty) {
          _initializeVideoPlayer(videoUrl);
        }
      }
    } catch (error) {
      print('Error fetching video details: $error');
    }
  }

  void _initializeVideoPlayer(String url) {
    _videoController = VideoPlayerController.network(url)
      ..addListener(() {
        if (mounted) {
          setState(() {
            _currentPosition =
                _videoController?.value.position ?? Duration.zero;
          });
        }
      })
      ..initialize().then((_) {
        if (mounted) {
          setState(() {}); // Refresh the UI when video is initialized
        }
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoController != null && _videoController!.value.isPlaying) {
        _videoController?.pause();
        _showControls = true;
      } else {
        _videoController?.play();
        _showControls = false;

        // Auto-hide controls after 3 seconds if playing
        Future.delayed(const Duration(seconds: 3), () {
          if (_videoController?.value.isPlaying ?? false) {
            setState(() {
              _showControls = false;
            });
          }
        });
      }
    });
  }

  void _enterFullScreen() {
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    setState(() {
      _isFullScreen = true;
    });
  }

  void _exitFullScreen() {
    // Set portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    setState(() {
      _isFullScreen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: const Text(
                'Video Player',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
      body: WillPopScope(
        // Handle back button to exit full screen
        onWillPop: () async {
          if (_isFullScreen) {
            _exitFullScreen();
            return false; // Prevent the back button from closing the page
          }
          return true; // Allow normal back behavior
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24), // Add spacing to push video lower
            Flexible(
              // Adjusts video size to prevent overflow in landscape mode
              child: Stack(
                children: [
                  if (_videoController != null &&
                      _videoController!.value.isInitialized)
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: AspectRatio(
                        aspectRatio: _isFullScreen
                            ? 16 / 9 // Smaller aspect ratio for landscape mode
                            : _videoController!.value.aspectRatio, // Default for portrait
                        child: Stack(
                          children: [
                            VideoPlayer(_videoController!),
                            if (_showControls)
                              Positioned(
                                // Play button position adjusted for landscape mode
                                top: _isFullScreen ? 150 : 0,
                                bottom: _isFullScreen ? null : 0,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Icon(
                                    _videoController!.value.isPlaying
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_fill,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (_isFullScreen)
                              Positioned(
                                // Slider inside video in landscape mode
                                bottom: 50,
                                left: 16,
                                right: 16,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.purple,
                                    inactiveTrackColor: Colors.purple.shade100,
                                    thumbColor: Colors.purple,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 8),
                                    overlayColor: Colors.purple.withOpacity(0.2),
                                    trackHeight: 4,
                                  ),
                                  child: Slider(
                                    value: _currentPosition.inSeconds.toDouble(),
                                    max: _videoController!.value.duration.inSeconds
                                        .toDouble(),
                                    onChanged: (value) {
                                      _videoController?.seekTo(
                                        Duration(seconds: value.toInt()),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            if (_isFullScreen)
                              Positioned(
                                // Fullscreen exit button inside video
                                bottom: 10,
                                right: 16,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.fullscreen_exit,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: _exitFullScreen,
                                ),
                              ),
                            if (!_isFullScreen)
                              Positioned(
                                bottom: 10,
                                right: 16,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: _enterFullScreen,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (_videoController == null ||
                      !_videoController!.value.isInitialized)
                    const Center(
                      child:
                          CircularProgressIndicator(), // Show a loading indicator until initialized
                    ),
                ],
              ),
            ),
            if (!_isFullScreen) ...[
              // Portrait mode: Slider remains outside video
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.purple,
                  inactiveTrackColor: Colors.purple.shade100,
                  thumbColor: Colors.purple,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayColor: Colors.purple.withOpacity(0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _currentPosition.inSeconds.toDouble(),
                  max: _videoController?.value.duration.inSeconds.toDouble() ??
                      0.0,
                  onChanged: (value) {
                    _videoController?.seekTo(
                      Duration(seconds: value.toInt()),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _formatDuration(_currentPosition),
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _formatDuration(
                          _videoController?.value.duration ??
                              Duration.zero),
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchVideoDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            videoTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Description",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isExpanded
                                ? videoDescription
                                : "${videoDescription.substring(0, videoDescription.length > 100 ? 100 : videoDescription.length)}...",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black),
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
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
