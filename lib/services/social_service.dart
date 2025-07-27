import '../models/post.dart';
import '../models/comment.dart';
import '../models/follow.dart';
import '../models/like.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import 'database_service.dart';

class SocialService {
  // Posts
  static AuthResponse createPost({
    required int userId,
    required String content,
    String? imageUrl,
    List<String>? hashtags,
    bool isPublic = true,
  }) {
    if (content.trim().isEmpty) {
      return AuthResponse.error(
        message: 'Post content cannot be empty',
        key: 'social.post.content.empty',
        statusCode: 400,
      );
    }

    if (content.length > 1000) {
      return AuthResponse.error(
        message: 'Post content is too long (max 1000 characters)',
        key: 'social.post.content.too_long',
        statusCode: 400,
      );
    }

    try {
      final post = Post(
        userId: userId,
        content: content.trim(),
        imageUrl: imageUrl,
        hashtags: hashtags,
        isPublic: isPublic,
        createdAt: DateTime.now(),
      );

      final postId = DatabaseService.createPost(post);
      final createdPost = DatabaseService.getPostById(postId);

      if (createdPost == null) {
        return AuthResponse.error(
          message: 'Failed to create post',
          key: 'social.post.create.failed',
          statusCode: 500,
        );
      }

      return AuthResponse.success(
        message: 'Post created successfully',
        key: 'social.post.create.success',
        user: createdPost.toJson(),
      );
    } catch (e) {
      return AuthResponse.error(
        message: 'Failed to create post: $e',
        key: 'social.post.create.error',
        statusCode: 500,
      );
    }
  }

  static AuthResponse getFeed(int userId, {int limit = 20, int offset = 0}) {
    try {
      final posts = DatabaseService.getFeedPosts(
        userId,
        limit: limit,
        offset: offset,
      );

      return AuthResponse.success(
        message: 'Feed retrieved successfully',
        key: 'social.feed.get.success',
        user: {
          'posts': posts.map((post) => post.toJson()).toList(),
          'total': posts.length,
        },
      );
    } catch (e) {
      return AuthResponse.error(
        message: 'Failed to get feed: $e',
        key: 'social.feed.get.error',
        statusCode: 500,
      );
    }
  }

  static AuthResponse getUserPosts(
    int userId, {
    int limit = 20,
    int offset = 0,
  }) {
    try {
      final posts = DatabaseService.getPostsByUserId(
        userId,
        limit: limit,
        offset: offset,
      );

      return AuthResponse.success(
        message: 'User posts retrieved successfully',
        key: 'social.posts.user.success',
        user: {
          'posts': posts.map((post) => post.toJson()).toList(),
          'total': posts.length,
        },
      );
    } catch (e) {
      return AuthResponse.error(
        message: 'Failed to get user posts: $e',
        key: 'social.posts.user.error',
        statusCode: 500,
      );
    }
  }

