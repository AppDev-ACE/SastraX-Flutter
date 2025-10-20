import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // REQUIRED FIRESTORE

import '../../services/ApiEndpoints.dart';

class StudyMaterialBot extends StatefulWidget {
  final String url;
  final String token;
  final String? regNo; // Used as the Firestore Document ID

  const StudyMaterialBot({
    super.key,
    required this.url,
    required this.token,
    this.regNo,
  });

  @override
  State<StudyMaterialBot> createState() => _StudyMaterialBotState();
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

  ChatMessage({
    required this.text,
    required this.fromUser,
    this.materials,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

class _StudyMaterialBotState extends State<StudyMaterialBot> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = false;

  late final ApiEndpoints _api;

  // Firestore Instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- ADDED for Retry Logic ---
  String? _lastQuery;
  Uri? _lastUri;
  String? _lastError;
  // ---------------------------

  @override
  void initState() {
    super.initState();
    _api = ApiEndpoints(widget.url);

    // Load previous chats every time the State is initialized (when navigating back)
    if (widget.regNo != null) {
      _loadPreviousChats();
    } else {
      _addWelcomeMessage();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ⬇️ ADDED: Helper for welcome message
  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: "Hi! Ask me for PYQs or notes (e.g. 'os pyq')",
      fromUser: false,
    ));
  }

  // ⬇️ ADDED: Function to load chats from Firestore
  Future<void> _loadPreviousChats() async {
    if (widget.regNo == null) {
      _addWelcomeMessage();
      return;
    }

    setState(() => _loading = true);

    try {
      final chatData = await _fetchFromFirehose(widget.regNo!);

      final List<ChatMessage> loadedChats = chatData.map((data) {
        final List<MaterialItem>? materials = (data['materials'] as List<dynamic>?)
            ?.map((m) => MaterialItem(title: m['title'], link: m['link']))
            .toList();

        return ChatMessage(
          text: data['text'] as String,
          fromUser: data['fromUser'] as bool,
          // Parse the stored time string back to DateTime
          time: DateTime.parse(data['time'] as String),
          materials: materials,
        );
      }).toList();

      setState(() {
        _messages.clear();
        // Load old messages (reversed for ListView.builder(reverse: true))
        _messages.addAll(loadedChats.reversed);
        _addWelcomeMessage(); // Add the standard welcome message
      });

    } catch (e) {
      print('Error loading previous chats: $e');
      _addWelcomeMessage(); // Add welcome message even on failure
    } finally {
      setState(() => _loading = false);
      _scrollToTop();
    }
  }

  // ⬇️ IMPLEMENTED: Actual Firestore fetching logic
  Future<List<Map<String, dynamic>>> _fetchFromFirehose(String regNo) async {
    try {
      final docSnapshot = await _firestore
          .collection('material_bot')
          .doc(regNo)
          .get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return [];
      }

      // Assumes history is stored in an array field named 'chats'
      final chatList = (docSnapshot.data()!['chats'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ?? [];

      return chatList;

    } catch (e) {
      print('Firestore Load Error: $e');
      return [];
    }
  }

  // ⬇️ IMPLEMENTED: Actual Firestore save logic
  Future<void> _saveChat(ChatMessage message) async {
    if (widget.regNo == null) return;

    // Convert ChatMessage to a storable Map
    final chatMap = {
      'text': message.text,
      'fromUser': message.fromUser,
      'time': message.time.toIso8601String(), // Store time as string
      'materials': message.materials?.map((m) => {'title': m.title, 'link': m.link}).toList(),
    };

    try {
      // Use arrayUnion to append the message to the 'chats' array in the document 'material_bot/{regNo}'
      await _firestore.collection('material_bot').doc(widget.regNo).set(
          {
            'chats': FieldValue.arrayUnion([chatMap]),
            'lastUpdated': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true)
      );
    } catch (e) {
      print('Firestore Save Error: $e');
    }
  }


  Future<void> _sendQuery({String? forcedQuery}) async {
    final query = (forcedQuery ?? _controller.text).trim();
    if (query.isEmpty || _loading) return;

    final userMsg = ChatMessage(text: query, fromUser: true);

    // ⬇️ Save user message
    await _saveChat(userMsg);

    setState(() {
      _messages.insert(0, userMsg); // Add to local list
      if (forcedQuery == null) _controller.clear();
      _loading = true;
      _lastError = null; // Clear previous error
    });
    _scrollToTop();

    try {
      final uri = Uri.parse(_api.chatbot);

      _lastQuery = query;
      _lastUri = uri;

      final headers = {
        'Content-Type': 'application/json',
        if (widget.token.isNotEmpty) 'Authorization': 'Bearer ${widget.token}'
      };

      final body = jsonEncode({
        'message': query, // Match req.body.message
        if (widget.regNo != null) 'regNo': widget.regNo,
        'token': widget.token
      });

      final res = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));

      String? replyText;
      List<MaterialItem> materials = [];

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['reply'] != null) {
          replyText = decoded['reply'].toString();
          // Extract all URLs from the reply
          final urls = _extractAllUrls(replyText);
          for (final link in urls) {
            materials
                .add(MaterialItem(title: 'Open Material for "$query"', link: link));
          }
        } else {
          replyText =
              decoded['reply']?.toString() ?? decoded['message']?.toString() ?? decoded.toString();
        }
      } else {
        replyText = 'Server error: ${res.statusCode}';
        _lastError = replyText;
      }

