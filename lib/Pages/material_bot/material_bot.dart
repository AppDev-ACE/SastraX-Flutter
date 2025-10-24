import 'dart:async'; // Required for TimeoutException
import 'dart:convert';
import 'dart:io';   // Required for SocketException
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // ⭐️ --- ADD THIS IMPORT ---
import 'package:url_launcher/url_launcher.dart';

// Assuming ApiEndpoints class is in this file or imported correctly.
// If it's in another file, make sure the import path is correct:
import '../../services/ApiEndpoints.dart';

// ⭐️ --- ADD THIS IMPORT (path must be correct for your project) ---
import '../../models/theme_model.dart';


/*
// Your ApiEndpoints class (for reference)
class ApiEndpoints {
  final String baseUrl;
  ApiEndpoints(this.baseUrl);

  // ... (all your other endpoints) ...

  // This is the endpoint we will now use
  String get materials => '$baseUrl/materials';

  // This endpoint is no longer used by this file
  String get pyqBot => '$baseUrl/chatbot';
}
*/

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

class _MaterialBotState extends State<MaterialBot> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = false; // This is now for the *initial list download*

  late final ApiEndpoints _api;
  String? _lastError;

  // --- NEW: This will store all materials from the server ---
  List<Map<String, dynamic>> _allMaterials = [];

  @override
  void initState() {
    super.initState();
    _api = ApiEndpoints(widget.url);

    // Add welcome message immediately
    _messages.add(ChatMessage(
        text: 'Welcome! Loading materials list... (e.g. "cse3" , "ict3")',
        fromUser: false));

    // --- NEW: Fetch the entire list on startup ---
    _fetchMaterialList();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // --- NEW: Fetches the entire material list once ---
  Future<void> _fetchMaterialList() async {
    setState(() {
      _loading = true; // Show loading bar
      _lastError = null;
    });

    try {
      // Use the new endpoint and a GET request
      final uri = Uri.parse(_api.materials);
      final headers = {
        'Content-Type': 'application/json',
        if (widget.token.isNotEmpty) 'Authorization': 'Bearer ${widget.token}',
      };

      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        // The server sends a direct JSON list
        final List<dynamic> data = jsonDecode(res.body);
        _allMaterials = data.map((item) => Map<String, dynamic>.from(item)).toList();
        // --- END ---
      } else {
        throw Exception('Server error: ${res.statusCode}');
      }
    } catch (e) {
      String err;
      if (e is TimeoutException) {
        err = 'Failed to load materials: Connection timed out.';
      } else if (e is SocketException) {
        err = 'Network Error. Please check your internet connection.';
      } else {
        err = 'Failed to load materials list: $e';
      }

      setState(() {
        _lastError = err;
        _messages.insert(0, ChatMessage(text: err, fromUser: false));
      });
    } finally {
      setState(() => _loading = false); // Hide loading bar
      _scrollToTop();
    }
  }

  // --- MODIFIED: This now searches the LOCAL LIST ---
  Future<void> _sendQuery({String? forcedQuery}) async {
    final query = (forcedQuery ?? _controller.text).trim();
    if (query.isEmpty) return;

    final userMsg = ChatMessage(text: query, fromUser: true);
    setState(() {
      _messages.insert(0, userMsg);
      if (forcedQuery == null) _controller.clear();
      _lastError = null; // Clear any previous *load* error
    });
    _scrollToTop();

    String replyText;
    List<MaterialItem> materials = [];

    // Check if the list has been loaded
    if (_allMaterials.isEmpty && _lastError == null) {
      replyText = 'Materials list is still loading. Please try again in a moment.';
    } else if (_lastError != null) {
      replyText = 'Materials list failed to load. Please pull to refresh or check connection.';
    } else {
      // Search the local list for an *exact* match, ignoring case
      final userQuery = query.toLowerCase();

      final match = _allMaterials.firstWhere(
            (item) => item['dept']?.toString().toLowerCase() == userQuery,
        orElse: () => {}, // Return empty map if not found
      );

      if (match.isNotEmpty && match['url'] != null) {
        // --- Found a match ---
        replyText = 'Here is your study material for "$query".';
        materials.add(MaterialItem(
          title: 'Open Material for "$query"',
          link: match['url'],
        ));
      } else {
        // --- No match found ---
        replyText = 'Subject not found. Please check the spelling (e.g., "cse3", "ict3").';
      }
    }

    // Add the bot's reply to the chat
    setState(() {
      _messages.insert(0, ChatMessage(
        text: replyText,
        fromUser: false,
        materials: materials.isNotEmpty ? materials : null,
      ));
    });
    _scrollToTop();
  }

  List<String> _extractAllUrls(String text) {
    // This regex finds URLs and stops at spaces or common punctuation
    final matches = RegExp(r'(https?:\/\/[^\s<>,;"]+)').allMatches(text);
    return matches.map((m) => m.group(0)!).toList();
  }

  void _scrollToTop() {
    if (_scroll.hasClients) {
      _scroll.animateTo(0.0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<void> _openLink(String link) async {
    final Uri? uri = Uri.tryParse(link);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid link')),
      );
      return;
    }

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Opens in browser
      );
      if (!launched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $link')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open link: $e')),
      );
    }
  }

  // --- MODIFIED TO USE AppTheme ---
  Widget _buildMessageTile(ChatMessage m) {
    // Access the theme provider
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = theme.isDarkMode;
    final isUser = m.fromUser;

    // Define colors based on HomeScreen's theme
    // User message: primaryBlue / neonBlue
    // Bot message: darkSurface / white (like a card)
    final bg = isUser
        ? (isDark ? AppTheme.neonBlue : AppTheme.primaryBlue)
        : (isDark ? AppTheme.darkSurface : Colors.white);

    // Text on accent color is white, text on surface is black/white
    final color = isUser
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);

    // Link color on user message is white, on bot message is the accent color
    final linkColor = isUser
        ? Colors.white
        : (isDark ? AppTheme.neonBlue : AppTheme.primaryBlue);

    // This is the variable you asked about:
    final align = isUser ? MainAxisAlignment.end : MainAxisAlignment.start;


    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: align,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              // Apply card shadow to bot messages
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isUser ? null : [ // Only add shadow to bot messages
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
  // --- END OF MODIFICATION ---


  // --- MODIFIED: _retryLast now retries the LIST FETCH ---
  Future<void> _retryLast() async {
    // The only action that can fail with a network error is fetching the list.
    // So, we retry that.
    await _fetchMaterialList();
  }

  // --- MODIFIED TO USE AppTheme ---
  @override
  Widget build(BuildContext context) {
    // Access the theme provider
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;

    // Define colors based on HomeScreen's theme
    final bg = isDark ? AppTheme.darkBackground : Colors.grey[100];
    final inputFill = isDark ? AppTheme.darkSurface : Colors.white;
    final appBarBg = isDark ? AppTheme.darkSurface : AppTheme.primaryBlue;
    final appBarFg = Colors.white;
    final fabBg = isDark ? AppTheme.neonBlue : AppTheme.primaryBlue;
    final errorBg = isDark ? Colors.red.shade900.withOpacity(0.8) : Colors.red.shade100;
    final errorFg = isDark ? Colors.red.shade100 : Colors.red.shade900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Bot'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: appBarBg,     // MODIFIED
        foregroundColor: appBarFg,   // MODIFIED
      ),
      backgroundColor: bg, // MODIFIED
      body: SafeArea(
        child: Column(
          children: [
            // error bar with retry
            if (_lastError != null)
              Material(
                color: errorBg, // MODIFIED
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                            _lastError!,
                            style: TextStyle(color: errorFg) // MODIFIED
                        ),
                      ),
                      TextButton.icon(
                          onPressed: _retryLast,
                          icon: Icon(Icons.refresh, color: errorFg), // MODIFIED
                          label: Text(
                              'Retry',
                              style: TextStyle(color: errorFg) // MODIFIED
                          )
                      ),
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
            // This now only shows on the initial load
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        hintText: 'Enter subject (e.g. cse3)',
                        filled: true,
                        fillColor: inputFill, // MODIFIED
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
                    backgroundColor: fabBg, // MODIFIED
                    foregroundColor: Colors.white, // ADDED
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