  static AuthResponse updatePost({
    required int postId,
    required int userId,
    required String content,
    String? imageUrl,
    List<String>? hashtags,
    bool? isPublic,
  }) {
    // Check if post exists and belongs to user
    final post = DatabaseService.getPostById(postId);
    if (post == null) {
      return AuthResponse.error(
        message: 'Post not found',
        key: 'social.post.not_found',
        statusCode: 404,
      );
    }

    if (post.userId != userId) {
      return AuthResponse.error(
        message: 'You can only edit your own posts',
        key: 'social.post.edit.unauthorized',
        statusCode: 403,
      );
    }

    if (content.trim().isEmpty) {
      return AuthResponse.error(
        message: 'Post content cannot be empty',
        key: 'social.post.content.empty',
        statusCode: 400,
      );
    }

    try {
      final updates = <String, dynamic>{
        'content': content.trim(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_edited': 1,
      };

      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (hashtags != null) updates['hashtags'] = hashtags.join(',');
      if (isPublic != null) updates['is_public'] = isPublic ? 1 : 0;

      final success = DatabaseService.updatePost(postId, updates);

      if (success) {
        final updatedPost = DatabaseService.getPostById(postId);
        return AuthResponse.success(
          message: 'Post updated successfully',
          key: 'social.post.update.success',
          user: updatedPost?.toJson(),
        );
      } else {
        return AuthResponse.error(
          message: 'Failed to update post',
          key: 'social.post.update.failed',
          statusCode: 500,
        );
      }
    } catch (e) {
      return AuthResponse.error(
        message: 'Failed to update post: $e',
        key: 'social.post.update.error',
        statusCode: 500,
      );
    }
  }

  static AuthResponse deletePost(int postId, int userId) {
    final post = DatabaseService.getPostById(postId);
    if (post == null) {
      return AuthResponse.error(
        message: 'Post not found',
        key: 'social.post.not_found',
        statusCode: 404,
      );
    }

    if (post.userId != userId) {
      return AuthResponse.error(
        message: 'You can only delete your own posts',
        key: 'social.post.delete.unauthorized',
        statusCode: 403,
      );
    }

    try {
      final success = DatabaseService.deletePost(postId);

      if (success) {
        return AuthResponse.success(
          message: 'Post deleted successfully',
          key: 'social.post.delete.success',
        );
      } else {
        return AuthResponse.error(
          message: 'Failed to delete post',
          key: 'social.post.delete.failed',
          statusCode: 500,
        );
      }
    } catch (e) {
      return AuthResponse.error(
        message: 'Failed to delete post: $e',
        key: 'social.post.delete.error',
        statusCode: 500,
      );
    }
  }

  // Comments
  static AuthResponse createComment({
    required int postId,
    required int userId,
    required String content,
    int? parentCommentId,
  }) {
    if (content.trim().isEmpty) {
      return AuthResponse.error(
        message: 'Comment content cannot be empty',
        key: 'social.comment.content.empty',
        statusCode: 400,
      );
    }

    if (content.length > 500) {
      return AuthResponse.error(
        message: 'Comment content is too long (max 500 characters)',
        key: 'social.comment.content.too_long',
        statusCode: 400,
      );
    }

    // Check if post exists
    final post = DatabaseService.getPostById(postId);
    if (post == null) {
      return AuthResponse.error(
        message: 'Post not found',
        key: 'social.post.not_found',
        statusCode: 404,
      );
    }

    try {
      final comment = Comment(
        postId: postId,
        userId: userId,
        content: content.trim(),
        parentCommentId: parentCommentId,
        createdAt: DateTime.now(),
      );

      final commentId = DatabaseService.createComment(comment);
      final createdComment = DatabaseService.getCommentsByPostId(
        postId,
      ).firstWhere((c) => c.id == commentId);

      // Update post comment count
      DatabaseService.updatePost(postId, {
        'comment_count': post.commentCount + 1,
      });

      return AuthResponse.success(
        message: 'Comment created successfully',
        key: 'social.comment.create.success',
        user: createdComment.toJson(),
      );
    } catch (e) {
      return AuthResponse.error(
        message: 'Failed to create comment: $e',
        key: 'social.comment.create.error',
        statusCode: 500,
      );
    }
  }

  static AuthResponse getPostComments(
    int postId, {
    int limit = 50,
    int offset = 0,
  }) {
    try {
      final comments = DatabaseService.getCommentsByPostId(
        postId,
        limit: limit,
        offset: offset,
      );

      return AuthResponse.success(
        message: 'Comments retrieved successfully',
        key: 'social.comments.get.success',
        user: {
          'comments': comments.map((comment) => comment.toJson()).toList(),
          'total': comments.length,
        },
      );
    } catch (e) {
      return AuthResponse.error(
        message: 'Failed to get comments: $e',
        key: 'social.comments.get.error',
        statusCode: 500,
      );
    }
  }

  // Likes
  static AuthResponse likePost(int userId, int postId) {
    try {
      final success = DatabaseService.likePost(userId, postId);

      if (success) {
        return AuthResponse.success(
          message: 'Post liked successfully',
          key: 'social.post.like.success',
        );
      } else {
        return AuthResponse.error(
          message: 'Post already liked',
          key: 'social.post.like.already_liked',
          statusCode: 409,
        );
      }
    } catch (e) {
      return AuthResponse.error(
        message: 'Failed to like post: $e',
        key: 'social.post.like.error',
        statusCode: 500,
      );
    }
  }

  static AuthResponse unlikePost(int userId, int postId) {
    try {
      final success = DatabaseService.unlikePost(userId, postId);

      if (success) {
        return AuthResponse.success(
          message: 'Post unliked successfully',
          key: 'social.post.unlike.success',
        );
      } else {
        return AuthResponse.error(
          message: 'Post not liked',
          key: 'social.post.unlike.not_liked',
          statusCode: 404,
        );
      }
    } catch (e) {
      return AuthResponse.error(
        message: 'Failed to unlike post: $e',
        key: 'social.post.unlike.error',
        statusCode: 500,
      );
    }
  }

  static AuthResponse likeComment(int userId, int commentId) {
    try {
      final success = DatabaseService.likeComment(userId, commentId);

      if (success) {
        return AuthResponse.success(
          message: 'Comment liked successfully',
          key: 'social.comment.like.success',
        );
      } else {
        return AuthResponse.error(
          message: 'Comment already liked',
          key: 'social.comment.like.already_liked',
          statusCode: 409,
        );
      }
    } catch (e) {
      return AuthResponse.error(
        message: 'Failed to like comment: $e',
        key: 'social.comment.like.error',
        statusCode: 500,
      );
    }
  }

  static AuthResponse unlikeComment(int userId, int commentId) {
    try {
      final success = DatabaseService.unlikeComment(userId, commentId);

      if (success) {
        return AuthResponse.success(
          message: 'Comment unliked successfully',
          key: 'social.comment.unlike.success',
        );
      } else {
        return AuthResponse.error(
          message: 'Comment not liked',
          key: 'social.comment.unlike.not_liked',
          statusCode: 404,
        );
      }
    } catch (e) {
      return AuthResponse.error(
        message: 'Failed to unlike comment: $e',
        key: 'social.comment.unlike.error',
        statusCode: 500,
      );
    }
  }

  // Follows
  static AuthResponse followUser(int followerId, int followingId) {
    if (followerId == followingId) {
      return AuthResponse.error(
        message: 'You cannot follow yourself',
        key: 'social.follow.self',
        statusCode: 400,
      );
    }

    // Check if user exists
    final user = DatabaseService.getUserById(followingId);
    if (user == null) {
      return AuthResponse.error(
        message: 'User not found',
        key: 'social.user.not_found',
        statusCode: 404,
      );
    }

    try {
      final success = DatabaseService.followUser(followerId, followingId);

      if (success) {
        return AuthResponse.success(
          message: 'User followed successfully',
          key: 'social.follow.success',
        );
      } else {
        return AuthResponse.error(
          message: 'Already following this user',
          key: 'social.follow.already_following',
          statusCode: 409,
        );
      }
    } catch (e) {
      return AuthResponse.error(
        message: 'Failed to follow user: $e',
        key: 'social.follow.error',
        statusCode: 500,
      );
    }
  }

  static AuthResponse unfollowUser(int followerId, int followingId) {
    try {
      final success = DatabaseService.unfollowUser(followerId, followingId);

      if (success) {
        return AuthResponse.success(
          message: 'User unfollowed successfully',
          key: 'social.unfollow.success',
        );
      } else {
        return AuthResponse.error(
          message: 'Not following this user',
          key: 'social.unfollow.not_following',
          statusCode: 404,
        );
      }
    } catch (e) {
      return AuthResponse.error(
        message: 'Failed to unfollow user: $e',
        key: 'social.unfollow.error',
        statusCode: 500,
      );
    }
  }

  static AuthResponse getFollowers(int userId) {
    try {
      final followerIds = DatabaseService.getFollowers(userId);
      final followers = followerIds
          .map((id) => DatabaseService.getUserById(id))
          .whereType<User>()
          .toList();

      return AuthResponse.success(
        message: 'Followers retrieved successfully',
        key: 'social.followers.get.success',
        user: {
          'followers': followers.map((user) => user.toJson()).toList(),
          'count': followers.length,
        },
      );
    } catch (e) {
      return AuthResponse.error(
        message: 'Failed to get followers: $e',
        key: 'social.followers.get.error',
        statusCode: 500,
      );
    }
  }

  static AuthResponse getFollowing(int userId) {
    try {
      final followingIds = DatabaseService.getFollowing(userId);
      final following = followingIds
          .map((id) => DatabaseService.getUserById(id))
          .whereType<User>()
          .toList();

      return AuthResponse.success(
        message: 'Following retrieved successfully',
        key: 'social.following.get.success',
        user: {
          'following': following.map((user) => user.toJson()).toList(),
          'count': following.length,
        },
      );
    } catch (e) {
      return AuthResponse.error(
        message: 'Failed to get following: $e',
        key: 'social.following.get.error',
        statusCode: 500,
      );
    }
  }
}