      final botMsg = ChatMessage(
        text: replyText ?? 'An unknown error occurred.',
        fromUser: false,
        materials: materials.isEmpty ? null : materials,
      );

      // ⬇️ Save bot message
      await _saveChat(botMsg);

      setState(() {
        _messages.insert(0, botMsg);
      });

    } catch (e) {
      final err = 'Wrong Subject Name ! Please enter a valid subject name';
      final errMessage = ChatMessage(text: err, fromUser: false);
      setState(() {
        _lastError = err;
        _messages.insert(0, errMessage);
      });

    } finally {
      setState(() => _loading = false);
      _scrollToTop();
    }
  }

  // --- MODIFIED: To find all URLs and clean up trailing punctuation ---
  List<String> _extractAllUrls(String text) {
    final matches = RegExp(r'(https?:\/\/[^\s]+)').allMatches(text);
    return matches.map((m) {
      String url = m.group(0)!;
      // Trim trailing comma, period, or closing parenthesis
      while (url.endsWith(',') || url.endsWith('.') || url.endsWith(')')) {
        url = url.substring(0, url.length - 1);
      }
      return url;
    }).toList();
  }

  void _scrollToTop() {
    if (_scroll.hasClients) {
      _scroll.animateTo(0.0,
          duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  // --- MODIFIED: Enhanced _openLink for robust URL parsing and launching ---
  Future<void> _openLink(String link) async {
    Uri? uri;
    try {
      // 1. Try to parse the link first
      uri = Uri.parse(link);
    } catch (e) {
      // 2. If parsing fails, try to encode and parse
      final encodedLink = Uri.encodeFull(link);
      uri = Uri.tryParse(encodedLink);
    }

    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not parse URL.')),
        );
      }
      return;
    }

    // 3. Attempt to launch the URL.
    try {
      final success = await launchUrl(
        uri,
        // Use externalApplication for guaranteed browser opening on all platforms
        mode: LaunchMode.externalApplication,
      );

      if (!success) {
        // 4. If launchUrl returns false (failure to find an app)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Could not open $link. Please check the URL.')),
          );
        }
      }
    } catch (e) {
      // 5. Catch any platform-specific launch errors.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to launch link: $e')),
        );
      }
    }
  }

  // --- ADDED: Retry function ---
  Future<void> _retryLast() async {
    if (_lastQuery == null) return;
    await _sendQuery(forcedQuery: _lastQuery);
  }

  // --- REBUILT: _buildMessageTile (theme-aware, no sender) ---
  Widget _buildMessageTile(ChatMessage m) {
    final isUser = m.fromUser;

    // Define colors based on theme
    final bg = isUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceVariant;
    final color = isUser
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final linkColor =
    isUser ? Colors.white : Theme.of(context).colorScheme.primary;
    final timeColor = isUser
        ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
        : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7);

    final decoration = BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: decoration,
              child: Column(
                crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(m.text, style: TextStyle(color: color, fontSize: 15)),
                  if (m.materials != null && m.materials!.isNotEmpty)
                    const SizedBox(height: 8),
                  if (m.materials != null)
                    ...m.materials!.map((mat) {
                      return InkWell(
                        onTap: () => _openLink(mat.link),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min, // Fit content
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(mat.title,
                                        style: TextStyle(
                                            color: linkColor,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Text(mat.link,
                                        style: TextStyle(
                                            color: linkColor.withOpacity(0.8),
                                            decoration:
                                            TextDecoration.underline,
                                            fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.open_in_new, size: 18, color: linkColor),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 6),
                  Align(
                      alignment: Alignment.bottomRight,
                      child: Text(TimeOfDay.fromDateTime(m.time).format(context),
                          style: TextStyle(fontSize: 10, color: timeColor))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).colorScheme.background;
    final inputFill = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Material Bot'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: ListView.builder(
                  controller: _scroll,
                  reverse: true, // Display newest message at the bottom
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
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                      ),
                      onSubmitted: (_) => _sendQuery(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                      mini: true,
                      onPressed: _sendQuery,
                      child: const Icon(Icons.search))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}