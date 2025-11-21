import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities/comment.dart';
import '../domain/entities/post.dart';
import '../domain/repos/post_repo.dart';

class FirebasePostRepo implements PostRepo {
  final _firestore = FirebaseFirestore.instance;

  @override
  Future<void> createPost(Post post) async {
    await _firestore.collection("posts").doc(post.id).set(post.toJson());
  }

  @override
  Future<void> deletePost(String id) async {
    await _firestore.collection("posts").doc(id).delete();
  }

  @override
  Future<List<Post>> loadAllPosts() async {
    final snapshot = await _firestore.collection("posts").get();
    return snapshot.docs.map((doc) => Post.fromJson(doc.data())).toList();
  }

  @override
  Future<void> addComment(Comment comment) async {
    await _firestore
        .collection('posts')
        .doc(comment.postId)
        .collection('comments')
        .doc(comment.id)
        .set(comment.toJson());
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  @override
  Future<List<Comment>> getComments(String postId) async {
    // get comments from firestore
    final snapshot = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('id', descending: false)
        .get();

    // convert map into list
    final commentsForThisPost =
        snapshot.docs.map((doc) => Comment.fromJson(doc.data())).toList();

    // return list of comments :D
    return commentsForThisPost;
  }
}
