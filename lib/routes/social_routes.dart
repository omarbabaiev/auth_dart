import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/social_service.dart';
import '../services/auth_service.dart';
import '../middleware/auth_middleware.dart';

Router createSocialRoutes() {
  final router = Router();

  // Posts
  router.post('/posts', authMiddleware(_createPostHandler));
  router.get('/posts', authMiddleware(_getFeedHandler));
  router.get('/posts/user/<userId>', authMiddleware(_getUserPostsHandler));
  router.get('/posts/<postId>', authMiddleware(_getPostHandler));
  router.put('/posts/<postId>', authMiddleware(_updatePostHandler));
  router.delete('/posts/<postId>', authMiddleware(_deletePostHandler));

  // Comments
  router.post(
    '/posts/<postId>/comments',
    authMiddleware(_createCommentHandler),
  );
  router.get('/posts/<postId>/comments', authMiddleware(_getCommentsHandler));

  // Likes
  router.post('/posts/<postId>/like', authMiddleware(_likePostHandler));
  router.delete('/posts/<postId>/like', authMiddleware(_unlikePostHandler));
  router.post(
    '/comments/<commentId>/like',
    authMiddleware(_likeCommentHandler),
  );
  router.delete(
    '/comments/<commentId>/like',
    authMiddleware(_unlikeCommentHandler),
  );

  // Follows
  router.post('/users/<userId>/follow', authMiddleware(_followUserHandler));
  router.delete('/users/<userId>/follow', authMiddleware(_unfollowUserHandler));
  router.get('/users/<userId>/followers', authMiddleware(_getFollowersHandler));
  router.get('/users/<userId>/following', authMiddleware(_getFollowingHandler));

  return router;
}

