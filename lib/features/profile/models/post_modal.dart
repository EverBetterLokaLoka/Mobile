class Post {
  final int id;
  final String content;
  final int userId;
  final String userEmail;
  final String userName;
  final String createdAt;
  final String? updatedAt;
  final String avatar;
  final List<Comment> comments;
  final List<Like> likes;
  final List<PostImage> images;
  final int likeCount;
  final int commentCount;
  final bool destroyed;

  Post({
    required this.id,
    required this.content,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.createdAt,
    this.updatedAt,
    required this.avatar,
    required this.comments,
    required this.likes,
    required this.images,
    required this.likeCount,
    required this.commentCount,
    required this.destroyed,
  });

  Post copyWith({
    int? id,
    String? content,
    int? userId,
    String? userEmail,
    String? userName,
    String? createdAt,
    String? updatedAt,
    String? avatar,
    List<Comment>? comments,
    List<Like>? likes,
    List<PostImage>? images,
    int? likeCount,
    int? commentCount,
    bool? destroyed,
  }) {
    return Post(
      id: id ?? this.id,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      avatar: avatar ?? this.avatar,
      comments: comments ?? this.comments,
      likes: likes ?? this.likes,
      images: images ?? this.images,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      destroyed: destroyed ?? this.destroyed,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      userId: json['userId'] ?? 0,
      userEmail: json['userEmail'] ?? '',
      userName: json['userName'] ?? '',
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'],
      avatar: json['avatar'] ?? '',
      comments: (json['comments'] as List<dynamic>?)
          ?.map((comment) => Comment.fromJson(comment))
          .toList() ?? [],
      likes: (json['likes'] as List<dynamic>?)
          ?.map((like) => Like.fromJson(like))
          .toList() ?? [],
      images: (json['images'] as List<dynamic>?)
          ?.map((image) => PostImage.fromJson(image))
          .toList() ?? [],
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      destroyed: json['destroyed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'avatar': avatar,
      'comments': comments.map((c) => c.toJson()).toList(),
      'likes': likes.map((l) => l.toJson()).toList(),
      'images': images.map((i) => i.toJson()).toList(),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'destroyed': destroyed,
    };
  }
}

class Comment {
  final int id;
  final String content;
  final int postId;
  final int userId;
  final String userEmail;
  final String userName;
  final String createdAt;
  final String? updatedAt;
  final bool? destroyed;
  final String avatar;

  Comment({
    required this.id,
    required this.content,
    required this.postId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.createdAt,
    this.updatedAt,
    required this.destroyed,
    required this.avatar,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      postId: json['postId'] ?? 0,
      userId: json['userId'] ?? 0,
      userEmail: json['userEmail'] ?? '',
      userName: json['userName'] ?? '',
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'],
      destroyed: json['destroyed'] ?? false,
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'postId': postId,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'destroyed': destroyed,
      'avatar': avatar,
    };
  }
}

class Like {
  final int id;
  final int postId;
  final int userId;
  final String userEmail;
  final DateTime createdAt;

  Like({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userEmail,
    required this.createdAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'] ?? 0,
      postId: json['postId'] ?? 0,
      userId: json['userId'] ?? 0,
      userEmail: json['userEmail'] ?? 'unknown@example.com',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userEmail': userEmail,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class PostImage {
  final int id;
  final String content;
  final String? shares;
  final int? locationId;
  final int userId;
  final int postId;
  final int? mapId;
  final int? activityId;
  final String userEmail;
  final String type;
  final String? createdAt;
  final String? updatedAt;

  PostImage({
    required this.id,
    required this.content,
    this.shares,
    this.locationId,
    required this.userId,
    required this.postId,
    this.mapId,
    this.activityId,
    required this.userEmail,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory PostImage.fromJson(Map<String, dynamic> json) {
    return PostImage(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      shares: json['shares'],
      locationId: json['locationId'],
      userId: json['userId'] ?? 0,
      postId: json['postId'] ?? 0,
      mapId: json['mapId'],
      activityId: json['activityId'],
      userEmail: json['userEmail'] ?? '',
      type: json['type'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'shares': shares,
      'locationId': locationId,
      'userId': userId,
      'postId': postId,
      'mapId': mapId,
      'activityId': activityId,
      'userEmail': userEmail,
      'type': type,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}