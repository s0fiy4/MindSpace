import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mindspace/pages_payment/payment_success.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({Key? key}) : super(key: key);

  @override
  _PaymentMethodPageState createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String? _selectedMethod = "PayPal"; // Default selected payment method
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
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
      'payment_channel', // ID
      'Payment Notifications', // Name
      description: 'This is the payment notification channel.',
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'payment_channel', // Channel ID
      'Payment Notifications', // Channel name
      channelDescription: 'This is the payment notification channel.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Payment Success', // Title
      'Your payment has been successfully processed.', // Body
      platformDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Payment Method",
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              "Payment Method",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _buildPaymentOption(
            title: "Credit Card",
            subtitle: "",
            image: "assets/visa_mastercard.png",
            value: "Credit Card",
          ),
          _buildPaymentOption(
            title: "PayPal",
            subtitle: "",
            image: "assets/paypal_logo.png",
            value: "PayPal",
          ),
          _buildPaymentOption(
            title: "Apple Pay",
            subtitle: "",
            image: "assets/apple_pay_logo.png",
            value: "Apple Pay",
          ),
          const Spacer(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Purchase Date", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("01/09/2020"),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Price", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("\RM10"),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Total Price", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("\RM10", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 54),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _showNotification(); // Show notification
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PaymentSuccessPage()),
                      );
                    },
                    child: const Text(
                      "Pay Now",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                const SizedBox(height: 54),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required String image,
    required String value,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedMethod,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedMethod = newValue;
                });
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
            Image.asset(image, height: 32),
          ],
        ),
      ),
    );
  }
}
