import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/components/my_textfield.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../subscriptions/presentation/cubits/subscription_cubit.dart';
import '../../../subscriptions/presentation/cubits/subscription_states.dart';
import '../../../subscriptions/presentation/pages/offerings_page.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../components/comment_tile.dart';
import '../components/post_tile.dart';
import '../cubits/post_cubit.dart';

/*

POST PAGE

--------------------------------------------------------------------------------

- Display post
- Display comments

*/

class PostPage extends StatefulWidget {
  final Post post;

  const PostPage({
    super.key,
    required this.post,
  });

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  // text controller
  final _commentController = TextEditingController();

  // list of locally stored comments
  List<Comment> _comments = [];

  // loading..
  bool _isLoading = true;

  // cubits
  late final _postCubit = context.read<PostCubit>();
  late final _authCubit = context.read<AuthCubit>();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // user wants to add new comment (check pro status, only pro can make a comment)
  void handleAddComment() {
    // get current subscription state from cubit
    final subscriptionState = context.read<SubscriptionCubit>().state;

    if (subscriptionState is SubscriptionLoaded && subscriptionState.isPro) {
      // user is pro: proceed to add comment
      _showAddCommentBox();
    } else {
      // user is not pro: prompt the subscription dialog
      showSubscriptionDialog();
    }
  }

  // prompt user to subscribe
  void showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Pro Subscription",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Only pro users can post & comment."),
        actions: [
          // cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          // subscribe button
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OfferingsPage(),
                ),
              );
            },
            child: const Text("Subscribe"),
          )
        ],
      ),
    );
  }

  // load comments for current post
  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final comments = await _postCubit.getComments(widget.post.id);

      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _comments = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Could not load comments..$e")));
    }
  }

  // add new comment
  Future<void> _showAddCommentBox() async {
    _commentController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Comment"),
        content: MyTextfield(
          controller: _commentController,
          hintText: "Write your comment..",
          obscureText: false,
        ),
        actions: [
          // cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          // yes button
          TextButton(
            onPressed: () async {
              if (_commentController.text.isNotEmpty) {
                setState(() {
                  _isLoading = true;
                });

                Navigator.pop(context);

                // use email for username
                final username = _authCubit.currentUser?.email ?? "user";

                // add comment via cubit
                await _postCubit.addComment(
                  postId: widget.post.id,
                  text: _commentController.text,
                  username: username,
                  uid: _authCubit.currentUser!.uid,
                );

                // reload
                await _loadComments();
              }
            },
            child: const Text("Post"),
          ),
        ],
      ),
    );
  }

  // delete a comment
  Future<void> _showDeleteCommentBox(String commentId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Comment"),
        actions: [
          // cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          // yes button
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              // delete comment via cubit
              await _postCubit.deleteComment(
                  commentId: commentId, postId: widget.post.id);

              // reload
              await _loadComments();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    // SCAFFOLD
    return Scaffold(
      // APP BAR
      appBar: AppBar(
        actions: [
          // add new comment button
          IconButton(
            onPressed: handleAddComment,
            icon: const Icon(Icons.add),
          ),
        ],
      ),

      // BODY: Pull to refresh comments
      body: RefreshIndicator(
        onRefresh: _loadComments,
        child: ListView(
          children: [
            // THE POST
            PostTile(
              post: widget.post,
              commentCount: _comments.length,
              onDelete: () {},
              onTap: () {},
              showFullContent: true,
            ),

            Divider(
              indent: 16,
              endIndent: 16,
              color: Theme.of(context).colorScheme.tertiary,
            ),

            // COMMENTS

            // loading..
            if (_isLoading)
              const Center(child: CircularProgressIndicator())

            // no comments..
            else if (_comments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    "No comments yet..",
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              )

            // loaded comments!
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  // get each comment
                  final comment = _comments[index];

                  // Comment tile UI
                  return CommentTile(
                    comment: comment,
                    onDelete: () => _showDeleteCommentBox(comment.id),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
