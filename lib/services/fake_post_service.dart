import '../models/post_model.dart';

class FakePostService {
  final List<String> _mockImages = [
    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
    'https://images.unsplash.com/photo-1493246507139-91e8fad9978e',
    'https://images.unsplash.com/photo-1501785888041-af3ef285b470',
    'https://images.unsplash.com/photo-1511497584788-876760111969',
    'https://images.unsplash.com/photo-1441974231531-c6227db76b6e',
    'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429',
    'https://images.unsplash.com/photo-1518837695005-2083093ee35b',
    'https://images.unsplash.com/photo-1470770841072-f978cf4d019e',
    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b',
    'https://images.unsplash.com/photo-1472214103451-9374bd1c798e',
  ];

  Future<List<PostModel>> fetchPosts({int page = 1, int limit = 10}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    return List.generate(limit, (index) {
      final actualIndex = ((page - 1) * limit) + index;
      final imageIndex = actualIndex % _mockImages.length;

      return PostModel(
        postId: 'post_${actualIndex}_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user_${actualIndex % 5}',
        username: _usernames[actualIndex % _usernames.length],
        profileImage:
            'https://randomuser.me/api/portraits/${actualIndex % 2 == 0 ? 'men' : 'women'}/${actualIndex + 10}.jpg',
        mediaUrl: '${_mockImages[imageIndex]}?auto=format&fit=crop&w=1080&q=80',
        mediaType: 'image',
        caption: _captions[actualIndex % _captions.length],
        likesCount: 150 + (actualIndex * 42),
        commentsCount: 12 + actualIndex,
        isLiked: false,
        isSaved: false,
        isFollowing: actualIndex % 3 == 0,
        timestamp: DateTime.now().subtract(Duration(hours: actualIndex + 1)),
        location: actualIndex % 4 == 0 ? 'Mumbai, India' : null,
      );
    });
  }

  final List<String> _usernames = [
    'alex_explorer',
    'nature_vibes',
    'urban_pixel',
    'silent_traveler',
    'dreamy_lens',
    'velvet_soul',
    'cyan_horizon',
    'golden_hour',
    'mystic_road',
    'luna_capture',
  ];

  final List<String> _captions = [
    'Chasing sunsets and dreams. ✨ #Momento',
    'Lost in the beauty of nature. 🌲☁️',
    'City lights and late nights. 🌃',
    'Every corner has a story to tell. 📖',
    'Moments like these are forever. ❤️',
    'Breath in the fresh air. 🍃',
    'Staring into the infinite. 🌊',
    'Keep your head in the clouds. ☁️',
    'Simple things, big joy. 💫',
    'Adventure is out there! 🚀',
  ];
}
