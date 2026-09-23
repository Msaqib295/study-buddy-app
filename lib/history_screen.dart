import 'package:flutter/material.dart';

import 'db_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _groupedHistory = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await DBHelper.getAllHistory();
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final entry in history) {
      final timestamp = DateTime.parse(entry['timestamp']);
      final label = _dateLabel(timestamp);

      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(entry);
    }

    setState(() {
      _groupedHistory = grouped;
      _isLoading = false;
    });
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(entryDate).inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Yesterday";
    return "${date.month}/${date.day}/${date.year}";
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $period";
  }

  void _showDetail(BuildContext context, Map<String, dynamic> entry) {
    final timestamp = DateTime.parse(entry['timestamp']);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850] : Colors.grey[100];
    final mutedColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final textColor = isDark ? Colors.white : Colors.black87;
    final sheetColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[isDark ? 700 : 300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    entry['question'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${entry['source']} · ${_formatTime(timestamp)}",
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry['answer'],
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900] : Colors.grey[100];
    final mutedColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _groupedHistory.isEmpty
            ? Center(
                child: Text(
                  "No questions asked yet",
                  style: TextStyle(color: mutedColor, fontSize: 14),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    "Swipe left on an entry to delete it",
                    style: TextStyle(fontSize: 11, color: mutedColor),
                  ),
                  const SizedBox(height: 8),
                  ..._groupedHistory.entries.map((group) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 12),
                          child: Text(
                            group.key,
                            style: TextStyle(fontSize: 12, color: mutedColor),
                          ),
                        ),
                        ...group.value.map((entry) {
                          final timestamp = DateTime.parse(entry['timestamp']);
                          return Dismissible(
                            key: Key(entry['id'].toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (direction) async {
                              await DBHelper.deleteEntry(entry['id']);
                              setState(() {
                                _groupedHistory[group.key]!.remove(entry);
                                if (_groupedHistory[group.key]!.isEmpty) {
                                  _groupedHistory.remove(group.key);
                                }
                              });
                            },
                            child: GestureDetector(
                              onTap: () => _showDetail(context, entry),
                              child: _HistoryTile(
                                question: entry['question'],
                                source: entry['source'],
                                time: _formatTime(timestamp),
                                cardColor: cardColor!,
                                mutedColor: mutedColor!,
                                textColor: textColor,
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String question;
  final String source;
  final String time;
  final Color cardColor;
  final Color mutedColor;
  final Color textColor;

  const _HistoryTile({
    required this.question,
    required this.source,
    required this.time,
    required this.cardColor,
    required this.mutedColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline, size: 16, color: mutedColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "$source · $time",
                  style: TextStyle(fontSize: 11, color: mutedColor),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 16, color: mutedColor),
        ],
      ),
    );
  }
}
