
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

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }
  // Update the camera icon button to show options

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

  // Add this method to handle image selection

  // In _EditProfileScreenState class
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
      final updatedUser = _currentUser!.copyWith(
        profilePicUrl: imageUrl,
        lastActive: DateTime.now(),
      );

      print('Attempting to save user data to Firestore...');
      await _fs.saveUser(updatedUser);
      print('User data saved to Firestore.'); // Confirm Firestore update

      setState(() {
        _currentUser = updatedUser;
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
        // Create updated user model
        final updatedUser = _currentUser!.copyWith(
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          location: _locationController.text.trim(),
          phone: _phoneController.text.trim(),
          lastActive: DateTime.now(),
        );

        // Save to Firestore
        await _fs.saveUser(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.pop(context);
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SkillManagementScreen(),
                    ),
                  );
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


