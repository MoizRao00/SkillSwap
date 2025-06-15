// lib/screens/profile/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/usermodel.dart';
import '../../services/image_service.dart';
import '../skills/skill_management_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _fs = FirestoreService();
  final ImageService _imageService = ImageService();
  bool _isLoading = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  UserModel? _currentUser;

  // NEW: State variables to hold the current skills being edited
  List<String> _currentSkillsToTeach = [];
  List<String> _currentSkillsToLearn = [];


  @override
  void initState() {
    super.initState();
    _loadCurrentUser(); // This will populate _currentUser and the controllers
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _updateProfilePicture(true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _updateProfilePicture(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfilePicture(bool fromCamera) async {
    try {
      print('Attempting to pick image...');
      final image = await _imageService.pickImage(fromCamera);

      if (image == null) {
        print('Image picking cancelled or failed (image is null).');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image selection cancelled or failed.')),
          );
        }
        return; // Exit if no image was picked
      }
      print('Image picked successfully: ${image.path}'); // Confirm image path

      setState(() => _isLoading = true); // Start loading indicator

      print('Attempting to upload image...');
      // Ensure _currentUser is not null before accessing its uid
      if (_currentUser?.uid == null) {
        print('Error: current user UID is null. Cannot upload.');
        throw Exception("User not logged in or UID not available for upload.");
      }
      final imageUrl = await _imageService.uploadProfilePicture(
        _currentUser!.uid,
        image,
      );

      if (imageUrl == null) {
        print('Image upload returned null URL.'); // Confirm if URL is null
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to get image download URL.')),
          );
        }
        return; // Exit if upload failed to get URL
      }
      print('Image URL obtained: $imageUrl'); // Confirm URL obtained

      // Update user model with new image URL
      // Make sure to pass existing values for skills as they are not being edited here
      final updatedUser = _currentUser!.copyWith(
        profilePicUrl: imageUrl,
        lastActive: DateTime.now(),
        // IMPORTANT: Ensure skills are also passed to copyWith
        skillsToTeach: _currentSkillsToTeach, // Pass the current state of skills
        skillsToLearn: _currentSkillsToLearn, // Pass the current state of skills
      );

      print('Attempting to save user data to Firestore...');
      await _fs.saveUser(updatedUser); // This saveUser will now trigger an update
      print('User data saved to Firestore.'); // Confirm Firestore update

      setState(() {
        _currentUser = updatedUser; // Update the local state
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      print('Final catch block error: $e'); // Catch any error that bubbles up
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        print('Loading finished.'); // Indicate end of loading state
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await _fs.getUser(user.uid);
      if (userData != null) {
        setState(() {
          _currentUser = userData;
          _nameController.text = userData.name;
          _bioController.text = userData.bio ?? '';
          _locationController.text = userData.location ?? '';
          _phoneController.text = userData.phone ?? '';
          // NEW: Initialize local skill lists from loaded user data
          _currentSkillsToTeach = List.from(userData.skillsToTeach);
          _currentSkillsToLearn = List.from(userData.skillsToLearn);
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _currentUser != null) {
        // Create updated user model from current UI state
        // NEW: Include the skills from the local state (_currentSkillsToTeach, _currentSkillsToLearn)
        final updatedUser = _currentUser!.copyWith(
          name: _nameController.text.trim(),
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(), // Handle empty string to null
          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(), // Handle empty string to null
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(), // Handle empty string to null
          skillsToTeach: _currentSkillsToTeach, // THIS IS THE KEY CHANGE!
          skillsToLearn: _currentSkillsToLearn, // THIS IS THE KEY CHANGE!
          lastActive: DateTime.now(),
          isAvailable: _currentUser!.isAvailable, // Ensure availability is preserved
        );

        // Save to Firestore. Assuming _fs.saveUser handles both create and update
        // and correctly converts UserModel to a Map for Firestore.
        await _fs.saveUser(updatedUser);

        // Update the local _currentUser state to reflect the saved changes
        setState(() {
          _currentUser = updatedUser;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.pop(context); // Pop back to the previous screen
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              _buildProfilePicture(),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  icon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bio Field
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  icon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Location Field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  icon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  icon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Availability Toggle
              SwitchListTile(
                title: const Text('Available for Skill Exchange'),
                value: _currentUser?.isAvailable ?? true,
                onChanged: (bool value) {
                  setState(() {
                    _currentUser = _currentUser?.copyWith(isAvailable: value);
                  });
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.psychology),
                label: const Text('Manage Skills'),
                onPressed: () async { // Make onPressed async to await result
                  if (_currentUser != null) {
                    // NEW: Pass current skills to SkillManagementScreen and await for updated ones
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SkillManagementScreen(
                          initialSkillsToTeach: _currentSkillsToTeach,
                          initialSkillsToLearn: _currentSkillsToLearn,
                        ),
                      ),
                    );

                    // NEW: If SkillManagementScreen returns updated lists
                    if (result != null && result is Map<String, List<String>>) {
                      setState(() {
                        _currentSkillsToTeach = result['skillsToTeach'] ?? [];
                        _currentSkillsToLearn = result['skillsToLearn'] ?? [];
                        // NEW: IMPORTANT: Update _currentUser directly so it's consistent for saving
                        // This assumes UserModel has copyWith for these lists
                        _currentUser = _currentUser!.copyWith(
                          skillsToTeach: _currentSkillsToTeach,
                          skillsToLearn: _currentSkillsToLearn,
                        );
                      });
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User data not loaded yet.')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildProfilePicture() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: _currentUser?.profilePicUrl != null
                ? NetworkImage(_currentUser!.profilePicUrl!)
                : null,
            child: _currentUser?.profilePicUrl == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 18,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, size: 18),
                color: Colors.white,
                onPressed: _showImageSourceDialog,
              ),
            ),
          ),
        ],
      ),
    );
  }
}