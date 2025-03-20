import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lokaloka/features/auth/models/user.dart';
import 'package:lokaloka/features/profile/models/post_modal.dart';
import 'package:lokaloka/features/profile/services/profile_services.dart';

class CommentScreen extends StatefulWidget {
  final Post post;
  final Function(Comment) onCommentAdded;
  final Function(Comment) onCommentUpdated;
  final Function(int) onCommentDeleted;

  const CommentScreen({
    Key? key,
    required this.post,
    required this.onCommentAdded,
    required this.onCommentUpdated,
    required this.onCommentDeleted,
  }) : super(key: key);

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ProfileService _profileService = ProfileService();
  late List<Comment> _comments;
  bool _isLoading = false;
  int currentUserId = 0;
  Comment? editingComment;
  bool _hasCommentText = false;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.post.comments);
    _getCurrentUserProfile();
    _commentController.addListener(_updateCommentStatus);
  }

  void _updateCommentStatus() {
    final hasText = _commentController.text.trim().isNotEmpty;
    if (hasText != _hasCommentText) {
      setState(() {
        _hasCommentText = hasText;
      });
    }
  }

  @override
  void didUpdateWidget(CommentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.comments != oldWidget.post.comments) {
      setState(() {
        _comments = List.from(widget.post.comments);
      });
    }
  }

  Future<void> _getCurrentUserProfile() async {
    UserNormal? userProfile = await _profileService.getUserProfile();
    setState(() {
      currentUserId = userProfile?.id ?? 0;
    });
  }

  Future<void> _addNewComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserNormal? userProfile = await _profileService.getUserProfile();
      final int userId = userProfile?.id ?? 0;
      final String userEmail = userProfile?.email ?? 'user@example.com';
      final String userName = userProfile?.full_name ?? 'Unknown User';
      final String avatar = userProfile?.avatar ?? '';

      Comment newComment = await _profileService.addComment(
          widget.post.id, _commentController.text);

      newComment = Comment(
        id: newComment.id,
        content: newComment.content,
        postId: widget.post.id,
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        createdAt: DateTime.now().toIso8601String(),
        avatar: avatar,
        destroyed: null,
      );

      setState(() {
        _comments.add(newComment);
        _commentController.clear();
      });

      widget.onCommentAdded(newComment);
    } catch (error) {
      print('Error adding comment: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateExistingComment() async {
    if (editingComment == null || _commentController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserNormal? userProfile = await _profileService.getUserProfile();
      final int userId = userProfile?.id ?? 0;
      final String userEmail = userProfile?.email ?? 'user@example.com';
      final String userName = userProfile?.full_name ?? 'Unknown User';
      final String avatar = userProfile?.avatar ?? '';

      Comment updatedComment = await _profileService.updateComment(
          widget.post.id, editingComment!.id, _commentController.text);

      Comment fullUpdatedComment = Comment(
        id: updatedComment.id,
        content: updatedComment.content,
        postId: widget.post.id,
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        createdAt: editingComment!.createdAt,
        avatar: avatar,
        destroyed: null,
      );

      setState(() {
        int index = _comments.indexWhere((c) => c.id == editingComment!.id);
        if (index != -1) {
          _comments[index] = fullUpdatedComment;
        }
        editingComment = null;
        _commentController.clear();
      });

      widget.onCommentUpdated(fullUpdatedComment);
    } catch (error) {
      print('Error updating comment: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update comment. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSendButtonPress() {
    if (editingComment != null) {
      _updateExistingComment();
    } else {
      _addNewComment();
    }
  }

  Future<void> _editComment(Comment comment) async {
    setState(() {
      editingComment = comment;
      _commentController.text =
          comment.content;
    });
  }

  Future<void> _deleteComment(int commentId) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Comment'),
          content: Text('Are you sure you want to delete this comment?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _profileService.deleteComment(commentId);
        setState(() {
          _comments.removeWhere((c) => c.id == commentId);
        });

        widget.onCommentDeleted(commentId);
      } catch (error) {
        print('Error deleting comment: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete comment. Please try again.')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildCommentItem(Comment comment) {
    DateTime commentDate;
    try {
      commentDate = DateTime.parse(comment.createdAt);
    } catch (e) {
      commentDate = DateTime.now();
    }

    final String formattedDate =
        DateFormat('MMM d, yyyy • h:mm a').format(commentDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(comment.avatar.isNotEmpty
                ? comment.avatar
                : 'https://example.com/default_avatar.png'),
            backgroundColor: Colors.blue,
          ),
          SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IntrinsicWidth(
                          child: Container(
                            constraints: BoxConstraints(maxWidth: 230), // Đặt giới hạn tối đa
                            padding: EdgeInsets.fromLTRB(5, 5, 10, 5),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.topLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.userName,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  comment.content,
                                  style: TextStyle(fontSize: 13),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    Spacer(),
                    if (currentUserId == comment.userId)
                      IconButton(
                        icon: Icon(Icons.more_vert, size: 20),
                        onPressed: () => _showCommentMenu(comment),
                      ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentMenu(Comment comment) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editComment(comment);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteComment(comment.id);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _commentController.removeListener(_updateCommentStatus);
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, size: 16, color: Colors.grey[700]),
          ),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: editingComment == null
                    ? 'Add a comment...'
                    : 'Edit comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) =>
                  _hasCommentText ? _handleSendButtonPress() : null,
            ),
          ),
          SizedBox(width: 8),
          _isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: Icon(
                    editingComment == null ? Icons.send : Icons.check,
                    color: _hasCommentText
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  onPressed: _hasCommentText ? _handleSendButtonPress : null,
                ),
          if (editingComment != null)
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                setState(() {
                  editingComment = null;
                  _commentController.clear();
                });
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments (${_comments.length})'),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: _comments.isEmpty
                ? Center(
                    child: Text('No comments yet. Be the first to comment!'))
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      return _buildCommentItem(_comments[index]);
                    },
                  ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }
}
