/// Lightweight date/time formatting utilities that avoid pulling in the heavy
/// `intl` package. The functions here cover the few patterns the app needs.

String formatHm(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String formatMonthDayHourMinute(DateTime dt) {
  const months = [
    '',
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  final month = months[dt.month];
  final day = dt.day;
  return '$month $day ${formatHm(dt)}';
}
