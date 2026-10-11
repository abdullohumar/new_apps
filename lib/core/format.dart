import 'dart:math' as math;

const _months = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', //
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

String _two(int n) => n.toString().padLeft(2, '0');

/// "Minggu, 11 Oktober 2026"
String fullDate(DateTime d) =>
    '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

/// "11 Okt 2026"
String shortDate(DateTime d) =>
    '${d.day} ${_months[d.month - 1].substring(0, 3)} ${d.year}';

/// "11 Oktober 2026, 13.54"
String dateTime(DateTime d) =>
    '${d.day} ${_months[d.month - 1]} ${d.year}, ${_two(d.hour)}.${_two(d.minute)}';

String timeAgo(DateTime? d, {DateTime? now}) {
  if (d == null) return '';
  final diff = (now ?? DateTime.now()).difference(d);
  if (diff.isNegative || diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inHours < 48) return 'Kemarin';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return shortDate(d);
}

/// 2101 → "2,1 rb"
String compact(int n) {
  String fmt(double v, String unit) {
    final s = v.toStringAsFixed(1).replaceAll('.', ',');
    return '${s.endsWith(',0') ? s.substring(0, s.length - 2) : s} $unit';
  }

  if (n < 1000) return '$n';
  if (n < 1000000) return fmt(n / 1000, 'rb');
  return fmt(n / 1000000, 'jt');
}

int readingMinutes(String? text) {
  if (text == null || text.trim().isEmpty) return 1;
  final words = text.trim().split(RegExp(r'\s+')).length;
  return math.max(1, (words / 200).ceil());
}

String editionLabel(DateTime d) => switch (d.hour) {
      < 11 => 'Edisi Pagi',
      < 15 => 'Edisi Siang',
      < 19 => 'Edisi Sore',
      _ => 'Edisi Malam',
    };

List<String> paragraphs(String? content) => (content ?? '')
    .split(RegExp(r'\n\s*\n'))
    .map((p) => p.trim())
    .where((p) => p.isNotEmpty)
    .toList();

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

/// Normalisasi seperti API: huruf kecil, selain huruf/angka menjadi "-".
String slugify(String s) => s
    .toLowerCase()
    .trim()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');
