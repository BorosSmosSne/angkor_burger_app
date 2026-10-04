import 'package:angkor_burger_app/models/user_profile_model.dart';
import 'package:angkor_burger_app/services/rest_api.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Global manager for reactive User Profile state.
class UserProfileManager {
  static final ValueNotifier<UserProfileModel> profileNotifier =
      ValueNotifier<UserProfileModel>(
    UserProfileModel(
      name: 'User',
      phone: '',
      email: '',
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

// 👈 2. Add this initialization helper:
  static void initFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final displayName =
          (user.displayName != null && user.displayName!.trim().isNotEmpty)
              ? user.displayName!.trim()
              : (user.email?.split('@').first ?? 'User');
      final email = user.email ?? '';
      final phone = user.phoneNumber ?? '';

      updateProfile(
        name: displayName,
        email: email,
        phone: phone,
      );
      // 2. Fetch the persisted profile (phone, address, etc.) from Laravel MySQL
      if (email.isNotEmpty) {
        final backendUser = await RestApi.fetchUserProfile(email);
        if (backendUser != null) {
          updateProfile(
            name: (backendUser['name'] != null &&
                    backendUser['name'].toString().isNotEmpty)
                ? backendUser['name']
                : displayName,
            phone: (backendUser['phone'] != null &&
                    backendUser['phone'].toString().isNotEmpty)
                ? backendUser['phone']
                : phone,
            address: backendUser['address'] ?? currentProfile.address,
            gender: backendUser['gender'] ?? currentProfile.gender,
            dateOfBirth:
                backendUser['date_of_birth'] ?? currentProfile.dateOfBirth,
          );
        }
      }
    }
  }

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
