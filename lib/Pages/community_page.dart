import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'post_model.dart';
import 'compose_post_page.dart';
import 'comments_page.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
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
    currentUserRegNo = prefs.getString('regNo'); // stored earlier on login

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

  Future<void> _addPostToFirestore(Post post) async {
    final docRef = groupChat.doc(); // auto-generated ID
    await docRef.set({
      'message': post.message,
      'mediaURL': post.imageFile != null ? "TODO_upload_image_url" : null,
      'senderID': currentUserRegNo ?? 'Unknown',
      'senderName': currentUserName ?? 'Anonymous',
      'timestamp': FieldValue.serverTimestamp(),
      'replyCount': 0,
      'replies': {},
      'likes': 0,
      'reposts': 0,
      'isLiked': false,
    });
  }

  void _navigateToComposePage() async {
    final newPost = await Navigator.push<Post>(
      context,
      MaterialPageRoute(builder: (context) => const ComposePostPage()),
    );
    if (newPost != null) {
      await _addPostToFirestore(newPost);
    }
  }

  void _navigateToCommentsPage(String messageId, Map<String, dynamic> data) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsPage(
          postId: messageId,
          postData: data,
        ),
      ),
    );
  }

  Future<void> _toggleLike(String messageId, bool isLiked, int likes) async {
    await groupChat.doc(messageId).update({
      'isLiked': !isLiked,
      'likes': isLiked ? likes - 1 : likes + 1,
    });
  }

  Future<void> _repost(String messageId, Map<String, dynamic> data) async {
    final repost = {
      'message': data['message'],
      'mediaURL': data['mediaURL'],
      'senderID': currentUserRegNo ?? "Unknown",
      'senderName': currentUserName ?? "You",
      'timestamp': FieldValue.serverTimestamp(),
      'replyCount': 0,
      'replies': {},
      'likes': 0,
      'reposts': 0,
      'isLiked': false,
      'originalPost': messageId,
    };
    await groupChat.add(repost);
    await groupChat.doc(messageId).update({
      'reposts': (data['reposts'] ?? 0) + 1,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false,  toolbarHeight: MediaQuery.of(context).size.height * 0.0009,),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToComposePage,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: groupChat.orderBy("timestamp", descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildPostCard(doc.id, data);
            },
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(String messageId, Map<String, dynamic> data) {
    return InkWell(
      onTap: () => _navigateToCommentsPage(messageId, data),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              child: Text(
                (data['senderName'] ?? "U")[0],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostHeader(data),
                  if ((data['message'] ?? "").isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(data['message']),
                    ),
                  if (data['mediaURL'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.network(data['mediaURL']),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _buildActionButtons(messageId, data),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] != null
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();

    return Row(
      children: [
        Text(data['senderName'] ?? "Unknown",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            "· ${DateFormat.jm().format(timestamp)}",
            style: TextStyle(color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String messageId, Map<String, dynamic> data) {
    final isLiked = data['isLiked'] ?? false;
    final likes = data['likes'] ?? 0;
    final reposts = data['reposts'] ?? 0;
    final replyCount = data['replyCount'] ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(Icons.chat_bubble_outline, replyCount.toString(),
                () => _navigateToCommentsPage(messageId, data)),
        _buildActionButton(Icons.repeat, reposts.toString(),
                () => _repost(messageId, data)),
        _buildActionButton(
          isLiked ? Icons.favorite : Icons.favorite_border,
          likes.toString(),
              () => _toggleLike(messageId, isLiked, likes),
          activeColor: isLiked ? Colors.pink : null,
        ),
        _buildActionButton(Icons.bar_chart, '156', () {}),
      ],
    );
  }

  Widget _buildActionButton(
      IconData icon,
      String text,
      VoidCallback onPressed, {
        Color? activeColor,
      }) {
    final color = activeColor ?? Colors.grey.shade600;
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}
