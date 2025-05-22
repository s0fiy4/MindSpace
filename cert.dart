import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
// ignore: unused_import
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CertViewerPage extends StatefulWidget {
  const CertViewerPage({Key? key}) : super(key: key);

  @override
  _CertViewerPageState createState() => _CertViewerPageState();
}

class _CertViewerPageState extends State<CertViewerPage> {
  late PdfController pdfController;

  @override
  void initState() {
    super.initState();
    // Initialize the PDF controller to load the cert.pdf from assets
    pdfController = PdfController(
      document: PdfDocument.openAsset('assets/cert.pdf'),
    );
  }

  @override
  void dispose() {
    pdfController.dispose();
    super.dispose();
  }

  Future<void> _downloadPdf() async {
    try {
      // Request external storage directory
      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final filePath = '${directory.path}/cert.pdf';

      // Load the file from assets
      final byteData = await DefaultAssetBundle.of(context).load('assets/cert.pdf');
      final buffer = byteData.buffer;

      // Write the file to the Downloads directory
      final file = File(filePath);
      await file.writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF downloaded to $filePath")),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "PDF Certificate",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: PdfView(
        controller: pdfController,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _downloadPdf,
        label: const Text('Download PDF'),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.download),
        backgroundColor: Colors.blue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      backgroundColor: Colors.white,
    );
  }
}
