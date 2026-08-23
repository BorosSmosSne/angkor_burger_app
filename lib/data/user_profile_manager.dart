import 'package:angkor_burger_app/models/user_profile_model.dart';
import 'package:flutter/foundation.dart';

/// Global manager for reactive User Profile state.
class UserProfileManager {
  static final ValueNotifier<UserProfileModel> profileNotifier =
      ValueNotifier<UserProfileModel>(
    UserProfileModel(
      name: 'Boros Smos Sne',
      phone: '+855 12 345 678',
      email: 'boros.burger@gmail.com',
      address: 'Street 2004, Sen Sok, Phnom Penh',
      gender: 'Male',
      dateOfBirth: '2004-05-15',
      avatarEmoji: '👑',
      profileImagePath: null,
      profileImageBytes: null,
      rewardPoints: 150,
      membershipTier: 'Gold Member',
    ),
  );

  static UserProfileModel get currentProfile => profileNotifier.value;

  static void updateProfile({
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
    profileNotifier.value = profileNotifier.value.copyWith(
      name: name,
      phone: phone,
      email: email,
      address: address,
      gender: gender,
      dateOfBirth: dateOfBirth,
      avatarEmoji: avatarEmoji,
      profileImagePath: profileImagePath,
      profileImageBytes: profileImageBytes,
      clearProfileImage: clearProfileImage,
      rewardPoints: rewardPoints,
      membershipTier: membershipTier,
    );
  }

  static void updateAddress(String newAddress) {
    profileNotifier.value = profileNotifier.value.copyWith(address: newAddress);
  }

  static void updateProfileImage(String? imagePath, {Uint8List? imageBytes}) {
    profileNotifier.value = profileNotifier.value.copyWith(
      profileImagePath: imagePath,
      profileImageBytes: imageBytes,
      clearProfileImage: imagePath == null && imageBytes == null,
    );
  }
}
