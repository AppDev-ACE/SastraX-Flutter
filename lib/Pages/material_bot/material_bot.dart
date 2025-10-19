import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../services/ApiEndpoints.dart';

class MaterialBot extends StatefulWidget {
  final String url;
  final String token;
  final String? regNo;

  const MaterialBot({
    super.key,
    required this.url,
    required this.token,
    this.regNo,
  });

  @override
  // --- RENAMED State Class ---
  State<MaterialBot> createState() => _MaterialBotState();
}

class MaterialItem {
  final String title;
  final String link;
  MaterialItem({required this.title, required this.link});
}

class ChatMessage {
  final String text;
  final bool fromUser;
  final List<MaterialItem>? materials;
  final DateTime time;
  ChatMessage({required this.text, required this.fromUser, this.materials, DateTime? time})
      : time = time ?? DateTime.now();
}

// --- RENAMED State Class ---
class _MaterialBotState extends State<MaterialBot> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = false;

  late final ApiEndpoints _api;
  String? _lastQuery;
  Uri? _lastUri;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _api = ApiEndpoints(widget.url);
    // --- Updated Welcome Message ---
    _messages.add(ChatMessage(
        text: 'Welcome to the Material Bot. Ask for course materials (e.g. "os" or "java")',
        fromUser: false));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendQuery({String? forcedQuery}) async {
    final query = (forcedQuery ?? _controller.text).trim();
    if (query.isEmpty || _loading) return;

    final userMsg = ChatMessage(text: query, fromUser: true);
    setState(() {
      _messages.insert(0, userMsg);
      if (forcedQuery == null) _controller.clear();
      _loading = true;
      _lastError = null;
    });
    _scrollToTop();

    try {
      // --- MODIFIED: Always use chatbot endpoint ---
      // The backend /chatbot route now handles subject matching
      final base = _api.chatbot.replaceAll(RegExp(r'/$'), '');
      final endpoint = base;
      final uri = Uri.parse(endpoint);
      // --- END OF MODIFICATION ---

      // save for retry
      _lastQuery = query;
      _lastUri = uri;

      final headers = {
        'Content-Type': 'application/json',
        if (widget.token.isNotEmpty) 'Authorization': 'Bearer ${widget.token}',
      };

      // --- MODIFIED: Send 'message' key instead of 'query' ---
      final body = jsonEncode({
        'message': query, // Match the backend's req.body.message
        if (widget.regNo != null) 'regNo': widget.regNo,
        'token': widget.token,
      });
      // --- END OF MODIFICATION ---

      final res = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        final err = 'Server error: ${res.statusCode}';
        setState(() {
          _lastError = err;
          _messages.insert(0, ChatMessage(text: err, fromUser: false));
        });
        return;
      }

      // --- REPLACED: Simplified response parsing logic ---
      // This logic is now designed to parse the exact response from your backend snippet
      final decoded = jsonDecode(res.body);
      String replyText;
      List<MaterialItem> materials = [];

      if (decoded is Map && decoded['reply'] != null) {
        replyText = decoded['reply'].toString();
        // Extract all URLs from the reply text
        final urls = _extractAllUrls(replyText);

        for (final link in urls) {
          materials.add(MaterialItem(title: 'Open Material for "$query"', link: link));
        }
      } else {
        // Fallback for an unexpected response or error message
        replyText = decoded['reply']?.toString() ?? decoded['message']?.toString() ?? decoded.toString();
      }

      // Add one chat message that contains BOTH the text and the materials
      setState(() {
        _messages.insert(0, ChatMessage(
          text: replyText,
          fromUser: false,
          materials: materials.isNotEmpty ? materials : null,
        ));
      });
      // --- END OF REPLACEMENT ---

    } catch (e) {
      final err = 'Network / timeout error: ${e.toString()}';
      setState(() {
        _lastError = err;
        _messages.insert(0, ChatMessage(text: err, fromUser: false));
      });
    } finally {
      setState(() => _loading = false);
      _scrollToTop();
    }
  }

  // --- ADDED: Helper to extract all URLs ---
  List<String> _extractAllUrls(String text) {
    // This regex finds URLs and stops at spaces, commas, or other delimiters
    final matches = RegExp(r'(https?:\/\/[^\s<>,;"]+)').allMatches(text);
    return matches.map((m) => m.group(0)!).toList();
  }
  // --- END OF ADDITION ---

  // --- REMOVED: _extractFirstUrl (replaced by _extractAllUrls) ---

  void _scrollToTop() {
    if (_scroll.hasClients) {
      _scroll.animateTo(0.0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<void> _openLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid link')));
      return;
    }
    if (!await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open link')));
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildMessageTile(ChatMessage m) {
    final isUser = m.fromUser;
    final align = isUser ? MainAxisAlignment.end : MainAxisAlignment.start;
    final bg = isUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceVariant;
    final color = isUser
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final linkColor = isUser
        ? Colors.white
        : Theme.of(context).colorScheme.primary;


    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: align,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Always start-align text
                children: [
                  Text(m.text, style: TextStyle(color: color, fontSize: 15)),
                  if (m.materials != null && m.materials!.isNotEmpty) const SizedBox(height: 8),
                  if (m.materials != null)
                    ...m.materials!.map((mat) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _openLink(mat.link),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.link, size: 18, color: linkColor.withOpacity(0.8)),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                        mat.title,
                                        style: TextStyle(color: linkColor, fontWeight: FontWeight.w500)
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _retryLast() async {
    if (_lastUri == null || _lastQuery == null) return;
    await _sendQuery(forcedQuery: _lastQuery);
  }

  @override
  Widget build(BuildContextCtxt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF071226) : const Color(0xFFF7FAFF);
    final inputFill = isDark ? Colors.grey[850] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        // --- Updated AppBar Title ---
        title: const Text('Material Bot'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // error bar with retry
            if (_lastError != null)
              Material(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(_lastError!, style: const TextStyle(color: Colors.red))),
                      TextButton.icon(onPressed: _retryLast, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (ctx, idx) => _buildMessageTile(_messages[idx]),
                ),
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Enter subject (e.g. OS)',
                        filled: true,
                        fillColor: inputFill,
                        border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                            borderSide: BorderSide.none
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                      onSubmitted: (_) => _sendQuery(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed: _sendQuery,
                    child: const Icon(Icons.search),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}