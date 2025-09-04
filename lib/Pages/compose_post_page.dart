import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


import 'post_model.dart'; // Ensure this path is correct

class ComposePostPage extends StatefulWidget {
  const ComposePostPage({super.key});

  @override
  State<ComposePostPage> createState() => _ComposePostPageState();
}

class _ComposePostPageState extends State<ComposePostPage> {
  final TextEditingController _textController = TextEditingController();
  XFile? _selectedImage;

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _post() {
    if (_textController.text.trim().isEmpty && _selectedImage == null) return;
    final newPost = Post(
      sender: 'You', // In a real app, get this from user data
      handle: '@me',
      avatarInitial: 'Y',
      message: _textController.text.trim(),
      timestamp: DateTime.now(),
      imageFile: _selectedImage,
    );
    Navigator.pop(context, newPost);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _post,
              child: const Text('Post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _textController,
                    autofocus: true,
                    maxLines: null,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      hintText: "What's on your mind?",
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_selectedImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_selectedImage!.path)),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: const CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library_outlined, size: 28),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  tooltip: 'Choose from Gallery',
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined, size: 28),
                  onPressed: () => _pickImage(ImageSource.camera),
                  tooltip: 'Take a Photo',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}