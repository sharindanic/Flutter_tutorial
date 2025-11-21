import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../moderation/presentation/cubits/moderation_cubit.dart';
import '../../../moderation/presentation/cubits/moderation_states.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../../domain/repos/post_repo.dart';
import 'post_states.dart';

/*

THIS CUBIT HANDLES THE STATE MANAGEMENT FOR POSTS!

*/

class PostCubit extends Cubit<PostState> {
  final PostRepo postRepo;
  final ModerationCubit moderationCubit;

  PostCubit({
    required this.postRepo,
    required this.moderationCubit,
  }) : super(PostInitial()) {
    // listen to if a user gets blocked/unblocked, then reload posts
    moderationCubit.stream.listen(
      (state) {
        if (state is UserBlocked || state is UserUnblocked) {
          loadPosts();
        }
      },
    );
  }

  // locally cache posts
  List<Post> _posts = [];

  // get all posts
  List<Post> get posts => _posts;

  // Load all posts
  Future<void> loadPosts() async {
    try {
      emit(PostLoading());

      // first load blocked users
      await moderationCubit.loadBlockedUsers();

      // get all posts from repo
      _posts = await postRepo.loadAllPosts();

      // filter out blocked people
      final blockedUserIds = moderationCubit.blockedUserIds;
      if (blockedUserIds.isNotEmpty) {
        _posts =
            _posts.where((post) => !blockedUserIds.contains(post.uid)).toList();
      }

      // create map of comment counts per post
      final Map<String, int> commentCounts = {};

      // go thru each post and fetch comment counts
      for (final post in _posts) {
        final comments = await postRepo.getComments(post.id);
        commentCounts[post.id] = comments.length;
      }

      emit(PostsLoaded(posts, commentCounts: commentCounts));
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }

  // Create new post
  Future<void> createPost({
    required String title,
    required String content,
    required String category,
    required String username,
    required String uid,
  }) async {
    try {
      emit(PostLoading());
      final post = Post(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        category: category,
        username: username,
        uid: uid,
      );
      await postRepo.createPost(post);
      emit(PostCreated());
      await loadPosts();
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }

  // Delete a post
  Future<void> deletePost(String id) async {
    try {
      emit(PostLoading());
      await postRepo.deletePost(id);
      emit(PostDeleted());
      await loadPosts();
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }

  // Load comments for a post
  Future<List<Comment>> getComments(String postId) async {
    try {
      // get all comments from repo
      List<Comment> allComments = await postRepo.getComments(postId);

      // filter out comments from blocked users
      final blockedUserIds = moderationCubit.blockedUserIds;
      if (blockedUserIds.isNotEmpty) {
        allComments = allComments
            .where((comment) => !blockedUserIds.contains(comment.uid))
            .toList();
      }

      return allComments;
    } catch (e) {
      emit(PostError(e.toString()));
      return [];
    }
  }

  // Add new comment
  Future<void> addComment({
    required String postId,
    required String text,
    required String username,
    required String uid,
  }) async {
    try {
      // create the comment
      final comment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        postId: postId,
        text: text,
        username: username,
        uid: uid,
      );

      // add comment via repo
      await postRepo.addComment(comment);

      // reload posts to update comments
      await loadPosts();
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }

  // Delete comment
  Future<void> deleteComment({
    required String commentId,
    required String postId,
  }) async {
    try {
      // delete comment via repo
      await postRepo.deleteComment(postId, commentId);

      // reload posts
      await loadPosts();
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }
}
