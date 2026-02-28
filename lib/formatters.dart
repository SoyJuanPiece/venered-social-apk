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

String formatTimeAgo(DateTime dateTime) {
  final Duration diff = DateTime.now().difference(dateTime);

  if (diff.inDays >= 365) {
    final years = (diff.inDays / 365).floor();
    return 'Hace $years año${years == 1 ? '' : 's'}';
  } else if (diff.inDays >= 30) {
    final months = (diff.inDays / 30).floor();
    return 'Hace $months mes${months == 1 ? '' : 'es'}';
  } else if (diff.inDays >= 7) {
    final weeks = (diff.inDays / 7).floor();
    return 'Hace $weeks semana${weeks == 1 ? '' : 's'}';
  } else if (diff.inDays > 0) {
    return 'Hace ${diff.inDays} día${diff.inDays == 1 ? '' : 's'}';
  } else if (diff.inHours > 0) {
    return 'Hace ${diff.inHours} hora${diff.inHours == 1 ? '' : 's'}';
  } else if (diff.inMinutes > 0) {
    return 'Hace ${diff.inMinutes} minuto${diff.inMinutes == 1 ? '' : 's'}';
  } else {
    return 'Hace un momento';
  }
}

