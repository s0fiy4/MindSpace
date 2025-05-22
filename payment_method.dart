import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mindspace/pages_payment/payment_success.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PaymentMethodPage extends StatefulWidget {
  final int courseId;

  const PaymentMethodPage({Key? key, required this.courseId}) : super(key: key);

  @override
  _PaymentMethodPageState createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String? _selectedMethod = "PayPal"; // Default selected payment method
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  double _price = 0.0;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _fetchCoursePrice();
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

  Future<void> _fetchCoursePrice() async {
    try {
      final response = await supabase
          .from('courses')
          .select('price')
          .eq('id', widget.courseId)
          .maybeSingle();

      if (response != null && response['price'] != null) {
        setState(() {
          _price = response['price'];
        });
      }
    } catch (error) {
      print("Error fetching course price: $error");
    }
  }

  Future<void> _processPayment() async {
    final userId = supabase.auth.currentUser?.id;
    final purchaseDate = DateTime.now();

    if (userId == null) {
      print("User not logged in");
      return;
    }

    try {
      // Insert into payment table
      final paymentResponse = await supabase.from('payment').insert({
        'user_id': userId,
        'payment_method': _selectedMethod,
        'total_price': _price,
        'purchase_date': purchaseDate.toIso8601String(),
        'course_id': widget.courseId,
      }).select('id').maybeSingle();

      if (paymentResponse == null || paymentResponse['id'] == null) {
        print("Error inserting into payment table");
        return;
      }

      final paymentId = paymentResponse['id'];

      // Insert into user_courses table
      await supabase.from('user_courses').insert({
        'user_id': userId,
        'course_id': widget.courseId,
        'payment_id': paymentId,
      });

      // Show notification
      await _showNotification();

      // Navigate to success page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PaymentSuccessPage()),
      );
    } catch (error) {
      print("Error processing payment: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchaseDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

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
              children: [
                const Text("Purchase Date", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(purchaseDate),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Price", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("RM${_price.toStringAsFixed(2)}"),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Price", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("RM${_price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
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
                    onPressed: _processPayment,
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
