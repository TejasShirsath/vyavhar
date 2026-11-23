import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/utils/id_generator.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  /// Captures a photo using the device camera and stores it in app documents
  Future<String?> captureFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (file == null) return null;
      return await _persistImageFile(file);
    } catch (e) {
      // In case camera is unavailable (e.g. desktop/emulator test), fallback or rethrow
      return null;
    }
  }

  /// Picks an image from device gallery and stores it in app documents
  Future<String?> pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (file == null) return null;
      return await _persistImageFile(file);
    } catch (e) {
      return null;
    }
  }

  /// Copies the picked temporary image into the permanent app documents directory
  Future<String> _persistImageFile(XFile file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(appDir.path, 'vyavhar_delivery_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final ext = p.extension(file.path).isNotEmpty ? p.extension(file.path) : '.jpg';
    final fileName = 'delivery_${DateTime.now().millisecondsSinceEpoch}_${IdGenerator.uuid().substring(0, 8)}$ext';
    final targetPath = p.join(photosDir.path, fileName);

    final savedFile = await File(file.path).copy(targetPath);
    return savedFile.path;
  }

  /// Delete photo from storage if needed
  Future<void> deletePhoto(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
