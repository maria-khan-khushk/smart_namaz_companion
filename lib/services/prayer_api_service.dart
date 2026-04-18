// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../models/prayer_time_model.dart';


// class PrayerApiService {
//   static const String baseUrl = "http://api.aladhan.com/v1/timings";

//   Future<PrayerTimeModel> fetchPrayerTimes(double lat, double lng) async {
//     final date = DateTime.now().toIso8601String().split('T')[0];
//     final url = Uri.parse("$baseUrl/$date?latitude=$lat&longitude=$lng&method=2");

//     final response = await http.get(url);
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       final timings = data['data']['timings'];
//       return PrayerTimeModel.fromJson(timings);
//     } else {
//       throw Exception("Failed to load prayer times");
//     }
//   }
// }
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_time_model.dart';

class PrayerApiService {
  static const String baseUrl = "http://api.aladhan.com/v1/timings";
  static const int timeoutSeconds = 10; // Timeout after 10 seconds

  Future<PrayerTimeModel> fetchPrayerTimes(double lat, double lng) async {
    final date = DateTime.now().toIso8601String().split('T')[0];
    final url = Uri.parse("$baseUrl/$date?latitude=$lat&longitude=$lng&method=2");

    try {
      final response = await http
          .get(url)
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timings = data['data']['timings'];
        return PrayerTimeModel.fromJson(timings);
      } else {
        throw Exception("Failed to load prayer times: ${response.statusCode}");
      }
    } catch (e) {
      // Timeout or network error
      throw Exception("Network error: $e");
    }
  }
}