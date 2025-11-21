class Post {
  final String id;
  final String title;
  final String content;
  final String category;
  final String username;
  final String uid; // added to identify the person for blocking..

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.username,
    required this.uid,
  });

  // convert post -> json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'username': username,
      'uid': uid,
    };
  }

  // convert json -> post
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: json['category'],
      username: json['username'],
      uid: json['uid'] ?? '',
    );
  }
}
