import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  final String cloudName = "dtfh1xowr";
  final String uploadPreset = "unsigned_preset";

  /// 🔹 Pick image -> crop -> compress -> return final File
  Future<File?> pickAndCropImage({bool fromCamera = false}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1080, // Limit width (e.g., to Full HD width)
      maxHeight: 1920, // Limit height (e.g., to Full HD height) - adjust as needed
      imageQuality: 70, // Also apply initial quality reduction here
    );

    if (picked == null) return null;

    final originalFile = File(picked.path);

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: originalFile.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );

    if (croppedFile == null) return null;

    return File(croppedFile.path); // Return the cropped file directly
  }

  /// 🔹 Upload to Cloudinary
  Future<String?> uploadProfilePicture(String uid, File imageFile) async {
    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final res = await http.Response.fromStream(response);
        final data = jsonDecode(res.body);
        return data['secure_url'];
      } else {
        print("❌ Cloudinary upload failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error uploading to Cloudinary: $e");
      return null;
    }
  }
}

Future<File?> compressImage(File file) async {
  // Correct usage: call it directly after importing
  final dir = await getTemporaryDirectory();
  final targetPath = '${dir.path}/temp_compressed.jpg';

  final result = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    targetPath,
    quality: 70,
    minHeight: 800,
    minWidth: 800,
  );

  if (result == null) return null;

  return File(result.path);
}