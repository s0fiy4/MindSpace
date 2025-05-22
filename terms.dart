import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Terms And Conditions",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Introduction',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'MindSpace ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use the MindSpace App ("the App"), our education platform. By using the App, you consent to the data practices described in this policy. If you do not agree with the terms of this Privacy Policy, please do not access the App.',
            ),
            SizedBox(height: 20),
            Text(
              '2. Information We Collect',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '2.1 Personal Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              'When you register or use the App, we may collect personally identifiable information (PII), such as: \n- Name \n- Email address \n- Username and password \n- Phone number \n- Date of birth \n- Payment information (when applicable for subscription or service purchases).',
            ),
            SizedBox(height: 10),
            Text(
              '2.2 Non-Personal Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              'We may collect non-personally identifiable information that does not directly reveal your identity, such as: \n- Device information (device type, operating system, etc.) \n- Browser type \n- Usage data (app interactions, course progress, time spent on lessons) \n- IP address \n- Cookies and tracking technologies.',
            ),
            SizedBox(height: 10),
            Text(
              '2.3 User-Generated Content',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              'If you submit any content through the App, such as discussion posts, assignments, or messages, we may collect that content and associate it with your account.',
            ),
            SizedBox(height: 20),
            Text(
              '3. How We Use Your Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '- Provide and maintain the App. \n- Personalize user experience. \n- Manage your account. \n- Communicate with you. \n- Process payments. \n- Improve the App. \n- Ensure security.',
            ),
            SizedBox(height: 20),
            Text(
              '4. Sharing Your Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'We do not sell or rent your personal information. However, we may share your information with third parties in the following situations: \n- Service providers: We may share your data with third-party service providers who perform services on our behalf. \n- Legal obligations: We may disclose your personal information if required to do so by law. \n- Business transfers: In the event of a merger or acquisition, we may transfer your personal information.',
            ),
            SizedBox(height: 20),
            Text(
              '5. Cookies and Tracking Technologies',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'We use cookies and similar tracking technologies to track activity on the App and hold certain information. \n- Essential cookies: Necessary for the App to function properly. \n- Performance and analytics cookies: Help us understand how users interact with the App.',
            ),
            SizedBox(height: 20),
            Text(
              '6. Data Security',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'We take reasonable measures to protect your personal information from unauthorized access, misuse, or disclosure. However, please note that no method of transmission over the internet or electronic storage is 100% secure.',
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
