import 'dart:typed_data';

/// Model representing user profile and personal information.
class UserProfileModel {
  final String name;
  final String phone;
  final String email;
  final String address;
  final String gender;
  final String dateOfBirth;
  final String avatarEmoji;
  final String? profileImagePath;
  final Uint8List? profileImageBytes;
  final int rewardPoints;
  final String membershipTier;

  UserProfileModel({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.gender = 'Male',
    this.dateOfBirth = '2004-05-15',
    this.avatarEmoji = '👑',
    this.profileImagePath,
    this.profileImageBytes,
    this.rewardPoints = 150,
    this.membershipTier = 'Gold Member',
  });

  UserProfileModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? gender,
    String? dateOfBirth,
    String? avatarEmoji,
    String? profileImagePath,
    Uint8List? profileImageBytes,
    bool clearProfileImage = false,
    int? rewardPoints,
    String? membershipTier,
  }) {
    return UserProfileModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      profileImagePath: clearProfileImage
          ? null
          : (profileImagePath ?? this.profileImagePath),
      profileImageBytes: clearProfileImage
          ? null
          : (profileImageBytes ?? this.profileImageBytes),
      rewardPoints: rewardPoints ?? this.rewardPoints,
      membershipTier: membershipTier ?? this.membershipTier,
    );
  }
}
