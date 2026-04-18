import '../models/hadith_model.dart';

class HadithService {
  static final List<HadithModel> _hadithList = [
    HadithModel(
      arabic: "إنما الأعمال بالنيات",
      translation: "Actions are judged by intentions",
      explanation: "The value of deeds depends on the intentions behind them.",
      reference: "Bukhari & Muslim",
    ),
    HadithModel(
      arabic: "لا ضرر ولا ضرار",
      translation: "There should be no harm nor reciprocating harm",
      explanation: "Do not harm others or return harm.",
      reference: "Ibn Majah",
    ),
    HadithModel(
      arabic: "أحب الناس إلى الله أنفعهم للناس",
      translation: "The most beloved of people to Allah are those who are most beneficial to people.",
      explanation: "Helping others is a great deed.",
      reference: "Tabarani",
    ),
    HadithModel(
      arabic: "طلب العلم فريضة على كل مسلم",
      translation: "Seeking knowledge is an obligation upon every Muslim.",
      explanation: "Education is important for all.",
      reference: "Ibn Majah",
    ),
  ];

  static HadithModel getTodaysHadith() {
    // Calculate day of year
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(start).inDays;
    final index = dayOfYear % _hadithList.length;
    return _hadithList[index];
  }
}