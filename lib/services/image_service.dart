import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

/// 画像管理サービスクラス
class ImageService {
  static final ImageService _instance = ImageService._internal();
  final ImagePicker _picker = ImagePicker();
  
  factory ImageService() {
    return _instance;
  }
  
  ImageService._internal();
  
  /// カメラから画像を取得
  Future<String?> takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (photo != null) {
        return await _saveImage(photo);
      }
      return null;
    } catch (e) {
      debugPrint('カメラからの画像取得エラー: $e');
      return null;
    }
  }
  
  /// ギャラリーから画像を選択
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        return await _saveImage(image);
      }
      return null;
    } catch (e) {
      debugPrint('ギャラリーからの画像取得エラー: $e');
      return null;
    }
  }
  
  /// 画像を保存し、パスを返す
  Future<String> _saveImage(XFile image) async {
    if (kIsWeb) {
      // Web環境では画像データをBase64エンコードして保存
      final bytes = await image.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      return base64Image;
    } else {
      // ネイティブ環境では画像をローカルに保存
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
      final savedImage = File('${appDir.path}/$fileName');
      
      if (Platform.isIOS || Platform.isAndroid) {
        await savedImage.writeAsBytes(await image.readAsBytes());
        return savedImage.path;
      } else {
        // デスクトップ環境
        await savedImage.writeAsBytes(await image.readAsBytes());
        return savedImage.path;
      }
    }
  }
  
  /// 画像のプレビューウィジェット用のデータを取得
  Future<dynamic> getImageData(String? imagePath) async {
    if (imagePath == null) return null;
    
    if (kIsWeb) {
      // Web環境ではBase64エンコードされた画像データを直接返す
      if (imagePath.startsWith('data:image')) {
        return imagePath;
      }
      return null;
    } else {
      // ネイティブ環境ではファイルパスを返す
      final file = File(imagePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    }
  }
}
