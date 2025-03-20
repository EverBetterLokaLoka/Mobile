import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lokaloka/features/auth/models/user.dart';
import 'package:lokaloka/features/moments/screens/create_moment_screen.dart';
import 'package:lokaloka/features/profile/models/post_modal.dart';
import 'package:lokaloka/features/profile/services/profile_services.dart';
import 'package:lokaloka/features/profile/screens/comment_screen.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../itinerary/models/Itinerary.dart';
import '../../itinerary/services/itinerary_api.dart';
import '../models/Feeling.dart';

class MomentsScreen extends StatefulWidget {
  @override
  _MomentsScreenState createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  final ProfileService _profileService = ProfileService();
  List<Post> _posts = [];
  bool _isRefreshing = false;
  UserNormal? _currentUser;
  bool _isLoadingUser = true;
  bool _isLoadingItinerary = true;
  Feeling? selectedFeeling;
  Map<int, Itinerary>? _itineraryByPost = {};

  @override
  void initState() {
    super.initState();
    _loadUserAndPosts();
  }

  Future<void> _loadUserAndPosts() async {
    setState(() {
      _isRefreshing = true;
      _isLoadingUser = true;
      _isLoadingItinerary = true;
    });

    try {
      _currentUser = await _profileService.getUserProfile();
      _posts = await _profileService.fetchAllPosts();
      await fetchItineraryByPost(); // Đảm bảo chờ lấy itinerary
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoadingUser = false;
        _isRefreshing = false;
        _isLoadingItinerary = false;
      });
    }
  }

  Future<void> fetchItineraryByPost() async {
    Map<int, Itinerary> itineraryMap = {};

    for (var post in _posts) {
      if (post.itineraryId != null) {
        try {
          Itinerary itinerary =
              await ItineraryApi().getItineraryById(post.itineraryId!);
          // Kiểm tra xem itinerary có dữ liệu hợp lệ không
          if (itinerary.title != null &&
              itinerary.title!.isNotEmpty &&
              (itinerary.locations?.isNotEmpty ?? false)) {
            itineraryMap[post.id] = itinerary;
            print(
                'Added valid itinerary for post ${post.id}: ${itinerary.title}');
          } else {
            print('Skipping invalid/empty itinerary for post ${post.id}');
          }
        } catch (e) {
          print('Error fetching itinerary for post ${post.id}: $e');
        }
      } else {
        print('Post ${post.id} has no itineraryId, skipping...');
      }
    }

    setState(() {
      _itineraryByPost = itineraryMap;
      print("itineraryId$itineraryMap");
    });
  }

  Future<void> _refreshPosts() async {
    setState(() => _isRefreshing = true);
    try {
      _posts = await _profileService.fetchAllPosts();
      await fetchItineraryByPost(); // Làm mới cả itinerary
    } catch (e) {
      print('Error refreshing posts: $e');
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  void _handleCommentAdded(Post post, Comment newComment) {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = post.copyWith(
          comments: [...post.comments, newComment],
          commentCount: post.commentCount + 1,
        );
      }
    });
  }

  void _handleCommentUpdated(Post post, Comment updatedComment) {
    setState(() {
      final postIndex = _posts.indexWhere((p) => p.id == post.id);
      if (postIndex != -1) {
        final commentIndex = _posts[postIndex]
            .comments
            .indexWhere((c) => c.id == updatedComment.id);
        if (commentIndex != -1) {
          List<Comment> updatedComments = List.from(_posts[postIndex].comments);
          updatedComments[commentIndex] = updatedComment;
          _posts[postIndex] =
              _posts[postIndex].copyWith(comments: updatedComments);
        }
      }
    });
  }

  void _handleCommentDeleted(Post post, int commentId) {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        List<Comment> updatedComments =
            _posts[index].comments.where((c) => c.id != commentId).toList();
        _posts[index] = _posts[index].copyWith(
          comments: updatedComments,
          commentCount: _posts[index].commentCount - 1,
        );
      }
    });
  }

  void _handleLikeToggled(Post post) async {
    if (_currentUser == null) return;

    final bool isLiked =
        post.likes.any((like) => like.userId == _currentUser!.id);
    final List<Like> updatedLikes = List.from(post.likes);
    final int updatedLikeCount =
        isLiked ? post.likeCount - 1 : post.likeCount + 1;

    setState(() {
      if (isLiked) {
        updatedLikes.removeWhere((like) => like.userId == _currentUser!.id);
      } else {
        updatedLikes.add(Like(
          id: 0,
          postId: post.id,
          userId: _currentUser!.id,
          userEmail: _currentUser!.email,
          createdAt: DateTime.now(),
        ));
      }

      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = post.copyWith(
          likes: updatedLikes,
          likeCount: updatedLikeCount,
        );
      }
    });

    try {
      await _profileService.toggleLike(post.id);
    } catch (e) {
      print('Error toggling like: $e');
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          if (isLiked) {
            updatedLikes.add(Like(
              id: 0,
              postId: post.id,
              userId: _currentUser!.id,
              userEmail: _currentUser!.email,
              createdAt: DateTime.now(),
            ));
          } else {
            updatedLikes.removeWhere((like) => like.userId == _currentUser!.id);
          }
          _posts[index] = post.copyWith(
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

  void _createNewPost() {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Unable to load user profile. Please try again.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMomentScreen(
          userName: _currentUser!.full_name,
          userLocation: _currentUser!.address ?? 'Hoi An, Quang Nam, Vietnam',
          userAvatar:
              _currentUser!.avatar ?? 'https://example.com/default-avatar.jpg',
        ),
      ),
    ).then((_) => _refreshPosts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Moments'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _isLoadingUser ? null : _createNewPost,
            tooltip: 'Create Post',
          ),
        ],
      ),
      body: _isLoadingUser
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshPosts,
              child: _isRefreshing
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        return PostCard(
                          post: _posts[index],
                          currentUserId: _currentUser?.id ?? 0,
                          itineraryByPost: _itineraryByPost ?? {},
                          onCommentAdded: _handleCommentAdded,
                          onCommentUpdated: _handleCommentUpdated,
                          onCommentDeleted: _handleCommentDeleted,
                          onLikeToggled: _handleLikeToggled,
                        );
                      },
                    ),
            ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;
  final int currentUserId;
  final Map<int, Itinerary> itineraryByPost;
  final Function(Post, Comment) onCommentAdded;
  final Function(Post, Comment) onCommentUpdated;
  final Function(Post, int) onCommentDeleted;
  final Function(Post) onLikeToggled;

  const PostCard({
    required this.post,
    required this.currentUserId,
    required this.itineraryByPost,
    required this.onCommentAdded,
    required this.onCommentUpdated,
    required this.onCommentDeleted,
    required this.onLikeToggled,
  });

  bool _isLikedByCurrentUser() {
    return post.likes.any((like) => like.userId == currentUserId);
  }

  String getFeelingEmoji(String feeling) {
    Map<String, String> feelings = {
      "Happy": "😊",
      "Sad": "😢",
      "Excited": "🤩",
      "Angry": "😡",
      "Love": "😍",
      "Surprised": "😲",
      "Tired": "😴",
    };
    return feelings[feeling] ?? "😊";
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('MMM d, yyyy • h:mm a')
        .format(DateTime.parse(post.createdAt));
    return Card(
      shape: Border(),
      margin: EdgeInsets.only(bottom: 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(post.avatar)),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(post.userName,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(
                        width: 5,
                      ),
                      if (post.emotion != null && post.emotion!.isNotEmpty)
                        Row(
                          children: [
                            Text(
                              "is feeling ${post.emotion}",
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(width: 4),
                            Text(
                              getFeelingEmoji(post.emotion!),
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(height: 5),
                      Text(formattedDate,
                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  )
                ],
              ),
            ],
          ),
          SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.content.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 0.0),
                    child: Text(post.content),
                  ),
                if (itineraryByPost.containsKey(post.id) &&
                    itineraryByPost[post.id] != null)
                  _buildTripCard(itineraryByPost[post.id]!),
                if (post.images.isNotEmpty)
                  _buildImageGrid(post.images, context),
                Divider(height: 10),
                _buildPostActions(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<PostImage> images, BuildContext context) {
    List<PostImage> limitedImages = images.take(6).toList();
    bool hasMoreImages = images.length > 6;

    if (limitedImages.isEmpty) return SizedBox();

    return Column(
      children: [
        SizedBox(height: 5,),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
          ),
          itemCount: hasMoreImages ? 6 : limitedImages.length,
          itemBuilder: (context, index) {
            if (index == 5 && hasMoreImages) {
              return GestureDetector(
                onTap: () {
                  _openImageGallery(images, 5, context);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        limitedImages[5].content,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child:
                                Center(child: Icon(Icons.image_not_supported)),
                          );
                        },
                      ),
                      Container(color: Colors.black54),
                      Center(
                        child: Text(
                          '+${images.length - 6}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return GestureDetector(
              onTap: () {
                _openImageGallery(images, index, context);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: Image.network(
                  limitedImages[index].content,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Center(child: Icon(Icons.image_not_supported)),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _openImageGallery(
      List<PostImage> images, int initialIndex, BuildContext context) {
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
              heroAttributes:
                  PhotoViewHeroAttributes(tag: images[index].content),
            );
          },
          scrollPhysics: BouncingScrollPhysics(),
          backgroundDecoration: BoxDecoration(color: Colors.black),
          pageController: PageController(initialPage: initialIndex),
        ),
      ),
    );
  }

  Widget _buildPostActions(BuildContext context) {
    final bool isLiked = _isLikedByCurrentUser();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : null,
              ),
              onPressed: () => onLikeToggled(post),
            ),
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
                  onCommentAdded: (newComment) =>
                      onCommentAdded(post, newComment),
                  onCommentUpdated: (updatedComment) =>
                      onCommentUpdated(post, updatedComment),
                  onCommentDeleted: (commentId) =>
                      onCommentDeleted(post, commentId),
                ),
              ),
            );
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
    );
  }

  Widget _buildTripCard(Itinerary trip) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 2, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: trip.locations.isNotEmpty
                ? Image.network(
                    trip.locations
                            .firstWhere(
                              (location) =>
                                  location.image != null &&
                                  location.image!.isNotEmpty,
                            )
                            .image ??
                        '',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(Icons.image, color: Colors.grey),
                  ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.title ?? '',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                trip.init_date != null
                    ? Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(
                            trip.init_date.toString(),
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      )
                    : SizedBox(),
                trip.price != null
                    ? Row(
                        children: [
                          Icon(Icons.attach_money,
                              size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(
                            trip.price.toString(),
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      )
                    : SizedBox(),
                SizedBox(height: 4),
                trip.locations.isNotEmpty
                    ? Row(
                        children: [
                          Icon(Icons.place, size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(
                            "${trip.locations.length} Destinations",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      )
                    : SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
