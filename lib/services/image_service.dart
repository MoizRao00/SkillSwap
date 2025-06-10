
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery or camera
  Future<File?> pickImage(bool fromCamera) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      print('❌ Error picking image: $e');
      return null;
    }
  }

  // Upload image to Firebase Storage
  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      // Create storage reference
      final ref = _storage.ref().child('profile_pictures/$userId.jpg');

      // Upload file
      await ref.putFile(imageFile);

      // Get download URL
      final url = await ref.getDownloadURL();
      print('✅ Image uploaded successfully: $url');
      return url;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }
}