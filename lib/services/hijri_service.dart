import 'package:intl/intl.dart';

class HijriService {
  // Reference: Jan 1, 2023 = 8 Jumada al-Thani 1444
  static const _refGregYear = 2023;
  static const _refGregMonth = 1;
  static const _refGregDay = 1;
  static const _refHijriYear = 1444;
  static const _refHijriMonth = 6;  // Jumada al-Thani
  static const _refHijriDay = 8;

  // Approximate month lengths for Hijri (alternating 30,29)
  static const _monthLengths = [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29];

  static Map<String, int> getCurrentHijriDate() {
    final now = DateTime.now();
    final refDate = DateTime(_refGregYear, _refGregMonth, _refGregDay);
    final diffDays = now.difference(refDate).inDays;

    int hijriYear = _refHijriYear;
    int hijriMonth = _refHijriMonth;
    int hijriDay = _refHijriDay + diffDays;

    // Adjust days to correct month/year
    while (hijriDay > _monthLengths[hijriMonth - 1]) {
      hijriDay -= _monthLengths[hijriMonth - 1];
      hijriMonth++;
      if (hijriMonth > 12) {
        hijriMonth = 1;
        hijriYear++;
      }
    }
    while (hijriDay < 1) {
      hijriMonth--;
      if (hijriMonth < 1) {
        hijriMonth = 12;
        hijriYear--;
      }
      hijriDay += _monthLengths[hijriMonth - 1];
    }

    return {
      'year': hijriYear,
      'month': hijriMonth,
      'day': hijriDay,
    };
  }

  static String getFormattedHijriDate(bool isUrdu) {
    final hijri = getCurrentHijriDate();
    final day = hijri['day']!;
    final month = isUrdu ? _getUrduMonthName(hijri['month']!) : _getEnglishMonthName(hijri['month']!);
    final year = hijri['year']!;

    if (isUrdu) {
      return '$day $month $year ہجری';
    } else {
      return '$day $month $year AH';
    }
  }

  static String _getEnglishMonthName(int month) {
    const months = [
      'Muharram', 'Safar', 'Rabi\' al-Awwal', 'Rabi\' al-Thani',
      'Jumada al-Ula', 'Jumada al-Thani', 'Rajab', 'Sha\'ban',
      'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah'
    ];
    return months[month - 1];
  }

  static String _getUrduMonthName(int month) {
    const months = [
      'محرم', 'صفر', 'ربیع الاول', 'ربیع الثانی',
      'جمادی الاول', 'جمادی الثانی', 'رجب', 'شعبان',
      'رمضان', 'شوال', 'ذوالقعدہ', 'ذوالحجہ'
    ];
    return months[month - 1];
  }

  static String getGregorianDate(bool isUrdu) {
    final now = DateTime.now();
    final formatter = DateFormat('dd MMMM yyyy');
    return formatter.format(now);
  }
}