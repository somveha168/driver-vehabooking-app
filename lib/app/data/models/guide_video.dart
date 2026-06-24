class GuideVideo {
  const GuideVideo({
    required this.uuid,
    required this.title,
    this.url,
    this.description,
    this.embedUrl,
    this.provider,
    this.module = 'general',
  });

  final String uuid;
  final String title;
  final String? url;
  final String? description;
  final String? embedUrl;
  final String? provider;
  final String module;

  factory GuideVideo.fromJson(Map<String, dynamic> json) {
    return GuideVideo(
      uuid: json['uuid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      url: json['url']?.toString(),
      embedUrl: json['embed_url']?.toString(),
      provider: json['provider']?.toString(),
      module: json['module']?.toString() ?? 'general',
    );
  }
}
