import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.grey[900] : Colors.grey[100];

    return Scaffold(
      appBar: AppBar(title: const Text("About")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/icon/app_icon_light.png',
                width: 56,
                height: 56,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Study buddy",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Version 1.0.0",
              style: TextStyle(fontSize: 12, color: mutedColor),
            ),
            const SizedBox(height: 28),
            Text("About", style: TextStyle(fontSize: 12, color: mutedColor)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "Study buddy is an AI-powered study assistant that answers questions using your own uploaded notes. Built with Flutter, FastAPI, and RAG (retrieval-augmented generation).",
                style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Your data",
              style: TextStyle(fontSize: 12, color: mutedColor),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "Your uploaded documents and question history are stored securely and are only accessible to you. Deleting your account permanently removes all associated data. No data is shared with third parties beyond what's needed to generate answers (your questions and note excerpts are sent to Groq's API for processing).",
                style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            Text("Built by", style: TextStyle(fontSize: 12, color: mutedColor)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "Muhammad Saqib — BSAI student, built this as a portfolio project.",
                style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
