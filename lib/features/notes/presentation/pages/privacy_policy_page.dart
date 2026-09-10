import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';

/// Gizlilik Sözleşmesi (NDA) sayfası.
///
/// Metin, dış bir bağlantıya yönlendirmek yerine uygulama içinde
/// assets/legal/gizlilik_sozlesmesi.txt dosyasından okunup gösterilir.
class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String? _content;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final text = await rootBundle.loadString(
      'assets/legal/gizlilik_sozlesmesi.txt',
    );
    if (mounted) {
      setState(() => _content = text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().isDark;
    final textColor = isDark
        ? AppColors.darkText
        : AppColors.lightText;
    final secondaryColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik Sözleşmesi'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _content == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildBlocks(_content!, textColor, secondaryColor),
              ),
            ),
    );
  }

  List<Widget> _buildBlocks(String raw, Color textColor, Color secondaryColor) {
    final blocks = raw.split('\n\n');
    final widgets = <Widget>[];

    for (final block in blocks) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Text(
              trimmed.substring(2),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: TextStyle(color: secondaryColor)),
                Expanded(
                  child: Text(
                    trimmed.substring(2),
                    style: TextStyle(fontSize: 14, color: secondaryColor, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              trimmed,
              style: TextStyle(fontSize: 14, color: secondaryColor, height: 1.4),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}
