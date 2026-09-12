import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'backup_service.dart';
import '../../features/notes/data/datasources/note_local_data_source.dart';
import '../../features/notes/data/datasources/folder_local_data_source.dart';

/// Hesaba bağlı bulut yedekleme.
///
/// Yerel [BackupService] tarafından üretilen .zip yedeğini, oturum açan
/// kullanıcının UID'si altında Firebase Storage'a yükler / oradan indirir.
/// Böylece kullanıcı başka bir cihazda aynı hesapla giriş yaptığında
/// notları geri yüklenebilir.
class CloudBackupService {
  CloudBackupService({required this.backupService});

  final BackupService backupService;

  /// Bu cihazdaki yerel veri kaynaklarına bağlı bir [CloudBackupService]
  /// oluşturur. Giriş/kayıt ve hesap sayfalarından ortak kullanılır.
  static Future<CloudBackupService> forCurrentDevice() async {
    final dbHelper = DatabaseHelper.instance;
    final noteDataSource = NoteLocalDataSource(dbHelper);
    final folderDataSource = FolderLocalDataSource(dbHelper);
    final prefs = await SharedPreferences.getInstance();

    return CloudBackupService(
      backupService: BackupService(
        noteDataSource: noteDataSource,
        folderDataSource: folderDataSource,
        prefs: prefs,
      ),
    );
  }

  FirebaseStorage get _storage => FirebaseStorage.instance;

  String _pathForUser(String uid) => 'backups/$uid/backup.zip';

  /// Mevcut kullanıcı için buluta yedek olup olmadığını kontrol eder.
  Future<bool> hasCloudBackup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      await _storage.ref(_pathForUser(user.uid)).getMetadata();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return false;
      rethrow;
    }
  }

  /// Yerel verilerden yedek oluşturup oturum açan kullanıcının bulut
  /// alanına yükler.
  Future<void> uploadBackup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Yedek yüklemek için önce oturum açmalısınız.');
    }
    final filePath = await backupService.createBackup();
    final file = File(filePath);
    await _storage.ref(_pathForUser(user.uid)).putFile(file);
  }

  /// Buluttaki yedeği indirip yerel veriyle değiştirir (geri yükler).
  Future<RestoreResult> downloadAndRestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Geri yüklemek için önce oturum açmalısınız.');
    }
    final tempDir = Directory.systemTemp;
    final localFile = File(
      '${tempDir.path}/cloud_backup_${user.uid}.zip',
    );
    await _storage.ref(_pathForUser(user.uid)).writeToFile(localFile);
    return backupService.restoreBackup(localFile.path);
  }

  /// Bu hesaba ait bulut yedeğini kalıcı olarak siler. Yerel verilere
  /// dokunmaz, sadece bulutta saklanan kopyayı kaldırır.
  Future<void> deleteBackup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Yedeği silmek için önce oturum açmalısınız.');
    }
    try {
      await _storage.ref(_pathForUser(user.uid)).delete();
    } on FirebaseException catch (e) {
      // Zaten yoksa hata sayılmaz.
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
