import 'package:image_picker/image_picker.dart';

class Post {
  final String sender;
  final String handle;
  final String avatarInitial;
  final String message;
  final DateTime timestamp;
  final XFile? imageFile;
  final List<String> comments;

  // State properties
  int likes;
  bool isLiked;
  int reposts;
  bool isReposted;
  final Post? originalPost; // Used for reposts

  Post({
    required this.sender,
    required this.handle,
    required this.avatarInitial,
    required this.message,
    required this.timestamp,
    this.imageFile,
    List<String>? comments,
    this.likes = 0,
    this.isLiked = false,
    this.reposts = 0,
    this.isReposted = false,
    this.originalPost,
  }) : comments = comments ?? [];
}