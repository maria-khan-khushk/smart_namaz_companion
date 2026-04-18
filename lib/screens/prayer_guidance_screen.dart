import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/theme.dart';

class PrayerGuidanceScreen extends StatelessWidget {
  final String prayerName;

  const PrayerGuidanceScreen({Key? key, required this.prayerName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    final guidance = _getGuidance(prayerName, isUrdu);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? _getPrayerNameUrdu(prayerName) : prayerName),
        backgroundColor: AppColors.primaryMuted,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rakat section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUrdu ? 'رکعات کی تعداد' : 'Number of Rakats',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryMuted),
                    ),
                    SizedBox(height: 12),
                    ...guidance['rakats'].entries.map<Widget>((entry) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // Method section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUrdu ? 'پڑھنے کا طریقہ' : 'How to Perform',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryMuted),
                    ),
                    SizedBox(height: 12),
                    ...guidance['steps'].map<Widget>((step) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(child: Text(step, style: TextStyle(fontSize: 16))),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            if (guidance.containsKey('note')) SizedBox(height: 16),
            if (guidance.containsKey('note'))
              Card(
                elevation: 1,
                color: AppColors.warmLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    guidance['note'],
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getPrayerNameUrdu(String name) {
    switch (name) {
      case 'Fajr': return 'فجر';
      case 'Dhuhr': return 'ظہر';
      case 'Asr': return 'عصر';
      case 'Maghrib': return 'مغرب';
      case 'Isha': return 'عشاء';
      default: return name;
    }
  }

  Map<String, dynamic> _getGuidance(String prayer, bool isUrdu) {
    if (isUrdu) {
      switch (prayer) {
        case 'Fajr':
          return {
            'rakats': {
              'سنّت (مؤکدہ)': '2 رکعات',
              'فرض': '2 رکعات',
              'کل': '4 رکعات',
            },
            'steps': [
              'فجر کی 2 رکعات سنّت کی نیت کریں',
              '2 رکعات سنّت پڑھیں (سورہ فاتحہ اور کوئی سورہ)',
              'پھر 2 رکعات فرض کی نیت کریں',
              '2 رکعات فرض پڑھیں (مردوں کے لیے بلند آواز سے)',
              'سلام کے بعد آیت الکرسی اور تسبیحات پڑھیں',
            ],
            'note': 'فجر کا وقت طلوع آفتاب تک رہتا ہے۔ فرض سے پہلے سنّت پڑھنا بہت فضیلت رکھتا ہے۔',
          };
        case 'Dhuhr':
          return {
            'rakats': {
              'سنّت (مؤکدہ)': '4 رکعات',
              'فرض': '4 رکعات',
              'سنّت (مؤکدہ)': '2 رکعات',
              'نفل': '2 رکعات (اختیاری)',
              'کل': '12 رکعات',
            },
            'steps': [
              'پہلے 4 رکعات سنّت (مؤکدہ) پڑھیں',
              'پھر 4 رکعات فرض (آہستہ) پڑھیں',
              'پھر 2 رکعات سنّت (مؤکدہ) پڑھیں',
              'اختیاری: 2 رکعات نفل پڑھیں',
            ],
            'note': 'ظہر کا وقت زوال سے شروع ہو کر عصر تک رہتا ہے۔',
          };
        case 'Asr':
          return {
            'rakats': {
              'سنّت (غیر مؤکدہ)': '4 رکعات (اختیاری)',
              'فرض': '4 رکعات',
              'کل': '8 رکعات (4 فرض لازمی)',
            },
            'steps': [
              'اختیاری: 4 رکعات سنّت (غیر مؤکدہ) پڑھیں',
              'پھر 4 رکعات فرض (آہستہ) پڑھیں',
            ],
            'note': 'عصر کا وقت اس وقت شروع ہوتا ہے جب کسی چیز کا سایہ اس کی اونچائی کے برابر (حنفی) یا دوگنا (شافعی) ہو جائے۔',
          };
        case 'Maghrib':
          return {
            'rakats': {
              'فرض': '3 رکعات',
              'سنّت (مؤکدہ)': '2 رکعات',
              'نفل': '2 رکعات (اختیاری)',
              'کل': '7 رکعات',
            },
            'steps': [
              '3 رکعات فرض پڑھیں (پہلی دو رکعات میں بلند آواز، تیسری میں آہستہ)',
              'پھر 2 رکعات سنّت (مؤکدہ) پڑھیں',
              'اختیاری: 2 رکعات نفل پڑھیں',
            ],
            'note': 'مغرب کا وقت بہت مختصر ہوتا ہے۔ جلد از جلد پڑھیں۔',
          };
        case 'Isha':
          return {
            'rakats': {
              'سنّت (غیر مؤکدہ)': '4 رکعات',
              'فرض': '4 رکعات',
              'سنّت (مؤکدہ)': '2 رکعات',
              'نفل': '2 رکعات (اختیاری)',
              'وتر': '3 رکعات (واجب)',
              'کل': '15 رکعات',
            },
            'steps': [
              '4 رکعات سنّت (غیر مؤکدہ) پڑھیں',
              'پھر 4 رکعات فرض (پہلی دو رکعات میں بلند آواز) پڑھیں',
              'پھر 2 رکعات سنّت (مؤکدہ) پڑھیں',
              'اختیاری: 2 رکعات نفل پڑھیں',
              'پھر 3 رکعات وتر (واجب) پڑھیں - (2+1 کر کے یا ایک سلام سے)',
            ],
            'note': 'حنفی مسلک کے مطابق وتر واجب ہیں۔ انہیں تہجد کے بعد بھی پڑھا جا سکتا ہے۔',
          };
        default: return {'rakats': {'فرض': '4 رکعات'}, 'steps': ['نیت کریں اور معمول کے مطابق پڑھیں']};
      }
    } else {
      // English version
      switch (prayer) {
        case 'Fajr':
          return {
            'rakats': {
              'Sunnah (Muakkadah)': '2 Rakats',
              'Fard': '2 Rakats',
              'Total': '4 Rakats',
            },
            'steps': [
              'Make Niyyah for 2 Rakats Sunnah of Fajr',
              'Pray 2 Rakats Sunnah (reciting Surah Fatiha and any Surah)',
              'Then make Niyyah for 2 Rakats Fard of Fajr',
              'Pray 2 Rakats Fard (recite loudly for men)',
              'After Salam, recite Ayat-ul-Kursi and Tasbeeh',
            ],
            'note': 'Fajr time ends at sunrise. It is highly recommended to pray Sunnah before Fard.',
          };
        case 'Dhuhr':
          return {
            'rakats': {
              'Sunnah (Muakkadah)': '4 Rakats',
              'Fard': '4 Rakats',
              'Sunnah (Muakkadah)': '2 Rakats',
              'Nafl': '2 Rakats (optional)',
              'Total': '12 Rakats',
            },
            'steps': [
              'First pray 4 Rakats Sunnah (Muakkadah)',
              'Then 4 Rakats Fard (recite silently)',
              'Then 2 Rakats Sunnah (Muakkadah)',
              'Optional: 2 Rakats Nafl',
            ],
            'note': 'Dhuhr prayer time starts after sun passes zenith (Zawal) and lasts until Asr time.',
          };
        case 'Asr':
          return {
            'rakats': {
              'Sunnah (Ghair Muakkadah)': '4 Rakats (optional)',
              'Fard': '4 Rakats',
              'Total': '8 Rakats (4 Fard compulsory)',
            },
            'steps': [
              'Optional: Pray 4 Rakats Sunnah (Ghair Muakkadah)',
              'Then pray 4 Rakats Fard (recite silently)',
            ],
            'note': 'Asr time begins when shadow of an object becomes equal to its length (Hanafi) or twice (Shafi).',
          };
        case 'Maghrib':
          return {
            'rakats': {
              'Fard': '3 Rakats',
              'Sunnah (Muakkadah)': '2 Rakats',
              'Nafl': '2 Rakats (optional)',
              'Total': '7 Rakats',
            },
            'steps': [
              'Pray 3 Rakats Fard (recite loudly for first two Rakats, silently for third)',
              'Then pray 2 Rakats Sunnah (Muakkadah)',
              'Optional: 2 Rakats Nafl',
            ],
            'note': 'Maghrib time is short. Pray as soon as possible after sunset.',
          };
        case 'Isha':
          return {
            'rakats': {
              'Sunnah (Ghair Muakkadah)': '4 Rakats',
              'Fard': '4 Rakats',
              'Sunnah (Muakkadah)': '2 Rakats',
              'Nafl': '2 Rakats (optional)',
              'Witr': '3 Rakats (Wajib)',
              'Total': '15 Rakats',
            },
            'steps': [
              'Pray 4 Rakats Sunnah (Ghair Muakkadah)',
              'Then 4 Rakats Fard (recite loudly for first two Rakats)',
              'Then 2 Rakats Sunnah (Muakkadah)',
              'Optional: 2 Rakats Nafl',
              'Then 3 Rakats Witr (Wajib) - can be prayed as 2+1 or all 3 with one Salam',
            ],
            'note': 'Witr is Wajib according to Hanafi school. It can be prayed after Tahajjud as well.',
          };
        default: return {'rakats': {'Fard': '4 Rakats'}, 'steps': ['Make Niyyah and pray as usual']};
      }
    }
  }
}