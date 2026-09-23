import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'upload_screen.dart';
import 'ask_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) {
    return "Good morning";
  } else if (hour < 17) {
    return "Good afternoon";
  } else {
    return "Good evening";
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? "there";

    final mutedColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final cardColor = isDark ? Colors.grey[900] : Colors.grey[100];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Study buddy"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              child: const Icon(Icons.settings_outlined),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getGreeting(),
              style: TextStyle(fontSize: 13, color: mutedColor),
            ),
            const SizedBox(height: 4),
            Text(
              userName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            _HomeCard(
              icon: Icons.chat_bubble_outline,
              iconColor: Colors.blue,
              title: "Ask questions",
              subtitle: "Get answers from your notes",
              cardColor: cardColor!,
              mutedColor: mutedColor!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AskScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _HomeCard(
              icon: Icons.upload_outlined,
              iconColor: Colors.green,
              title: "Upload notes",
              subtitle: "Add a new PDF to study",
              cardColor: cardColor,
              mutedColor: mutedColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UploadScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _HomeCard(
              icon: Icons.history,
              iconColor: Colors.purple,
              title: "History",
              subtitle: "Revisit past questions",
              cardColor: cardColor,
              mutedColor: mutedColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color cardColor;
  final Color mutedColor;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.cardColor,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: mutedColor),
          ],
        ),
      ),
    );
  }
}
