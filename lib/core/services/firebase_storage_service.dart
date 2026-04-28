import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

/// Service để upload ảnh lên Firebase Storage và lấy download URL
///
/// LƯU Ý về Authentication:
/// - Firebase Storage có thể hoạt động KHÔNG CẦN đăng nhập nếu Security Rules cho phép
/// - Nếu Security Rules yêu cầu authentication, bạn cần đăng nhập trước
///
/// Để cho phép upload không cần đăng nhập, cấu hình Security Rules trong Firebase Console:
/// rules_version = '2';
/// service firebase.storage {
///   match /b/{bucket}/o {
///     match /{allPaths=**} {
///       allow read, write: if true; // Cho phép tất cả (chỉ dùng cho dev/test)
///     }
///   }
/// }
///
/// Hoặc để bảo mật hơn, yêu cầu authentication:
/// allow write: if request.auth != null;
class FirebaseStorageService extends GetxService {
  FirebaseStorageService._internal();
  static final FirebaseStorageService shared =
      FirebaseStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload ảnh từ file path và lấy download URL
  ///
  /// [filePath] - Đường dẫn file ảnh cần upload
  /// [folder] - Thư mục trong Storage (mặc định: 'images')
  /// [fileName] - Tên file (nếu null sẽ tự động generate)
  ///
  /// Returns: Download URL của ảnh đã upload
  Future<String?> uploadImageAndGetUrl({
    required String filePath,
    String folder = 'images',
    String? fileName,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File không tồn tại: $filePath');
      }

      // Tạo tên file nếu chưa có
      final finalFileName = fileName ??
          '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';

      // Tạo reference trong Storage
      final ref = _storage.ref().child('$folder/$finalFileName');

      // Upload file
      final uploadTask = ref.putFile(file);

      // Chờ upload hoàn thành
      final snapshot = await uploadTask;

      // Lấy download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Lỗi khi upload ảnh lên Firebase Storage: $e');
      rethrow;
    }
  }

  /// Upload ảnh từ bytes và lấy download URL
  ///
  /// [bytes] - Dữ liệu ảnh dạng Uint8List
  /// [folder] - Thư mục trong Storage (mặc định: 'images')
  /// [fileName] - Tên file (nếu null sẽ tự động generate)
  ///
  /// Returns: Download URL của ảnh đã upload
  Future<String?> uploadImageBytesAndGetUrl({
    required List<int> bytes,
    String folder = 'images',
    String? fileName,
  }) async {
    try {
      // Tạo tên file nếu chưa có
      final finalFileName =
          fileName ?? '${DateTime.now().millisecondsSinceEpoch}.png';

      // Tạo reference trong Storage
      final ref = _storage.ref().child('$folder/$finalFileName');

      // Upload bytes
      final uploadTask = ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: 'image/png'),
      );

      // Chờ upload hoàn thành
      final snapshot = await uploadTask;

      // Lấy download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Lỗi khi upload ảnh lên Firebase Storage: $e');
      rethrow;
    }
  }

  /// Xóa ảnh từ Storage
  ///
  /// [url] - Download URL của ảnh cần xóa
  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Lỗi khi xóa ảnh từ Firebase Storage: $e');
      rethrow;
    }
  }

  /// Xóa ảnh từ path trong Storage
  ///
  /// [path] - Đường dẫn trong Storage (ví dụ: 'images/photo123.png')
  Future<void> deleteImageByPath(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      print('Lỗi khi xóa ảnh từ Firebase Storage: $e');
      rethrow;
    }
  }
}
