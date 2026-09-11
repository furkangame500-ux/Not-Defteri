import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/cloud_backup_service.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/folders_bloc.dart';
import 'login_page.dart';

/// Hesap sayfası.
///
/// Oturum açılmamışsa giriş daveti, açılmışsa hesap bilgisi ve bulut
/// yedekleme/geri yükleme kontrollerini gösterir.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesabım'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<User?>(
        stream: AuthService.instance.authStateChanges,
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) {
            return _SignedOutView(
              onSignInTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
            );
          }
          return _SignedInView(user: user);
        },
      ),
    );
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView({required this.onSignInTap});

  final VoidCallback onSignInTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().isDark;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.person_crop_circle_badge_plus,
            size: 72,
            color: AppColors.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Henüz oturum açmadın',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Oturum açtığında notların bulutta yedeklenir; başka bir cihazda aynı hesapla giriş yaptığında geri gelir.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: onSignInTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
            ),
            child: const Text('Oturum Aç'),
          ),
        ],
      ),
    );
  }
}

class _SignedInView extends StatefulWidget {
  const _SignedInView({required this.user});

  final User user;

  @override
  State<_SignedInView> createState() => _SignedInViewState();
}

class _SignedInViewState extends State<_SignedInView> {
  bool _isBusy = false;
  String? _statusMessage;
  bool? _isSuccess;

  Future<void> _uploadBackup() async {
    setState(() {
      _isBusy = true;
      _statusMessage = null;
    });
    try {
      final cloud = await CloudBackupService.forCurrentDevice();
      await cloud.uploadBackup();
      setState(() {
        _statusMessage = 'Yedek buluta yüklendi.';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Yedekleme başarısız oldu: $e';
        _isSuccess = false;
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _restoreBackup() async {
    setState(() {
      _isBusy = true;
      _statusMessage = null;
    });
    try {
      final cloud = await CloudBackupService.forCurrentDevice();
      if (!await cloud.hasCloudBackup()) {
        setState(() {
          _statusMessage = 'Bu hesap için bulutta kayıtlı bir yedek yok.';
          _isSuccess = false;
        });
        return;
      }
      final result = await cloud.downloadAndRestore();
      if (result.success && mounted) {
        context.read<NotesBloc>().add(const LoadNotes());
        context.read<FoldersBloc>().add(const LoadFolders());
      }
      setState(() {
        _statusMessage = result.message;
        _isSuccess = result.success;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Geri yükleme başarısız oldu: $e';
        _isSuccess = false;
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().isDark;
    final secondaryColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withAlpha(30),
            child: Icon(
              CupertinoIcons.person_fill,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.user.email ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 32),

          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      CupertinoIcons.cloud_upload_fill,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text('Yedeği Buluta Yükle'),
                  subtitle: const Text('Notlarını bu hesaba kaydet'),
                  onTap: _isBusy ? null : _uploadBackup,
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      CupertinoIcons.cloud_download_fill,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  title: const Text('Buluttan Geri Yükle'),
                  subtitle: const Text('Bu hesaptaki en son yedeği getir'),
                  onTap: _isBusy ? null : _restoreBackup,
                ),
              ],
            ),
          ),

          if (_isBusy) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],

          if (_statusMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _statusMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isSuccess == false ? AppColors.error : secondaryColor,
              ),
            ),
          ],

          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: _isBusy ? null : _signOut,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}
