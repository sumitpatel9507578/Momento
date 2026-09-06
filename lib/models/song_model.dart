class SongModel {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String thumbnailUrl;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.thumbnailUrl,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'audioUrl': audioUrl,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}
