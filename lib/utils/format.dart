const _months = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', //
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

/// "Minggu, 11 Oktober 2026"
String formatDate(DateTime d) => '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

/// "5 menit lalu", "Kemarin", "11 Okt 2026"
String timeAgo(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays == 1) return 'Kemarin';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return '${d.day} ${_months[d.month - 1].substring(0, 3)} ${d.year}';
}

/// 2101 → "2,1 rb"
String compactNumber(int n) {
  if (n < 1000) return '$n';
  final s = (n / 1000).toStringAsFixed(1).replaceAll('.', ',');
  return '${s.endsWith(',0') ? s.substring(0, s.length - 2) : s} rb';
}
