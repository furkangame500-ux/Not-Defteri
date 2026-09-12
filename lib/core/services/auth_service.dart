import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// E-posta/şifre ile oturum açma servisi.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Firebase yapılandırma dosyaları (google-services.json /
  /// GoogleService-Info.plist) henüz eklenmediyse Firebase.apps boş olur.
  /// Bu durumda FirebaseAuth.instance'a dokunmak çöker; bunun yerine
  /// oturum kapalıymış gibi davranırız.
  bool get isConfigured => Firebase.apps.isNotEmpty;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Oturum durumu değişikliklerini dinlemek için (giriş/çıkış).
  Stream<User?> get authStateChanges {
    if (!isConfigured) return Stream<User?>.value(null);
    return _auth.authStateChanges();
  }

  User? get currentUser => isConfigured ? _auth.currentUser : null;

  bool get isSignedIn => currentUser != null;

  /// Var olan bir hesapla giriş yapar.
  Future<User?> signIn({required String email, required String password}) async {
    _ensureConfigured();
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  /// Yeni bir hesap oluşturur.
  Future<User?> register({
    required String email,
    required String password,
  }) async {
    _ensureConfigured();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  Future<void> signOut() => _auth.signOut();

  /// Hesabı Firebase Authentication'dan kalıcı olarak siler.
  ///
  /// Firebase, güvenlik gereği son girişin "yakın zamanda" yapılmış
  /// olmasını ister; aksi halde 'requires-recent-login' hatası fırlatır.
  /// Bu durumda çağıran taraf kullanıcıyı tekrar oturum açmaya
  /// yönlendirmelidir.
  Future<void> deleteAccount() async {
    _ensureConfigured();
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Silinecek bir hesap bulunamadı.');
    }
    await user.delete();
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw StateError(
        'Firebase henüz yapılandırılmadı. google-services.json / '
        'GoogleService-Info.plist dosyalarının eklendiğinden emin olun.',
      );
    }
  }

  /// FirebaseAuthException kodlarını kullanıcıya gösterilecek Türkçe
  /// mesajlara çevirir.
  static String messageForError(Object error) {
    if (error is StateError) {
      return error.message;
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Geçersiz e-posta adresi.';
        case 'user-disabled':
          return 'Bu hesap devre dışı bırakılmış.';
        case 'user-not-found':
          return 'Bu e-posta ile kayıtlı bir hesap bulunamadı.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-posta veya şifre hatalı.';
        case 'email-already-in-use':
          return 'Bu e-posta adresi zaten kullanımda.';
        case 'weak-password':
          return 'Şifre çok zayıf. En az 6 karakter kullanın.';
        case 'requires-recent-login':
          return 'Bu işlem için güvenlik amacıyla yakın zamanda tekrar oturum açmanız gerekiyor. Lütfen çıkış yapıp tekrar giriş yapın ve tekrar deneyin.';
        case 'network-request-failed':
          return 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.';
        default:
          return 'Bir hata oluştu: ${error.message ?? error.code}';
      }
    }
    return 'Beklenmeyen bir hata oluştu: $error';
  }
}
