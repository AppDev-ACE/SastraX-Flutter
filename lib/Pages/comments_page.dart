import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'post_model.dart'; // Ensure this path is correct

class CommentsPage extends StatefulWidget {
  final Post post;
  const CommentsPage({super.key, required this.post});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  late List<String> _comments;

  @override
  void initState() {
    super.initState();
    _comments = List<String>.from(widget.post.comments);
  }

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        final newComment = _commentController.text.trim();
        _comments.insert(0, newComment);
        // Also update the original post object
        widget.post.comments.insert(0, newComment);
      });
      _commentController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: _comments.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildOriginalPost(widget.post);
                }
                final comment = _comments[index - 1];
                return _buildCommentTile(comment);
              },
              separatorBuilder: (context, index) =>
              index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
            ),
          ),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildOriginalPost(Post post) {
    final secondaryTextColor = Theme.of(context).textTheme.bodySmall?.color;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 24, child: Text(post.avatarInitial)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.sender, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${post.handle} · ${DateFormat.yMMMd().format(post.timestamp)}',
                        style: TextStyle(color: secondaryTextColor)),
                  ],
                ),
              ),
            ],
          ),
          if (post.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(post.message, style: const TextStyle(fontSize: 18)),
            ),
          if (post.imageFile != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(post.imageFile!.path))),
            ),
          const SizedBox(height: 8),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Replies',
                style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(String comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 20, child: Text('Y')), // Placeholder for commenter's avatar
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('You', style: TextStyle(fontWeight: FontWeight.bold)), // Placeholder for commenter's name
                const SizedBox(height: 2),
                Text(comment),
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
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
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
              icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
              onPressed: _addComment,
            ),
          ],
        ),
      ),
    );
  }
}