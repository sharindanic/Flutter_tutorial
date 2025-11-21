import '../../domain/entities/post.dart';

abstract class PostState {}

// initial state
class PostInitial extends PostState {}

// loading state
class PostLoading extends PostState {}

// loaded with posts
class PostsLoaded extends PostState {
  final List<Post> posts;
  final Map<String, int> commentCounts;

  PostsLoaded(this.posts, {required this.commentCounts});
}

// error state
class PostError extends PostState {
  final String message;
  PostError(this.message);
}

// post create successfully
class PostCreated extends PostState {}

// post deleted successfully
class PostDeleted extends PostState {}
