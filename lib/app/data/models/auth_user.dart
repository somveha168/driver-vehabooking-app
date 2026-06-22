/// Authenticated driver, as returned by the backend `UserResource`.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.uuid,
    required this.name,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.imageUrl,
    this.gender,
    this.dateOfBirth,
    this.currentAddress,
  });

  final int id;
  final String uuid;
  final String name;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? imageUrl;

  /// 'male' or 'female'.
  final String? gender;

  /// ISO date string (yyyy-MM-dd).
  final String? dateOfBirth;
  final String? currentAddress;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: (json['id'] as num).toInt(),
        uuid: json['uuid']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        firstName: json['first_name']?.toString(),
        lastName: json['last_name']?.toString(),
        phone: json['phone']?.toString(),
        email: json['email']?.toString(),
        imageUrl: json['image_url']?.toString(),
        gender: json['gender']?.toString(),
        dateOfBirth: json['date_of_birth']?.toString(),
        currentAddress: json['current_address']?.toString(),
      );

  AuthUser copyWith({
    String? name,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? imageUrl,
    String? gender,
    String? dateOfBirth,
    String? currentAddress,
  }) =>
      AuthUser(
        id: id,
        uuid: uuid,
        name: name ?? this.name,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        imageUrl: imageUrl ?? this.imageUrl,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        currentAddress: currentAddress ?? this.currentAddress,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'name': name,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'email': email,
        'image_url': imageUrl,
        'gender': gender,
        'date_of_birth': dateOfBirth,
        'current_address': currentAddress,
      };
}
