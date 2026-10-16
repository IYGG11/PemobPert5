import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tombol reusable yang membuka [url] di aplikasi eksternal (browser / app GitHub).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.icon,
    required this.url,
    required this.height,
    required this.borderRadius,
  });

  final String label;
  final IconData icon;
  final String url;
  final double height;
  final double borderRadius;

  Future<void> _bukaUrl(BuildContext context) async {
    final Uri uri = Uri.parse(url);

    // Intent: buka URL lewat aplikasi eksternal, bukan di dalam aplikasi.
    final bool berhasil = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!berhasil && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton.icon(
        onPressed: () => _bukaUrl(context),
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
