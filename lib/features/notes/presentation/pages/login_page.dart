import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/cloud_backup_service.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/folders_bloc.dart';

/// Oturum açma / hesap oluşturma sayfası.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        await AuthService.instance.register(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await AuthService.instance.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        await _restoreCloudBackupIfAny();
      }
      if (mounted) {
        // Girişten sonra, hesaba bağlı verileri geri yükleyecek olan
        // AccountPage'e dönülür (Navigator.pop ile geri dönülür, orada
        // authStateChanges dinlendiği için otomatik geri yükleme tetiklenir).
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = AuthService.messageForError(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Bu hesaba ait buluttaki yedek varsa indirip yerel veriyle değiştirir
  /// ve ekrandaki not/klasör listelerini tazeler.
  Future<void> _restoreCloudBackupIfAny() async {
    try {
      final cloudBackup = await CloudBackupService.forCurrentDevice();
      if (!await cloudBackup.hasCloudBackup()) return;

      final result = await cloudBackup.downloadAndRestore();
      if (result.success && mounted) {
        context.read<NotesBloc>().add(const LoadNotes());
        context.read<FoldersBloc>().add(const LoadFolders());
      }
    } catch (_) {
      // Otomatik geri yükleme başarısız olursa sessizce geç; kullanıcı
      // hesap sayfasından elle "Buluttan Geri Yükle" ile tekrar deneyebilir.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().isDark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegisterMode ? 'Hesap Oluştur' : 'Oturum Aç'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(
                CupertinoIcons.person_crop_circle_fill,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _isRegisterMode
                    ? 'Notlarını buluta yedeklemek için bir hesap oluştur.'
                    : 'Notlarını yedeklemek ve başka bir cihazda geri getirmek için oturum aç.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(CupertinoIcons.mail),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'E-posta adresini girin';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Geçerli bir e-posta adresi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: const Icon(CupertinoIcons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash,
                    ),
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifreni girin';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalı';
                  }
                  return null;
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isRegisterMode ? 'Hesap Oluştur' : 'Oturum Aç'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() {
                        _isRegisterMode = !_isRegisterMode;
                        _errorMessage = null;
                      }),
                child: Text(
                  _isRegisterMode
                      ? 'Zaten hesabın var mı? Oturum aç'
                      : 'Hesabın yok mu? Hesap oluştur',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
