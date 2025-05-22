import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PDFViewerPage extends StatefulWidget {
  final int pdfId; // The PDF ID passed from the previous page

  const PDFViewerPage({Key? key, required this.pdfId}) : super(key: key);

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  late PdfControllerPinch _pdfController;
  final supabase = Supabase.instance.client;

  String title = "Loading...";
  String pdfUrl = "";
  bool isLoading = true;
  int currentPage = 1;
  int totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchPDFDetails();
  }

  Future<void> _fetchPDFDetails() async {
    try {
      final response = await supabase
          .from('pdf')
          .select('title, pdf_url')
          .eq('id', widget.pdfId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          title = response['title'] ?? "Untitled";
          pdfUrl = response['pdf_url'] ?? "";
        });

        if (pdfUrl.isNotEmpty) {
          await _initializePDFController();
        }
      }
    } catch (error) {
      print("Error fetching PDF details: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _initializePDFController() async {
    try {
      final response = await http.get(Uri.parse(pdfUrl));

      if (response.statusCode == 200) {
        _pdfController = PdfControllerPinch(
          document: PdfDocument.openData(response.bodyBytes),
        );

        _pdfController.addListener(() {
          setState(() {
            currentPage = _pdfController.page;
          });
        });
      } else {
        print('Failed to load PDF. HTTP Status Code: ${response.statusCode}');
      }
    } catch (error) {
      print("Error initializing PDF Controller: $error");
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _refreshPage() async {
    if (currentPage == 1) {
      setState(() {
        isLoading = true;
      });
      await _fetchPDFDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "PDF VIEWER",
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
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshPage,
              child: Stack(
                children: [
                  PdfViewPinch(
                    controller: _pdfController,
                    scrollDirection: Axis.vertical,
                    onDocumentLoaded: (document) async {
                      setState(() {
                        totalPages = document.pagesCount;
                      });
                    },
                    onPageChanged: (page) {
                      setState(() {
                        currentPage = page;
                      });
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Page $currentPage of $totalPages',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      backgroundColor: Colors.white,
    );
  }
}
