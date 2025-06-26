// lib/screens/profile/edit_profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
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
  // In _EditProfileScreenState

  Future<void> _updateCurrentUserLocation(BuildContext context) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid; // Get current user's UID directly

    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true); // Indicate loading

    // 1. Check if location services are enabled on the device
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable them.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    // 2. Request location permissions from the user
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied. Cannot set location without permission.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied. Please enable from app settings.'),
            duration: Duration(seconds: 8),
          ),
        );
      }
      setState(() => _isLoading = false);
      // Optionally, you might want to open app settings: Geolocator.openAppSettings();
      return;
    }

    // 3. Get the current position
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fetching your location...')),
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      GeoPoint userGeoPoint = GeoPoint(position.latitude, position.longitude);
      String? fetchedLocationName; // To store the human-readable name

      // 4. Perform Reverse Geocoding
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          // You can customize the format of the location name here
          // Example: "City, State, Country" or "Locality, Country"
          fetchedLocationName = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? place.country ?? 'Unknown Location';
          if (place.country != null && fetchedLocationName != null && !fetchedLocationName.contains(place.country!)) {
            fetchedLocationName += ', ${place.country}';
          }
        }
      } catch (e) {
        print('Error during reverse geocoding: $e');
        fetchedLocationName = 'Unknown Location'; // Fallback if geocoding fails
      }

      // 5. Update the user profile in Firestore
      // Use _fs.updateUser to save both GeoPoint and locationName
      // Note: _fs.updateUser needs to accept a Map<String, dynamic>
      bool success = await _fs.updateUser(
        currentUserId,
        {
          'location': userGeoPoint,
          'locationName': fetchedLocationName, // Saving the human-readable name
          // The 'geohash' field will be automatically calculated and saved by FirestoreService
          // because we updated the updateUser method to handle this. (Assuming it does)
        },
      );

      if (success) {
        // CRITICAL: Update the local _currentUser object in the state
        // and update the _locationController for display
        setState(() {
          _currentUser = _currentUser?.copyWith(
            location: userGeoPoint,
            locationName: fetchedLocationName,
          );
          _locationController.text = fetchedLocationName ?? 'Location not set';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location updated successfully!')),
          );
        }
        print('Location saved to Firestore: Lat ${userGeoPoint.latitude}, Lng ${userGeoPoint.longitude}, Name: $fetchedLocationName');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save location to Firestore.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching or saving location: $e')),
        );
      }
      print('Error in _updateCurrentUserLocation: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfilePicture(bool fromCamera) async {
    try {
      setState(() => _isLoading = true);

      // --- PERMISSION HANDLING START ---
      PermissionStatus status;
      if (fromCamera) {
        // For camera, request camera permission
        status = await Permission.camera.request();
      } else {
        // For gallery, request photo/storage permissions
        // On Android 13 (API 33) and above, use Permission.photos
        // On Android 12 (API 32) and below, use Permission.storage
        if (Theme.of(context).platform == TargetPlatform.android && (await getAndroidSdkVersion()) >= 33) {
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }
      }

      if (status.isGranted) {
        // Permissions granted, proceed with image picking
        final pickedImage = await _imageService.pickAndCropImage(fromCamera: fromCamera);
        if (pickedImage == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image selection cancelled or failed.')),
            );
          }
          return;
        }

        final imageUrl = await _imageService.uploadProfilePicture(_currentUser!.uid, pickedImage);

        if (imageUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image upload failed')),
            );
          }
          return;
        }

        final updatedUser = _currentUser!.copyWith(
          profileImageUrl: imageUrl,
          lastActive: DateTime.now(),
          skillsToTeach: _currentSkillsToTeach,
          skillsToLearn: _currentSkillsToLearn,
        );

        // Assuming _fs is your Firestore service or similar
        // await _fs.saveUser(updatedUser);

        setState(() {
          _currentUser = updatedUser;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!')),
          );
        }
      } else if (status.isDenied) {
        // User denied permission
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permission denied to access ${fromCamera ? 'camera' : 'gallery'}.')),
          );
        }
        return; // Stop execution if permission is denied
      } else if (status.isPermanentlyDenied) {
        // User permanently denied, guide them to app settings
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permission permanently denied. Please enable from app settings.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  openAppSettings(); // Opens app settings for the user
                },
              ),
            ),
          );
        }
        return; // Stop execution if permission is permanently denied
      }
      // --- PERMISSION HANDLING END ---

    } catch (e) {
      print('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<int> getAndroidSdkVersion() async {

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
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


          _locationController.text = userData.locationName ?? '';

          _phoneController.text = userData.phoneNumber ?? '';
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
        // The _currentUser object in state already has the updated location and locationName
        // from _updateCurrentUserLocation. So copyWith will use those values.
        final updatedUser = _currentUser!.copyWith(
          name: _nameController.text.trim(),
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
          // location and locationName are already updated in _currentUser state,
          // so copyWith will implicitly carry them over unless overridden.
          // Explicitly keeping them for clarity, but not strictly needed if not changing
          location: _currentUser!.location,
          locationName: _currentUser!.locationName,

          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          skillsToTeach: _currentSkillsToTeach,
          skillsToLearn: _currentSkillsToLearn,
          lastActive: DateTime.now(),
          isAvailable: _currentUser!.isAvailable,
        );

        // Your FirestoreService.saveUser method needs to accept a UserModel and save its .toMap()
        await _fs.saveUser(updatedUser);

        setState(() {
          _currentUser = updatedUser; // Update local state after successful save
        });

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[ ElevatedButton(
                  onPressed: () {
                    _updateCurrentUserLocation(context);
                  },
                  child: const Text('Set Current Location'),
                ),
                  const SizedBox(width: 10,),
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
                  ),]
              ),
              const SizedBox(height: 15),
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
            backgroundImage: _currentUser?.profileImageUrl != null
                ? NetworkImage(_currentUser!.profileImageUrl!)
                : null,
            child: _currentUser?.profileImageUrl == null
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