class PlatformInfo {
  const PlatformInfo({
    this.name,
    this.description,
    this.logo,
    this.favicon,
    this.phone,
    this.email,
    this.address,
    this.facebookUrl,
    this.tiktokUrl,
    this.youtubeUrl,
    this.telegramUrl,
    this.termsUrl,
    this.privacyUrl,
  });

  final String? name;
  final String? description;
  final String? logo;
  final String? favicon;
  final String? phone;
  final String? email;
  final String? address;
  final String? facebookUrl;
  final String? tiktokUrl;
  final String? youtubeUrl;
  final String? telegramUrl;
  final String? termsUrl;
  final String? privacyUrl;

  bool get hasContact =>
      _hasValue(phone) ||
      _hasValue(email) ||
      _hasValue(address) ||
      _hasValue(telegramUrl) ||
      _hasValue(facebookUrl) ||
      _hasValue(youtubeUrl) ||
      _hasValue(tiktokUrl);

  factory PlatformInfo.fromJson(Map<String, dynamic> json) {
    final contact = _map(json['contact']);
    final socials = _map(json['socials']);
    final legal = _map(json['legal']);

    return PlatformInfo(
      name: _stringOrNull(json['name']),
      description: _stringOrNull(json['description']),
      logo: _stringOrNull(json['logo']),
      favicon: _stringOrNull(json['favicon']),
      phone: _stringOrNull(contact['phone']),
      email: _stringOrNull(contact['email']),
      address: _stringOrNull(contact['address']),
      facebookUrl: _stringOrNull(socials['facebook']),
      tiktokUrl: _stringOrNull(socials['tiktok']),
      youtubeUrl: _stringOrNull(socials['youtube']),
      telegramUrl: _stringOrNull(socials['telegram']),
      termsUrl: _stringOrNull(legal['terms_url']),
      privacyUrl: _stringOrNull(legal['privacy_url']),
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  static bool _hasValue(String? value) => value != null && value.isNotEmpty;

  static String? _stringOrNull(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
