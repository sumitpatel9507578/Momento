import 'editor_layer.dart';

class StoryDraft {
  final String mediaPath;
  final String mediaType; // 'image' or 'video'
  final List<EditorLayer> layers;
  final Map<String, dynamic>? selectedMusic;
  final List<String> mentions;
  final String selectedFilter;
  final bool isAiGenerated;
  final bool isCloseFriends;
  final List<String> hideFromUserIds;
  final bool allowReplies;
  final bool allowSharing;
  final String altText;

  StoryDraft({
    required this.mediaPath,
    required this.mediaType,
    required this.layers,
    this.selectedMusic,
    required this.mentions,
    this.selectedFilter = 'Normal',
    this.isAiGenerated = false,
    this.isCloseFriends = false,
    required this.hideFromUserIds,
    this.allowReplies = true,
    this.allowSharing = true,
    this.altText = '',
  });

  Map<String, dynamic> toJson() => {
        'mediaPath': mediaPath,
        'mediaType': mediaType,
        'layers': layers.map((l) => l.toJson()).toList(),
        'selectedMusic': selectedMusic,
        'mentions': mentions,
        'selectedFilter': selectedFilter,
        'isAiGenerated': isAiGenerated,
        'isCloseFriends': isCloseFriends,
        'hideFromUserIds': hideFromUserIds,
        'allowReplies': allowReplies,
        'allowSharing': allowSharing,
        'altText': altText,
      };
}
