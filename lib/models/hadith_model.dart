class HadithModel {
  final int id;
  final String arabic;
  final String englishText;
  final String urduText;
  final String englishTranslation;
  final String urduTranslation;
  final String englishTafseer;
  final String urduTafseer;
  final String reference;

  HadithModel({
    required this.id,
    required this.arabic,
    required this.englishText,
    required this.urduText,
    required this.englishTranslation,
    required this.urduTranslation,
    required this.englishTafseer,
    required this.urduTafseer,
    required this.reference,
  });

  factory HadithModel.fromJson(Map<String, dynamic> json) {
    return HadithModel(
      id: json['id'],
      arabic: json['arabic'],
      englishText: json['englishText'],
      urduText: json['urduText'],
      englishTranslation: json['englishTranslation'],
      urduTranslation: json['urduTranslation'],
      englishTafseer: json['englishTafseer'],
      urduTafseer: json['urduTafseer'],
      reference: json['reference'],
    );
  }
}