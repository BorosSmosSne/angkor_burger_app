import 'dart:typed_data';
import 'package:angkor_burger_app/core/contants.dart';
import 'package:angkor_burger_app/data/user_profile_manager.dart';
import 'package:angkor_burger_app/helpers/angkor_app_bar.dart';
import 'package:angkor_burger_app/helpers/user_avatar.dart';
import 'package:angkor_burger_app/models/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  late String _selectedGender;
  late String _dateOfBirth;
  late String _selectedAvatarEmoji;
  String? _selectedImagePath;
  Uint8List? _selectedImageBytes;
  bool _isUploadingImage = false;

  final List<String> _avatarEmojiPresets = [
    '👑',
    '🍔',
    '🦁',
    '🍟',
    '🍕',
    '🧑‍🍳',
    '😎',
    '🚀',
    '⭐',
    '🥤',
    '🥑',
    '🐱',
  ];

  @override
  void initState() {
    super.initState();
    final profile = UserProfileManager.currentProfile;
    _nameController = TextEditingController(text: profile.name);
    _phoneController = TextEditingController(text: profile.phone);
    _emailController = TextEditingController(text: profile.email);
    _addressController = TextEditingController(text: profile.address);
    _selectedGender = profile.gender;
    _dateOfBirth = profile.dateOfBirth;
    _selectedAvatarEmoji = profile.avatarEmoji;
    _selectedImagePath = profile.profileImagePath;
    _selectedImageBytes = profile.profileImageBytes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final Uint8List imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImagePath = pickedFile.path;
          _selectedImageBytes = imageBytes;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.white,
              behavior: SnackBarBehavior.floating,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                    color: AppColors.brandLightRed, width: 1.5),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              content: const Row(
                children: [
                  Icon(Icons.photo_library,
                      color: AppColors.brandRed, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Profile photo selected!',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _showPhotoOptionsBottomSheet() {
    final bool hasPhoto =
        _selectedImagePath != null || _selectedImageBytes != null;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Profile Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 14),

            // 1. Camera Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.brandLightRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt,
                    color: AppColors.brandRed, size: 20),
              ),
              title: const Text(
                'Take Photo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text(
                'Capture photo with device camera',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),

            // 2. Gallery Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.brandLightRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library,
                    color: AppColors.brandRed, size: 20),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text(
                'Select photo from device album',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),

            // 3. Remove Photo Option
            if (hasPhoto)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                ),
                title: const Text(
                  'Remove Current Photo',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red),
                ),
                subtitle: const Text(
                  'Use emoji avatar instead',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  setState(() {
                    _selectedImagePath = null;
                    _selectedImageBytes = null;
                  });
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    DateTime initialDate = DateTime(2004, 5, 15);
    try {
      final parts = _dateOfBirth.split('-');
      if (parts.length == 3) {
        initialDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandRed,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateOfBirth =
            "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final bool isImageCleared =
        _selectedImagePath == null && _selectedImageBytes == null;

    UserProfileManager.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      gender: _selectedGender,
      dateOfBirth: _dateOfBirth,
      avatarEmoji: _selectedAvatarEmoji,
      profileImagePath: _selectedImagePath,
      profileImageBytes: _selectedImageBytes,
      clearProfileImage: isImageCleared,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.brandLightRed, width: 1.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.brandLightRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.brandRed, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Profile information updated successfully!',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Current temporary profile preview
    final previewProfile = UserProfileModel(
      name: _nameController.text.isNotEmpty ? _nameController.text : 'User',
      phone: _phoneController.text,
      email: _emailController.text,
      address: _addressController.text,
      gender: _selectedGender,
      dateOfBirth: _dateOfBirth,
      avatarEmoji: _selectedAvatarEmoji,
      profileImagePath: _selectedImagePath,
      profileImageBytes: _selectedImageBytes,
    );

    return Scaffold(
      backgroundColor: AppColors.brandColor,
      body: Column(
        children: [
          // Custom Angkor Burger App Bar
          AngkorAppBar(
            title: 'EDIT PROFILE',
            showBackButton: true,
            showFavorite: false,
          ),

          // Form Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. AVATAR UPLOAD & EMOJI PICKER CARD
                    _buildAvatarPickerCard(previewProfile),
                    const SizedBox(height: 20),

                    // 2. PERSONAL INFORMATION CONTAINER
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.person_outline,
                                  color: AppColors.brandRed, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, thickness: 0.8),

                          // Full Name Field
                          _buildInputField(
                            label: 'Full Name',
                            controller: _nameController,
                            icon: Icons.badge_outlined,
                            hint: 'Enter your full name',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Phone Number Field
                          _buildInputField(
                            label: 'Phone Number',
                            controller: _phoneController,
                            icon: Icons.phone_outlined,
                            hint: '+855 12 345 678',
                            keyboardType: TextInputType.phone,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          _buildInputField(
                            label: 'Email Address',
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            hint: 'user@example.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Gender Selection
                          const Text(
                            'Gender',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: ['Male', 'Female', 'Other'].map((gender) {
                              final isSelected = _selectedGender == gender;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: ChoiceChip(
                                  label: Text(gender),
                                  selected: isSelected,
                                  selectedColor: AppColors.brandRed,
                                  backgroundColor: Colors.grey.shade100,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppColors.brandRed
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedGender = gender;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Date of Birth Field
                          const Text(
                            'Date of Birth',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _selectDateOfBirth,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.cake_outlined,
                                      color: AppColors.brandRed, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    _dateOfBirth,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.calendar_month,
                                      size: 18, color: Colors.grey.shade600),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. DELIVERY ADDRESS CONTAINER
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  color: AppColors.brandRed, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Default Delivery Address',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, thickness: 0.8),
                          _buildInputField(
                            label: 'Street Address & City',
                            controller: _addressController,
                            icon: Icons.home_outlined,
                            hint: 'Street, Building, Phnom Penh',
                            maxLines: 2,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your delivery address';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 4. SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 20),
                        label: const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPickerCard(UserProfileModel previewProfile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                UserAvatar(
                  profile: previewProfile,
                  radius: 46,
                  showEditBadge: true,
                  borderWidth: 3,
                  onEditTap: _showPhotoOptionsBottomSheet,
                ),
                if (_isUploadingImage)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.brandRed),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Upload / Change Photo Action Buttons
          Builder(
            builder: (context) {
              final bool hasPhoto =
                  _selectedImagePath != null || _selectedImageBytes != null;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showPhotoOptionsBottomSheet,
                    icon: const Icon(Icons.add_a_photo_outlined,
                        size: 16, color: Colors.white),
                    label: Text(
                      hasPhoto ? 'Change Photo' : 'Upload Photo',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandRed,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  if (hasPhoto) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedImagePath = null;
                          _selectedImageBytes = null;
                        });
                      },
                      icon: const Icon(Icons.close, size: 14, color: Colors.red),
                      label: const Text(
                        'Remove',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Preset Avatars Selection
          const Text(
            'Or Select Avatar Character',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _avatarEmojiPresets.map((emoji) {
                final isSelected = _selectedAvatarEmoji == emoji &&
                    _selectedImagePath == null &&
                    _selectedImageBytes == null;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatarEmoji = emoji;
                      _selectedImagePath = null;
                      _selectedImageBytes = null;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.brandLightRed
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brandRed
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.brandRed, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.brandRed, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
