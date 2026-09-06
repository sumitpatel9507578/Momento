class ReelModel {
  final String id;
  final String userId;
  final String videoUrl;
  final String caption;
  final String songId;
  final List<String> likes;

  // Pexels fields
  final String creatorName;
  final String thumbnail;
  final String pexelsUrl;

  ReelModel({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.caption,
    required this.songId,
    required this.likes,
    this.creatorName = '',
    this.thumbnail = '',
    this.pexelsUrl = '',
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    // Pexels ke video_files
    final List videoFiles = json['video_files'] ?? [];

    String videoUrl = '';

    // Pehle portrait video dhoondhenge
    for (final file in videoFiles) {
      final width = file['width'] ?? 0;
      final height = file['height'] ?? 0;
      final link = file['link'] ?? '';

      if (height > width && link.isNotEmpty) {
        videoUrl = link;
        break;
      }
    }

    // Agar portrait nahi mila to first video
    if (videoUrl.isEmpty && videoFiles.isNotEmpty) {
      videoUrl = videoFiles.first['link'] ?? '';
    }

    final user = json['user'] ?? {};

    return ReelModel(
      id: json['id']?.toString() ?? '',
      userId: user['id']?.toString() ?? '',
      videoUrl: videoUrl,
      caption: '',
      songId: '',
      likes: const [],
      creatorName: user['name'] ?? 'Pexels Creator',
      thumbnail: json['image'] ?? '',
      pexelsUrl: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'videoUrl': videoUrl,
      'caption': caption,
      'songId': songId,
      'likes': likes,
      'creatorName': creatorName,
      'thumbnail': thumbnail,
      'pexelsUrl': pexelsUrl,
    };
  }
}