// Post Handlers
Future<Response> _createPostHandler(Request request) async {
  try {
    final userId = request.headers['user-id'];
    if (userId == null) {
      return Response(
        401,
        body: jsonEncode({
          'success': false,
          'message': 'User ID not found',
          'key': 'auth.user.not_authenticated',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final content = data['content']?.toString();
    final imageUrl = data['image_url']?.toString();
    final hashtags = data['hashtags'] as List<dynamic>?;
    final isPublic = data['is_public'] as bool? ?? true;

    if (content == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Content is required',
          'key': 'social.post.content.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final response = SocialService.createPost(
      userId: int.parse(userId),
      content: content,
      imageUrl: imageUrl,
      hashtags: hashtags?.cast<String>(),
      isPublic: isPublic,
    );

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'social.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _getFeedHandler(Request request) async {
  try {
    final userId = request.headers['user-id'];
    if (userId == null) {
      return Response(
        401,
        body: jsonEncode({
          'success': false,
          'message': 'User ID not found',
          'key': 'auth.user.not_authenticated',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final limit =
        int.tryParse(request.url.queryParameters['limit'] ?? '20') ?? 20;
    final offset =
        int.tryParse(request.url.queryParameters['offset'] ?? '0') ?? 0;

    final response = SocialService.getFeed(
      int.parse(userId),
      limit: limit,
      offset: offset,
    );

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'social.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _getUserPostsHandler(Request request) async {
  try {
    final userId = request.headers['user-id'];
    if (userId == null) {
      return Response(
        401,
        body: jsonEncode({
          'success': false,
          'message': 'User ID not found',
          'key': 'auth.user.not_authenticated',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final targetUserId = request.params['userId'];
    if (targetUserId == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'User ID parameter is required',
          'key': 'social.user.id.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final limit =
        int.tryParse(request.url.queryParameters['limit'] ?? '20') ?? 20;
    final offset =
        int.tryParse(request.url.queryParameters['offset'] ?? '0') ?? 0;

    final response = SocialService.getUserPosts(
      int.parse(targetUserId),
      limit: limit,
      offset: offset,
    );

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'social.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _getPostHandler(Request request) async {
  try {
    final postId = request.params['postId'];
    if (postId == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Post ID is required',
          'key': 'social.post.id.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    // This would need a getPostById method in SocialService
    // For now, return a placeholder response
    return Response(
      200,
      body: jsonEncode({
        'success': true,
        'message': 'Post retrieved successfully',
        'key': 'social.post.get.success',
      }),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'social.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _updatePostHandler(Request request) async {
  try {
    final userId = request.headers['user-id'];
    if (userId == null) {
      return Response(
        401,
        body: jsonEncode({
          'success': false,
          'message': 'User ID not found',
          'key': 'auth.user.not_authenticated',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final postId = request.params['postId'];
    if (postId == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Post ID is required',
          'key': 'social.post.id.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final content = data['content']?.toString();
    final imageUrl = data['image_url']?.toString();
    final hashtags = data['hashtags'] as List<dynamic>?;
    final isPublic = data['is_public'] as bool?;

    if (content == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Content is required',
          'key': 'social.post.content.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final response = SocialService.updatePost(
      postId: int.parse(postId),
      userId: int.parse(userId),
      content: content,
      imageUrl: imageUrl,
      hashtags: hashtags?.cast<String>(),
      isPublic: isPublic,
    );

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'social.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _deletePostHandler(Request request) async {
  try {
    final userId = request.headers['user-id'];
    if (userId == null) {
      return Response(
        401,
        body: jsonEncode({
          'success': false,
          'message': 'User ID not found',
          'key': 'auth.user.not_authenticated',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final postId = request.params['postId'];
    if (postId == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Post ID is required',
          'key': 'social.post.id.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final response = SocialService.deletePost(
      int.parse(postId),
      int.parse(userId),
    );

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'social.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

// Comment Handlers
Future<Response> _createCommentHandler(Request request) async {
  try {
    final userId = request.headers['user-id'];
    if (userId == null) {
      return Response(
        401,
        body: jsonEncode({
          'success': false,
          'message': 'User ID not found',
          'key': 'auth.user.not_authenticated',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final postId = request.params['postId'];
    if (postId == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Post ID is required',
          'key': 'social.post.id.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final content = data['content']?.toString();
    final parentCommentId = data['parent_comment_id'] as int?;

    if (content == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Content is required',
          'key': 'social.comment.content.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final response = SocialService.createComment(
      postId: int.parse(postId),
      userId: int.parse(userId),
      content: content,
      parentCommentId: parentCommentId,
    );

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'social.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _getCommentsHandler(Request request) async {
  try {
    final postId = request.params['postId'];
    if (postId == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Post ID is required',
          'key': 'social.post.id.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final limit =
        int.tryParse(request.url.queryParameters['limit'] ?? '50') ?? 50;
    final offset =
        int.tryParse(request.url.queryParameters['offset'] ?? '0') ?? 0;

    final response = SocialService.getPostComments(
      int.parse(postId),
      limit: limit,
      offset: offset,
    );

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'social.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

// Like Handlers
Future<Response> _likePostHandler(Request request) async {
  try {
    final userId = request.headers['user-id'];
    if (userId == null) {
      return Response(
        401,
        body: jsonEncode({
          'success': false,
          'message': 'User ID not found',
          'key': 'auth.user.not_authenticated',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final postId = request.params['postId'];
    if (postId == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Post ID is required',
          'key': 'social.post.id.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final response = SocialService.likePost(
      int.parse(userId),
      int.parse(postId),
    );

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'social.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _unlikePostHandler(Request request) async {
  try {
    final userId = request.headers['user-id'];
    if (userId == null) {
      return Response(
        401,
        body: jsonEncode({
          'success': false,
          'message': 'User ID not found',
          'key': 'auth.user.not_authenticated',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final postId = request.params['postId'];
    if (postId == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Post ID is required',
          'key': 'social.post.id.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final response = SocialService.unlikePost(
      int.parse(userId),
      int.parse(postId),
    );

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'social.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _likeCommentHandler(Request request) async {
  try {
    final userId = request.headers['user-id'];
    if (userId == null) {
      return Response(
        401,
        body: jsonEncode({
          'success': false,
          'message': 'User ID not found',
          'key': 'auth.user.not_authenticated',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final commentId = request.params['commentId'];
    if (commentId == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Comment ID is required',
          'key': 'social.comment.id.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final response = SocialService.likeComment(
      int.parse(userId),
      int.parse(commentId),
    );

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'social.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _unlikeCommentHandler(Request request) async {
  try {
    final userId = request.headers['user-id'];
    if (userId == null) {
      return Response(
        401,
        body: jsonEncode({
          'success': false,
          'message': 'User ID not found',
          'key': 'auth.user.not_authenticated',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final commentId = request.params['commentId'];
    if (commentId == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Comment ID is required',
          'key': 'social.comment.id.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final response = SocialService.unlikeComment(
      int.parse(userId),
      int.parse(commentId),
    );

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'social.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

// Follow Handlers
Future<Response> _followUserHandler(Request request) async {
  try {
    final userId = request.headers['user-id'];
    if (userId == null) {
      return Response(
        401,
        body: jsonEncode({
          'success': false,
          'message': 'User ID not found',
          'key': 'auth.user.not_authenticated',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final targetUserId = request.params['userId'];
    if (targetUserId == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Target user ID is required',
          'key': 'social.user.target_id.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final response = SocialService.followUser(
      int.parse(userId),
      int.parse(targetUserId),
    );

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'social.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _unfollowUserHandler(Request request) async {
  try {
    final userId = request.headers['user-id'];
    if (userId == null) {
      return Response(
        401,
        body: jsonEncode({
          'success': false,
          'message': 'User ID not found',
          'key': 'auth.user.not_authenticated',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final targetUserId = request.params['userId'];
    if (targetUserId == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'Target user ID is required',
          'key': 'social.user.target_id.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final response = SocialService.unfollowUser(
      int.parse(userId),
      int.parse(targetUserId),
    );

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'social.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _getFollowersHandler(Request request) async {
  try {
    final userId = request.params['userId'];
    if (userId == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'User ID is required',
          'key': 'social.user.id.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final response = SocialService.getFollowers(int.parse(userId));

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'social.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<Response> _getFollowingHandler(Request request) async {
  try {
    final userId = request.params['userId'];
    if (userId == null) {
      return Response(
        400,
        body: jsonEncode({
          'success': false,
          'message': 'User ID is required',
          'key': 'social.user.id.required',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final response = SocialService.getFollowing(int.parse(userId));

    return Response(
      response.statusCode ?? 200,
      body: jsonEncode(response.toJson()),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response(
      500,
      body: jsonEncode({
        'success': false,
        'message': 'Server error: $e',
        'key': 'social.server.error',
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}
