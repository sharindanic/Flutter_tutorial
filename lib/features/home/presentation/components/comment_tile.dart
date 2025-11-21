import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../moderation/presentation/cubits/moderation_cubit.dart';
import '../../domain/entities/comment.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final void Function()? onDelete;

  const CommentTile({
    super.key,
    required this.comment,
    required this.onDelete,
  });

  // show report dialog box
  void _showReportDialog(BuildContext context) {
    final moderationCubit = context.read<ModerationCubit>();
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report Comment"),
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
                  contentId: comment.id,
                  authorUid: comment.uid,
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

    // check if comment was created by this user
    final bool isOwnPost = (comment.username == currentUsername);

    // prepare display user name
    final displayUsername = comment.username.split('@').first;

    // get moderation cubit to check blocked status
    final moderationCubit = context.read<ModerationCubit>();
    final bool isCommentAuthorBlocked =
        moderationCubit.isUserBlocked(comment.uid);

    // build more options widget
    Widget buildMoreOptions() {
      return PopupMenuButton<String>(
        icon: Icon(
          Icons.more_horiz,
          color: Theme.of(context).colorScheme.primary,
        ),
        itemBuilder: (context) {
          final List<PopupMenuEntry<String>> options = [];

          // if it's the user's own comment, show delete option
          if (isOwnPost) {
            options.add(
              const PopupMenuItem<String>(
                value: "delete",
                child: Text("Delete"),
              ),
            );
          }

          // if it's someone else' comment
          else {
            // show block
            if (!isCommentAuthorBlocked) {
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
            moderationCubit.blockUser(comment.uid, comment.username);
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text("User Blocked")));
          } else if (value == 'report') {
            _showReportDialog(context);
          }
        },
      );
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, top: 20, right: 16),
      child: Row(
        children: [
          // text & username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // text
                Text(
                  comment.text,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 5),

                // username
                Text(
                  displayUsername,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // show more options (delete, block, report, etc..)
          buildMoreOptions()
        ],
      ),
    );
  }
}
