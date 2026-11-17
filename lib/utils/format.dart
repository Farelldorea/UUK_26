String fmtDateTime(DateTime d) {
  const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  String two(int n) => n.toString().padLeft(2, '0');
  return '${days[d.weekday - 1]}, ${two(d.day)}/${two(d.month)}/${d.year} '
      '${two(d.hour)}:${two(d.minute)}';
}