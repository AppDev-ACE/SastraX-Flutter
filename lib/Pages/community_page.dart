import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


import 'post_model.dart';
import 'compose_post_page.dart';
import 'comments_page.dart';


class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final List<Post> _posts = [
    Post(
      sender: 'Alice',
      handle: '@alice_wonder',
      avatarInitial: 'A',
      message: 'Hey everyone! Anyone up for a study group tonight? We could cover the last two chapters of calculus.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      likes: 12,
      reposts: 2,
    ),
    Post(
      sender: 'Bob the Builder',
      handle: '@bob_builds',
      avatarInitial: 'B',
      message: 'Just a heads-up, the library just got a new shipment of programming books. Saw some great titles on Flutter and Dart!',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      likes: 34,
      reposts: 9,
    ),
  ];

  void _navigateToComposePage() async {
    final newPost = await Navigator.push<Post>(
      context,
      MaterialPageRoute(builder: (context) => const ComposePostPage()),
    );

    if (newPost != null) {
      setState(() {
        _posts.insert(0, newPost);
      });
    }
  }

  void _navigateToCommentsPage(Post post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommentsPage(post: post)),
    );
    // Refresh the state when returning to update comment/like counts
    setState(() {});
  }

  void _toggleLike(Post post) {
    setState(() {
      if (post.isLiked) {
        post.likes--;
        post.isLiked = false;
      } else {
        post.likes++;
        post.isLiked = true;
      }
    });
  }

  void _repost(Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repost?'),
        content: const Text('This will share the post on your profile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                post.reposts++;
                final repost = Post(
                  sender: 'You',
                  handle: '@me',
                  avatarInitial: 'Y',
                  message: '',
                  timestamp: DateTime.now(),
                  originalPost: post,
                );
                _posts.insert(0, repost);
              });
              Navigator.pop(context);
            },
            child: const Text('Repost'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToComposePage,
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(_posts[index]);
        },
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return InkWell(
      onTap: () => _navigateToCommentsPage(post),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.originalPost != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.repeat, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('${post.sender} reposted', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  child: Text(post.originalPost?.avatarInitial ?? post.avatarInitial),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPostHeader(post.originalPost ?? post),
                      if ((post.originalPost ?? post).message.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text((post.originalPost ?? post).message),
                        ),
                      if (post.originalPost != null)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPostHeader(post.originalPost!),
                              if (post.originalPost!.message.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(post.originalPost!.message),
                                ),
                              if (post.originalPost!.imageFile != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12.0),
                                    child: Image.file(File(post.originalPost!.imageFile!.path)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (post.originalPost == null && post.imageFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.file(File(post.imageFile!.path)),
                          ),
                        ),
                      const SizedBox(height: 12),
                      _buildActionButtons(post),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(Post post) {
    return Row(
      children: [
        Text(post.sender, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${post.handle} · ${DateFormat.jm().format(post.timestamp)}',
            style: TextStyle(color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Post post) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(Icons.chat_bubble_outline, post.comments.length.toString(), () => _navigateToCommentsPage(post)),
        _buildActionButton(Icons.repeat, post.reposts.toString(), () => _repost(post)),
        _buildActionButton(
          post.isLiked ? Icons.favorite : Icons.favorite_border,
          post.likes.toString(),
              () => _toggleLike(post),
          activeColor: post.isLiked ? Colors.pink : null,
        ),
        _buildActionButton(Icons.bar_chart, '156', () {}),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String text, VoidCallback onPressed, {Color? activeColor}) {
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