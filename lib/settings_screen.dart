import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'main.dart';
import 'about_screen.dart';
import 'db_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmAndDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete account?"),
        content: const Text(
          "This will permanently delete your account, all uploaded notes, and your question history. This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;

    try {
      await http.delete(Uri.parse("http://10.0.2.2:8000/user/$userId"));
      await DBHelper.clearHistory();
      await user.delete();

      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Please sign out and sign in again before deleting your account.",
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900] : Colors.grey[100];
    final mutedColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Appearance",
                style: TextStyle(fontSize: 12, color: mutedColor),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, currentMode, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Dark mode",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      value: currentMode == ThemeMode.dark,
                      onChanged: (isDarkSelected) {
                        final newMode = isDarkSelected
                            ? ThemeMode.dark
                            : ThemeMode.light;
                        themeNotifier.value = newMode;
                        saveThemePreference(newMode);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                "Account",
                style: TextStyle(fontSize: 12, color: mutedColor),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red[400], size: 20),
                      const SizedBox(width: 12),
                      Text(
                        "Sign out",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.red[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _confirmAndDeleteAccount(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_forever_outlined,
                        color: Colors.red[400],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Delete account",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.red[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text("Info", style: TextStyle(fontSize: 12, color: mutedColor)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: mutedColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        "About & privacy",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
