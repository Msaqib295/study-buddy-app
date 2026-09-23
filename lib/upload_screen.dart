import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _isUploading = false;
  bool _isLoadingDocs = true;
  List<String> _documents = [];

  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() {
      _isLoadingDocs = true;
    });

    final url = Uri.parse("http://10.0.2.2:8000/documents?user_id=$_userId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _documents = List<String>.from(data['documents']);
        _isLoadingDocs = false;
      });
    } else {
      setState(() {
        _isLoadingDocs = false;
      });
    }
  }

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() {
      _isUploading = true;
    });

    final file = result.files.first;
    final url = Uri.parse("http://10.0.2.2:8000/upload?user_id=$_userId");
    final request = http.MultipartRequest('POST', url);

    request.files.add(await http.MultipartFile.fromPath('file', file.path!));

    final response = await request.send();
    await response.stream.bytesToString();

    setState(() {
      _isUploading = false;
    });

    await _fetchDocuments();
  }

  Future<void> _deleteDocument(String filename) async {
    final url = Uri.parse(
      "http://10.0.2.2:8000/documents/$filename?user_id=$_userId",
    );
    await http.delete(url);
    await _fetchDocuments();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900] : Colors.grey[100];
    final mutedColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[700] : Colors.grey[400];
    final iconBgColor = isDark ? Colors.grey[800] : Colors.grey[200];
    final iconColor = isDark ? Colors.grey[300] : Colors.grey[800];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(title: const Text("Upload notes")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: _isUploading ? null : _pickAndUploadFile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor!, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isUploading
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: iconColor,
                                ),
                              )
                            : Icon(
                                Icons.upload_file,
                                color: iconColor,
                                size: 22,
                              ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isUploading ? "Uploading…" : "Choose a PDF",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Lecture slides, notes, or readings",
                        style: TextStyle(fontSize: 12, color: mutedColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                "Your notes",
                style: TextStyle(fontSize: 12, color: mutedColor),
              ),
              const SizedBox(height: 4),
              Text(
                "Tip: remove documents you no longer need",
                style: TextStyle(fontSize: 11, color: mutedColor),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoadingDocs
                    ? const Center(child: CircularProgressIndicator())
                    : _documents.isEmpty
                    ? Center(
                        child: Text(
                          "No documents uploaded yet",
                          style: TextStyle(color: mutedColor, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _documents.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final docName = _documents[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  color: iconColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    docName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: iconColor,
                                  ),
                                  onPressed: () => _deleteDocument(docName),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
