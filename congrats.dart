import 'package:flutter/material.dart';
import '../homepage.dart'; // Adjust the import path based on your project structure

class CongratsPage extends StatelessWidget {
  const CongratsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to homepage when back button is pressed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        return false; // Disable default back button behavior
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Image Section
              Image.asset(
                'assets/congrats.png', // Ensure the image path is correct
                height: 200, // Adjust as necessary
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              // Congratulations Text
              const Text(
                "Congratulations!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              // Description Text
              const Text(
                "You have earned a digital certificate for this course.\nYou can view it in your profile section.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              // Back to Home Button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  "Back to Home",
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
