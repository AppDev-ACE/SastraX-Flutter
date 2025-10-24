import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommentsPage extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const CommentsPage({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  final CollectionReference groupChat =
  FirebaseFirestore.instance.collection("groupChat");

  String? currentUserRegNo;
  String? currentUserName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserRegNo = prefs.getString('regNo');

    if (currentUserRegNo != null) {
      final doc = await FirebaseFirestore.instance
          .collection('studentDetails')
          .doc(currentUserRegNo)
          .get();

      final profileData = doc.data()?['profile'] ?? {};
      currentUserName = profileData['name'];
    }

    setState(() {});
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final replyId =
        groupChat.doc(widget.postId).collection("replies").doc().id;

    await groupChat.doc(widget.postId).update({
      "replies.$replyId": {
        "replyMessage": text,
        "replyTime": FieldValue.serverTimestamp(),
        "senderID": currentUserRegNo ?? "Unknown",
        "senderName": currentUserName ?? "Anonymous",
      },
      "replyCount": FieldValue.increment(1),
    });

    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.postData;
    final secondaryTextColor = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'), toolbarHeight: MediaQuery.of(context).size.height * 0.14,
      ),
      body: Column(
        children: [
          // Original Post
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                        radius: 24,
                        child: Text(post['senderName'][0].toUpperCase())),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post['senderName'],
                              style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            DateFormat.yMMMd().add_jm().format(
                              (post['timestamp'] as Timestamp?)
                                  ?.toDate() ??
                                  DateTime.now(),
                            ),
                            style: TextStyle(color: secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (post['message'] != null &&
                    (post['message'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(post['message'],
                        style: const TextStyle(fontSize: 18)),
                  ),
                const SizedBox(height: 8),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Replies',
                      style: TextStyle(
                          color: secondaryTextColor,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Replies Stream
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: groupChat.doc(widget.postId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final replies = data["replies"] as Map<String, dynamic>? ?? {};

                final sortedReplies = replies.entries.toList()
                  ..sort((a, b) {
                    final aTime = (a.value["replyTime"] as Timestamp?)
                        ?.toDate() ??
                        DateTime.now();
                    final bTime = (b.value["replyTime"] as Timestamp?)
                        ?.toDate() ??
                        DateTime.now();
                    return bTime.compareTo(aTime);
                  });

                if (sortedReplies.isEmpty) {
                  return const Center(child: Text("No replies yet."));
                }

                return ListView.builder(
                  itemCount: sortedReplies.length,
                  itemBuilder: (context, index) {
                    final reply = sortedReplies[index].value;
                    return _buildCommentTile(reply);
                  },
                );
              },
            ),
          ),

          // Input field
          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> reply) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
              radius: 20, child: Text((reply["senderName"] ?? "U")[0])),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reply["senderName"] ?? "Unknown",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(reply["replyMessage"] ?? ""),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: "Post your reply",
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _addComment(),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send,
                  color: Theme.of(context).colorScheme.primary),
              onPressed: _addComment,
            ),
          ],
        ),
      ),
    );
  }
}
