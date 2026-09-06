import '../models/story_model.dart';

class FakeStoryService {
  final List<String> _storyImages = [
    'https://images.unsplash.com/photo-1518837695005-2083093ee35b',
    'https://images.unsplash.com/photo-1470770841072-f978cf4d019e',
    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b',
    'https://images.unsplash.com/photo-1472214103451-9374bd1c798e',
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
    'https://images.unsplash.com/photo-1439337153520-7082a56a81f4',
    'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d',
    'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05',
  ];

  Future<List<StoryModel>> fetchStories() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    return List.generate(8, (index) {
      return StoryModel(
        storyId: 'story_$index',
        userId: 'user_$index',
        username: _usernames[index],
        profileImage:
            'https://randomuser.me/api/portraits/${index % 2 == 0 ? 'women' : 'men'}/${index + 20}.jpg',
        mediaUrl: '${_storyImages[index]}?auto=format&fit=crop&w=1080&q=80',
        mediaType: 'image',
        timestamp: DateTime.now().subtract(Duration(minutes: index * 45)),
        viewed: false,
      );
    });
  }

  final List<String> _usernames = [
    'roshan_x',
    'priya_v',
    'aman_stories',
    'neha_capture',
    'kabir_wild',
    'sara_sun',
    'vikram_lens',
    'maya_glow',
  ];
}
