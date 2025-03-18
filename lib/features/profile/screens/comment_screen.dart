import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lokaloka/features/auth/models/user.dart';
import 'package:lokaloka/features/profile/models/post_modal.dart';
import 'package:lokaloka/features/profile/services/profile_services.dart';

class CommentScreen extends StatefulWidget {
  final Post post;
  final Function(Comment) onCommentAdded;
  final Function(Comment) onCommentUpdated; // Thêm callback cho cập nhật
  final Function(int) onCommentDeleted; // Thêm callback cho xóa

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
  bool _isSending = false;
  int currentUserId = 0; // User ID of the current user
  Comment? editingComment; // Hold the comment being edited
  bool _hasCommentText = false; // Thêm biến để theo dõi trạng thái nội dung

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.post.comments);
    _getCurrentUserProfile();

    // Thêm listener để theo dõi thay đổi nội dung
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

  // Cập nhật comments khi widget.post.comments thay đổi
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

  Future<void> _addOrUpdateComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      UserNormal? userProfile = await _profileService.getUserProfile();
      final int userId = userProfile?.id ?? 0;
      final String userEmail = userProfile?.email ?? 'user@example.com';
      final String userName = userProfile?.full_name ?? 'Unknown User';
      final String avatar = userProfile?.avatar ?? '';

      if (editingComment == null) {
        // Create a new comment
        Comment newComment = await _profileService.addComment(widget.post.id, _commentController.text);
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
        });
        widget.onCommentAdded(newComment);
      } else {
        // Update the existing comment
        Comment updatedComment = await _profileService.updateComment(widget.post.id, editingComment!.id, _commentController.text);

        Comment fullUpdatedComment = Comment(
          id: updatedComment.id,
          content: updatedComment.content,
          postId: widget.post.id,
          userId: userId,
          userEmail: userEmail,
          userName: userName,
          createdAt: editingComment!.createdAt, // Giữ nguyên thời gian tạo
          avatar: avatar,
          destroyed: null,
        );

        setState(() {
          int index = _comments.indexWhere((c) => c.id == editingComment!.id);
          if (index != -1) {
            _comments[index] = fullUpdatedComment;
          }
        });

        // Thông báo cho màn hình cha về comment đã cập nhật
        widget.onCommentUpdated(fullUpdatedComment);

        editingComment = null;
      }

      _commentController.clear();
      setState(() {
        _isSending = false;
      });
    } catch (error) {
      print('Error saving comment: $error');
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _editComment(Comment comment) async {
    // Tạo một biến để lưu nội dung comment, thay vì sử dụng controller mới
    String editedContent = comment.content;
    bool isCommentValid = comment.content.isNotEmpty;

    editingComment = comment;

    final bool? shouldUpdate = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Ngăn người dùng đóng dialog bằng cách nhấn bên ngoài
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('Edit Comment'),
                content: TextFormField(
                  initialValue: comment.content, // Sử dụng initialValue thay vì controller
                  decoration: InputDecoration(
                    hintText: 'Edit your comment...',
                  ),
                  autofocus: true,
                  maxLines: null,
                  onChanged: (value) {
                    // Cập nhật biến nội dung và trạng thái hợp lệ
                    editedContent = value;
                    setDialogState(() {
                      isCommentValid = value.trim().isNotEmpty;
                    });
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: isCommentValid
                        ? () {
                      Navigator.of(context).pop(true);
                    }
                        : null,
                    child: Text('Save'),
                    style: TextButton.styleFrom(
                      foregroundColor: isCommentValid ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                  ),
                ],
              );
            }
        );
      },
    );

    if (shouldUpdate == true && mounted) {
      // Cập nhật nội dung comment vào controller chính
      _commentController.text = editedContent;
      // Call _addOrUpdateComment to handle the update
      _addOrUpdateComment();
    } else {
      // Nếu hủy, xóa comment đang chỉnh sửa
      setState(() {
        editingComment = null;
      });
    }
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
                Navigator.of(context).pop(true);
              },
              child: Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await _profileService.deleteComment(commentId);
        setState(() {
          _comments.removeWhere((c) => c.id == commentId);
        });

        // Thông báo cho màn hình cha về comment đã xóa
        widget.onCommentDeleted(commentId);
      } catch (error) {
        print('Error deleting comment: $error');
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

    final String formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(commentDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(comment.avatar.isNotEmpty ? comment.avatar : 'https://example.com/default_avatar.png'),
            backgroundColor: Colors.blue,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment.userName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    comment.content,
                    style: TextStyle(fontSize: 14),
                  ),
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
    _commentController.removeListener(_updateCommentStatus); // Xóa listener khi dispose
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
                hintText: editingComment == null ? 'Add a comment...' : 'Edit comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _hasCommentText ? _addOrUpdateComment() : null,
            ),
          ),
          SizedBox(width: 8),
          _isSending
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
            onPressed: _hasCommentText
                ? _addOrUpdateComment
                : null,
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
          // Build post summary or any additional UI elements here.
          Expanded(
            child: _comments.isEmpty
                ? Center(child: Text('No comments yet. Be the first to comment!'))
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