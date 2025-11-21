import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../moderation/presentation/cubits/moderation_cubit.dart';
import '../../domain/entities/post.dart';

class PostTile extends StatelessWidget {
  final Post post;
  final void Function()? onDelete;
  final void Function()? onTap;
  final int commentCount;
  final bool showFullContent;

  const PostTile({
    super.key,
    required this.post,
    required this.onDelete,
    required this.onTap,
    this.commentCount = 0, // default to 0
    this.showFullContent = false,
  });

  // show report dialog box
  void _showReportDialog(BuildContext context) {
    final moderationCubit = context.read<ModerationCubit>();
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report Post"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: "Enter reason",
              ),
            )
          ],
        ),
        actions: [
          // cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          // report button
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                moderationCubit.reportContent(
                  contentId: post.id,
                  authorUid: post.uid,
                  reportReason: textController.text,
                );
              }

              // show confirmation and close box
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reported Successfully.")));
            },
            child: const Text("Report"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // get username of current signed in user
    final authCubit = context.read<AuthCubit>();
    final String currentUsername = authCubit.currentUser?.email ?? '';

    // check if post was created by this user
    final bool isOwnPost = (post.username == currentUsername);

    // prepare display user name
    final displayUsername = post.username.split('@').first;

    // get moderation cubit to check blocked status
    final moderationCubit = context.read<ModerationCubit>();
    final bool isPostAuthorBlocked = moderationCubit.isUserBlocked(post.uid);

    // build more options widget
    Widget buildMoreOptions() {
      return PopupMenuButton<String>(
        icon: Icon(
          Icons.more_horiz,
          color: Theme.of(context).colorScheme.primary,
        ),
        itemBuilder: (context) {
          final List<PopupMenuEntry<String>> options = [];

          // if it's the user's own post, show delete option
          if (isOwnPost) {
            options.add(
              const PopupMenuItem<String>(
                value: "delete",
                child: Text("Delete"),
              ),
            );
          }

          // if it's someone else' post
          else {
            // show block
            if (!isPostAuthorBlocked) {
              options.add(
                const PopupMenuItem<String>(
                  value: "block",
                  child: Text("Block User"),
                ),
              );
            }

            // show report button
            options.add(
              const PopupMenuItem<String>(
                value: "report",
                child: Text("Report User"),
              ),
            );
          }

          return options;
        },
        onSelected: (value) {
          if (value == 'delete') {
            onDelete?.call();
          } else if (value == 'block') {
            moderationCubit.blockUser(post.uid, post.username);
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text("User Blocked")));
          } else if (value == 'report') {
            _showReportDialog(context);
          }
        },
      );
    }

    // build UI
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: title & delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // title
                Text(
                  post.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                // more options -> delete, block, report, etc..
                buildMoreOptions()
              ],
            ),

            const SizedBox(height: 10),

            // content
            Text(
              post.content,
              maxLines: showFullContent ? null : 2,
              overflow: showFullContent ? null : TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),

            const SizedBox(height: 25),

            // Bottom row: username & comment counts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // username
                Text(
                  displayUsername,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),

                // comment counts
                Text(
                  "$commentCount comments",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
