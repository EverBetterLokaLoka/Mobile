import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lokaloka/core/constants/url_constant.dart';
import 'package:lokaloka/features/auth/models/user.dart';
import 'package:lokaloka/features/auth/services/auth_services.dart';
import 'package:lokaloka/features/moments/screens/create_moment_screen.dart';
import 'package:lokaloka/features/moments/screens/edit_post.dart';
import 'package:lokaloka/features/profile/models/post_modal.dart';
import 'package:lokaloka/features/profile/services/profile_services.dart';
import 'package:lokaloka/features/profile/screens/comment_screen.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lokaloka/widgets/notice_widget.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  late Future<List<Post>> _postsFuture;
  List<Post> _posts = [];
  bool _isRefreshing = false;
  int? _currentUserId;
  UserNormal? _currentUserProfile; // Biến để lưu thông tin người dùng.
  Set<int> _loadingLikes = {};
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _loadPosts();
  }

  Future<void> _getCurrentUserId() async {
    try {
      String? token = await _authService.getToken();
      if (token != null) {
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        setState(() {
          _currentUserId = int.tryParse(decodedToken['id'].toString());
        });
        _getCurrentUserProfile(); // Gọi hàm để lấy thông tin người dùng.
      }
    } catch (e) {
      print('Error getting current user ID: $e');
    }
  }

  Future<void> _getCurrentUserProfile() async {
    try {
      // Gọi dịch vụ để lấy thông tin người dùng
      _currentUserProfile = await _profileService.getUserProfile();
      // Cập nhật giao diện nếu cần
      setState(() {});
    } catch (e) {
      print('Error getting user profile: $e');
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isRefreshing = true;
      _postsFuture = _profileService.fetchPosts();
    });

    try {
      final posts = await _postsFuture;
      setState(() {
        _posts = posts;
        _isRefreshing = false;
      });
    } catch (e) {
      print('Error loading posts: $e');
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshPosts() async {
    await _loadPosts();
    return Future.value();
  }

  Future<void> _handleLikePress(Post post) async {
    if (_currentUserId == null || _loadingLikes.contains(post.id)) {
      return;
    }

    // Immediate local state update
    bool isLiked = post.likes.any((like) => like.userId == _currentUserId);
    final List<Like> updatedLikes = List.from(post.likes);
    final int updatedLikeCount = isLiked ? post.likeCount - 1 : post.likeCount + 1;

    setState(() {
      if (isLiked) {
        updatedLikes.removeWhere((like) => like.userId == _currentUserId);
      } else {
        updatedLikes.add(Like(
          id: 0, // Temporary ID; the server will handle ID assignment
          postId: post.id,
          userId: _currentUserId!,
          userEmail: "", // Bạn có thể lấy từ người dùng hoặc token nếu cần
          createdAt: DateTime.now(),
        ));
      }

      // Update the post locally without affecting its other content
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = post.copyWith(
          likes: updatedLikes,
          likeCount: updatedLikeCount,
        );
      }
    });

    // Now make the API call to actually toggle the like
    try {
      await _profileService.toggleLike(post.id);
    } catch (e) {
      print('Error toggling like: $e');

      // Handling failure scenario: revert local state to original
      setState(() {
        if (isLiked) {
          updatedLikes.add(Like(
            id: 0, // Temporary ID for the revert scenario
            postId: post.id,
            userId: _currentUserId!,
            userEmail: "", // Đặt đúng email nếu cần
            createdAt: DateTime.now(),
          ));
        } else {
          updatedLikes.removeWhere((like) => like.userId == _currentUserId);
        }

        // Revert the post state if the API call fails
        final revertIndex = _posts.indexWhere((p) => p.id == post.id);
        if (revertIndex != -1) {
          _posts[revertIndex] = post.copyWith(
            likes: updatedLikes,
            likeCount: isLiked ? updatedLikeCount + 1 : updatedLikeCount - 1,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update like status')),
      );
    }
  }

  Future<void> _handleDeletePost(int postId) async {
    // Hiển thị thông báo xác nhận xóa
    final confirmed = await showCustomNotice(
        context,
        "Are you sure you want to delete this post?",
        "confirm"
    );

    // Nếu người dùng xác nhận xóa
    if (confirmed ?? false) {
      try {
        await _profileService.deletePost(postId);
        setState(() {
          _posts.removeWhere((post) => post.id == postId);
        });
      } catch (e) {
        print('Failed to delete post: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post')),
        );
      }
    }
  }

  void _handleCommentAdded(Post post, Comment newComment) {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        final updatedPost = Post(
          id: post.id,
          content: post.content,
          userId: post.userId,
          userEmail: post.userEmail,
          userName: post.userName,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
          avatar: post.avatar,
          comments: [...post.comments, newComment],
          likes: post.likes,
          images: post.images,
          likeCount: post.likeCount,
          commentCount: post.commentCount + 1,
          destroyed: post.destroyed,
        );
        _posts[index] = updatedPost;
      }
    });
  }

  void _handleEditPost(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPostScreen(
          post: post,
          onUpdate: (updatedPost) {
            setState(() {
              final index = _posts.indexWhere((p) => p.id == post.id);
              if (index != -1) {
                _posts[index] = updatedPost;
              }
            });
          },
        ),
      ),
    );
  }

  void _openImageGallery(List<PostImage> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewGallery.builder(
          itemCount: images.length,
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(images[index].content),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              heroAttributes: PhotoViewHeroAttributes(tag: images[index].content), // Đảm bảo có hero animation
            );
          },
          scrollPhysics: BouncingScrollPhysics(),
          backgroundDecoration: BoxDecoration(color: Colors.black),
          pageController: PageController(initialPage: initialIndex),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshPosts,
            child: _posts.isEmpty && !_isRefreshing
                ? FutureBuilder<List<Post>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${snapshot.error}'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshPosts,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No posts available'));
                }

                if (_posts.isEmpty && snapshot.data != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _posts = snapshot.data!;
                    });
                  });
                }

                return _buildPostsList(snapshot.data!);
              },
            )
                : _buildPostsList(_posts),
          ),
          if (_isRefreshing && _posts.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Chuyển đến màn hình tạo bài viết với thông tin người dùng
          final newPost = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateMomentScreen(
                userName: _currentUserProfile?.full_name ?? "Tên người dùng",
                userLocation: "Địa điểm người dùng", // Thay thế bằng địa điểm người dùng thực tế
                userAvatar: _currentUserProfile?.avatar ?? '', // URL thực tế của avatar người dùng
              ),
            ),
          );

          // Nếu có bài viết mới được tạo thành công
          if (newPost != null) {
            setState(() {
              _posts.insert(0, newPost); // Thêm bài viết mới vào đầu danh sách
            });
            HomeTab();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildPostsList(List<Post> posts) {
    if (posts.isEmpty) {
      return Center(child: Text('No posts available'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(10),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(posts[index]);
      },
    );
  }

  Widget _buildPostCard(Post post) {
    DateTime postDate = DateTime.tryParse(post.createdAt) ?? DateTime.now();
    final String formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(postDate);

    bool isLiked = post.likes.any((like) => like.userId == _currentUserId);

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(post.avatar),
                      backgroundColor: Colors.blue,
                    ),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(formattedDate, style: TextStyle(color: Colors.grey, fontSize: 12))
                      ],
                    )
                  ],
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert),
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ];
                  },
                  onSelected: (value) {
                    if (value == 'delete') {
                      _handleDeletePost(post.id);
                    } else if (value == 'edit') {
                      _handleEditPost(post);
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            if (post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(post.content),
              ),
            if (post.images.isNotEmpty) _buildImageGrid(post.images),
            Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: _loadingLikes.contains(post.id)
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : null,
                      ),
                      onPressed: () => _handleLikePress(post),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    SizedBox(width: 5),
                    Text('${post.likeCount}'),
                  ],
                ),
                InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentScreen(
                          post: post,
                          onCommentAdded: (newComment) => _handleCommentAdded(post, newComment),
                        ),
                      ),
                    );
                    _refreshPosts();
                  },
                  child: Row(
                    children: [
                      Icon(Icons.comment),
                      SizedBox(width: 5),
                      Text('${post.commentCount}'),
                    ],
                  ),
                ),

              ],
            ),
            if (post.comments.isNotEmpty) _buildLatestComment(post.comments.last),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestComment(Comment comment) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest comment:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${comment.userName}: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Expanded(
                  child: Text(
                    comment.content,
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<PostImage> images) {
    if (images.isEmpty) return SizedBox();

    if (images.length == 1) {
      return GestureDetector(
        onTap: () {
          _openImageGallery(images, 0);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              images[0].content,
              fit: BoxFit.cover,
              height: 200,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: Center(child: Icon(Icons.image_not_supported)),
                );
              },
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: images.length == 2 ? 2 : 3,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          childAspectRatio: 1.0,
        ),
        itemCount: images.length > 6 ? 6 : images.length,
        itemBuilder: (context, index) {
          bool showOverlay = images.length > 6 && index == 5;

          return GestureDetector(
            onTap: () {
              _openImageGallery(images, index);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    images[index].content,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Center(child: Icon(Icons.image_not_supported)),
                      );
                    },
                  ),
                ),
                if (showOverlay)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '+${images.length - 5}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}