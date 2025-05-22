import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "About Us",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome to Mindspace, your personalized learning hub designed to empower learners of all ages and backgrounds. "
              "Our mission is to make high-quality education accessible, engaging, and tailored to fit your individual learning journey.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              "Who We Are",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "At Mindspace, we believe that learning should be flexible, interactive, and driven by curiosity. Whether you're a student looking to improve your skills, a professional seeking career advancement, or simply a lifelong learner, we offer a wide range of courses, tools, and resources to help you achieve your goals. "
              "Our app combines cutting-edge technology with top-tier educational content to ensure that you have the best learning experience, anytime, anywhere.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              "Our Mission",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Our mission is to democratize education by breaking down barriers to learning. We aim to provide a platform where learners can:",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const BulletPoint(
              text: "Access high-quality content created by experts in various fields.",
            ),
            const BulletPoint(
              text: "Learn at their own pace with interactive lessons, quizzes, and assessments.",
            ),
            const BulletPoint(
              text: "Earn certificates upon course completion to showcase your achievements.",
            ),
            const SizedBox(height: 20),
            const Text(
              "Why Choose Us?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const BulletPoint(
              text: "Flexible Learning: Learn on your own schedule, with content that is available 24/7.",
            ),
            const BulletPoint(
              text: "Expert Instructors: Our content is developed by industry leaders and educators with years of experience.",
            ),
            const BulletPoint(
              text: "Affordable: We strive to make education accessible with free and affordable course options.",
            ),
            const BulletPoint(
              text: "Supportive Community: Connect with fellow learners and educators to enhance your experience.",
            ),
            const SizedBox(height: 20),
            const Text(
              "Join Us on the Journey",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "At Mindspace, we are passionate about education and committed to helping you unlock your full potential. Whether you're looking to learn something new, advance your career, or simply explore new subjects, we're here to support you every step of the way.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              "Download Mindspace today, and take the next step in your learning journey!",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white, // Set background color to white
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;

  const BulletPoint({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "\u2022",
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
