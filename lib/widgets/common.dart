import 'package:flutter/material.dart';

import '../models/category.dart';
import '../theme.dart';

/// Gambar jaringan dengan latar polos saat memuat atau gagal.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(color: AppColors.line, child: SizedBox.expand());
    if (url == null || url!.isEmpty) return placeholder;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      frameBuilder: (_, child, frame, sync) => sync
          ? child
          : AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 400),
              child: child,
            ),
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

/// "■ TEKNOLOGI"
class CategoryLabel extends StatelessWidget {
  const CategoryLabel(this.category, {super.key, this.color = AppColors.accent});

  final NewsCategory category;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 6, height: 6, color: color),
      const SizedBox(width: 7),
      Text(category.name.toUpperCase(), style: AppText.label(color: color)),
    ],
  );
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.url, this.size = 32});

  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = Center(
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: AppText.ui(size * 0.42, color: AppColors.paper, weight: FontWeight.w600),
      ),
    );
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: ColoredBox(
          color: AppColors.inkSoft,
          child: url == null
              ? initial
              : Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => initial),
        ),
      ),
    );
  }
}

/// Garis ganda khas kepala surat kabar.
class DoubleRule extends StatelessWidget {
  const DoubleRule({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(height: 2.5, color: AppColors.ink),
      const SizedBox(height: 3),
      Container(height: 0.8, color: AppColors.ink),
    ],
  );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        Text('Gagal memuat', style: AppText.headline(20)),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppText.ui(14, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
      ],
    ),
  );
}

/// Tombol bulat putih — terlihat jelas di atas foto maupun kertas.
class RoundButton extends StatelessWidget {
  const RoundButton({super.key, required this.icon, required this.onPressed, this.tooltip});

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(6),
    decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle, boxShadow: softShadow),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: AppColors.ink),
    ),
  );
}

Future<bool> confirmDialog(BuildContext context, {required String title, required String message}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message, style: AppText.ui(14.5, color: AppColors.inkSoft)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    ) ??
    false;
