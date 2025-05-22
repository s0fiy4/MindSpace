import 'package:flutter/material.dart';
// ignore: unused_import
import 'ongoing_course.dart';
import 'congrats.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QuizScreen(quizId: 1), // Example quizId passed here
    );
  }
}

class QuizScreen extends StatefulWidget {
  final int quizId;

  const QuizScreen({Key? key, required this.quizId}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final List<Map<String, dynamic>> _questions = [
    {
      "question": "Which programming language is used to build Flutter applications?",
      "options": ["Kotlin", "Dart", "Java", "Go"],
      "selectedOption": -1, // Track selected option
    },
    {
      "question": "Who developed the Flutter Framework and continues to maintain it today?",
      "options": ["Google", "Facebook", "Microsoft", "Apple"],
      "selectedOption": -1, // Track selected option
    },
  ];

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  String quizTitle = "Loading..."; // Placeholder for quiz title

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _fetchQuizTitle(); // Fetch quiz title on init
    print("Received quizId: ${widget.quizId}"); // Debug log for quizId
  }

  Future<void> _fetchQuizTitle() async {
    try {
      final response = await Supabase.instance.client
          .from('quiz')
          .select('title')
          .eq('id', widget.quizId)
          .maybeSingle();

      if (response != null && response['title'] != null) {
        setState(() {
          quizTitle = response['title'];
        });
      }
    } catch (error) {
      print("Error fetching quiz title: $error");
    }
  }

  Future<void> _initializeNotifications() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification Clicked: ${details.payload}');
      },
    );

    await _requestNotificationPermission();
    _createNotificationChannel();
  }

  Future<void> _requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.request();
    if (status.isGranted) {
      print("Notification permission granted!");
    } else {
      print("Notification permission denied!");
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'quiz_channel', // Channel ID
      'Quiz Notifications', // Name
      description: 'This is the quiz notification channel.',
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'quiz_channel', // Channel ID
      'Quiz Notifications', // Channel name
      channelDescription: 'This is the quiz notification channel.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Congrats!', // Title
      'You have earned a new digital certificate.', // Body
      platformDetails,
    );
  }

  /// Shows a confirmation dialog for the back button
  Future<bool> _showBackButtonConfirmationDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Back Button"),
        content: const Text("Are you sure you want to leave the quiz via the back button?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Cancel exit
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Confirm exit
            child: const Text("Exit"),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      Navigator.of(context).pop(); // Navigate back to the previous page

      return true;
    }
    return false; // Prevent back navigation if not confirmed
  }

  /// Shows a confirmation dialog for the cross button
  Future<void> _showCrossButtonConfirmationDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Exit Quiz"),
        content: const Text("Are you sure you want to leave the quiz via the cross button?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Dismiss dialog
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss dialog
              Navigator.of(context).pop(); // Navigate back to previous page
            },
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog for the finish button
  Future<void> _showFinishConfirmationDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Finish Quiz"),
        content: const Text("Are you sure you want to finish the quiz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(), // Close dialog
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // Save the context before popping
              final navigatorContext = context;

              Navigator.of(dialogContext).pop(); // Close dialog
              await _insertOrSkipUserCert(); // Check and insert new record
              await _showNotification(); // Show notification

              // Navigate to CongratsPage
              Navigator.pushReplacement(
                // ignore: use_build_context_synchronously
                navigatorContext,
                MaterialPageRoute(builder: (context) => const CongratsPage()),
              );
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }


  Future<void> _insertOrSkipUserCert() async {
    try {
      // Replace this with your actual user_id from authentication/session
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception("User not logged in");
      }

      // Check if the record already exists
      final existingRecord = await Supabase.instance.client
          .from('user_cert')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', widget.quizId)
          .maybeSingle();

      if (existingRecord == null) {
        // Insert a new record if none exists
        await Supabase.instance.client.from('user_cert').insert({
          'user_id': userId,
          'course_id': widget.quizId,
          'created_at': DateTime.now().toIso8601String(),
        });
        print("New record inserted into user_cert");
      } else {
        print("Record already exists, skipping insert");
      }
    } catch (error) {
      // ignore: avoid_print
      print("Error inserting or skipping user_cert: $error");
    }
  }


  @override
  Widget build(BuildContext context) {
    final labels = ["A", "B", "C", "D"]; // Option labels

    return WillPopScope(
      onWillPop: _showBackButtonConfirmationDialog, // Handle back button
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: _showCrossButtonConfirmationDialog, // Handle cross button
          ),
          title: Text(
            "Quiz", // Placeholder app bar title
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                quizTitle, // Quiz title fetched from the database
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                
              ),
              const SizedBox(height: 16), // Spacing after title
              ..._questions.asMap().entries.map((entry) {
                final questionIndex = entry.key;
                final question = entry.value;
                final options = question["options"] as List<String>;
                final selectedOption = question["selectedOption"];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (questionIndex > 0) const SizedBox(height: 32), // Spacing between questions
                    Text(
                      "${questionIndex + 1}. ${question['question']}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...options.asMap().entries.map((optionEntry) {
                      final optionIndex = optionEntry.key;
                      final option = optionEntry.value;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            question["selectedOption"] = optionIndex;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16.0,
                            horizontal: 16.0,
                          ),
                          decoration: BoxDecoration(
                            color: selectedOption == optionIndex
                                ? Colors.blue
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "${labels[optionIndex]}. ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: selectedOption == optionIndex
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: selectedOption == optionIndex
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
              const SizedBox(height: 32), // Spacing before finish button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                onPressed: _showFinishConfirmationDialog, // Confirmation for finish button
                child: const Text(
                  "Finish",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
