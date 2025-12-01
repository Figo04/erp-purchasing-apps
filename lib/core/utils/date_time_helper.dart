class DateTimeHelper {
  DateTimeHelper._();

  /// Format DateTime untuk backend dengan timezone
  /// Output: "2025-11-28T09:37:41+07:00"
  static String formatForBackend(DateTime dateTime) {
    // Pastikan menggunakan local time (WIB/Jakarta)
    final localDateTime = dateTime.toLocal();
    
    // Get ISO string
    String isoString = localDateTime.toIso8601String();
    
    // Jika sudah ada timezone, return as is
    if (isoString.contains('+') || isoString.endsWith('Z')) {
      return isoString;
    }
    
    // Jika tidak ada timezone, tambahkan timezone Jakarta (+07:00)
    // Remove microseconds if exists, keep only milliseconds or seconds
    if (isoString.contains('.')) {
      isoString = isoString.split('.')[0];
    }
    
    return '$isoString+07:00';
  }

  /// Parse DateTime dari backend response
  static DateTime parseFromBackend(String dateTimeString) {
    return DateTime.parse(dateTimeString);
  }
}