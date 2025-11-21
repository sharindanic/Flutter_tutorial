class Comment {
  final String id;
  final String postId;
  final String text;
  final String username;
  final String uid;

  Comment({
    required this.id,
    required this.postId,
    required this.text,
    required this.username,
    required this.uid,
  });

  // convert comment -> json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'text': text,
      'username': username,
      'uid': uid,
    };
  }

  // convert json -> comment
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['postId'],
      text: json['text'],
      username: json['username'],
      uid: json['uid'] ?? '',
    );
  }
}
