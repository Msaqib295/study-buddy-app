import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'db_helper.dart';

import 'package:firebase_auth/firebase_auth.dart';

class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isThinking;
  _ChatMessage({
    required this.text,
    required this.isUser,
    this.isThinking = false,
  });
}

class _AskScreenState extends State<AskScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isNearBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100;
    if (_showScrollToBottom == isNearBottom) {
      setState(() {
        _showScrollToBottom = !isNearBottom;
      });
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadHistory() async {
    final history = await DBHelper.getAllHistory();
    final loadedMessages = <_ChatMessage>[];

    for (final entry in history.reversed) {
      loadedMessages.add(_ChatMessage(text: entry['question'], isUser: true));
      loadedMessages.add(_ChatMessage(text: entry['answer'], isUser: false));
    }

    setState(() {
      _messages.addAll(loadedMessages);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollToBottom();
    });
  }

  String _friendlyNetworkError(int? statusCode) {
    if (statusCode == null) {
      return "Couldn't reach the study buddy service. Check your connection and try again.";
    }
    switch (statusCode) {
      case 500:
        return "Something went wrong on our end. Please try again.";
      case 404:
        return "Couldn't reach the study buddy service.";
      case 422:
        return "That question couldn't be processed. Try rephrasing it.";
      default:
        return "Something went wrong. Please try again.";
    }
  }

  Future<void> _askQuestion() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: question, isUser: true));
      _messages.add(_ChatMessage(text: "", isUser: false, isThinking: true));
      _isLoading = true;
      _controller.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollToBottom();
    });

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final url = Uri.parse(
        "http://10.0.2.2:8000/ask?question=$question&user_id=$userId",
      );
      final response = await http
          .post(url)
          .timeout(const Duration(seconds: 30));

      setState(() {
        _messages.removeLast(); // remove "thinking" bubble
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['answer'];
        final sources = (data['sources'] as List).join(', ');

        setState(() {
          _messages.add(_ChatMessage(text: answer, isUser: false));
          _isLoading = false;
        });

        await DBHelper.insertEntry(
          question,
          answer,
          sources.isEmpty ? "Unknown" : sources,
        );
      } else {
        setState(() {
          _messages.add(
            _ChatMessage(
              text: _friendlyNetworkError(response.statusCode),
              isUser: false,
            ),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        if (_messages.isNotEmpty && _messages.last.isThinking) {
          _messages.removeLast();
        }
        _messages.add(
          _ChatMessage(text: _friendlyNetworkError(null), isUser: false),
        );
        _isLoading = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollToBottom();
    });
  }

  Future<void> _clearChat() async {
    await DBHelper.clearHistory();
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark ? Colors.grey[850] : Colors.grey[100];
    final mutedColor = isDark ? Colors.grey[400] : Colors.grey[500];
    final inputFillColor = isDark ? Colors.grey[900] : Colors.grey[100];
    final answerTextColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ask a question"),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearChat,
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Text(
                            "Ask something about your notes",
                            style: TextStyle(color: mutedColor, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return _ChatBubble(
                              message: message,
                              bubbleColor: bubbleColor!,
                              answerTextColor: answerTextColor,
                              mutedColor: mutedColor!,
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: inputFillColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _controller,
                            style: TextStyle(color: answerTextColor),
                            decoration: InputDecoration(
                              hintText: "Ask about your notes…",
                              hintStyle: TextStyle(color: mutedColor),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _askQuestion(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isLoading ? null : _askQuestion,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_upward,
                            color: isDark ? Colors.black : Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_showScrollToBottom)
              Positioned(
                bottom: 80,
                right: 20,
                child: FloatingActionButton.small(
                  onPressed: _scrollToBottom,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(
                    Icons.arrow_downward,
                    color: isDark ? Colors.black : Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  final Color bubbleColor;
  final Color answerTextColor;
  final Color mutedColor;

  const _ChatBubble({
    required this.message,
    required this.bubbleColor,
    required this.answerTextColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (message.isThinking) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: mutedColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Thinking…",
                style: TextStyle(
                  fontSize: 13,
                  color: mutedColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).colorScheme.primary : bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 13,
            color: isUser
                ? (isDark ? Colors.black : Colors.white)
                : answerTextColor,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
