import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/theme.dart';

class GuidanceScreen extends StatelessWidget {
  final List<Map<String, String>> _duas = [
    // 1. Tahlil
    {
      'arabic': 'لَا إِلٰهَ إِلَّا اللّٰهُ',
      'english': 'There is no god but Allah.',
      'urdu': 'اللہ کے سوا کوئی معبود نہیں۔',
      'reference': 'Nasā’ī – The best dhikr',
    },
    // 2. Tasbih, Tahmid, Takbir
    {
      'arabic': 'سُبْحَانَ اللّٰهِ\nاَلْحَمْدُ لِلّٰهِ\nاَللّٰهُ أَكْبَرُ',
      'english': 'Subḥāna-llāh. Alḥamdu li-llāh, Allāhu akbar.\nAllah is free from imperfection. All praise be to Allah. Allah is the Greatest.',
      'urdu': 'اللہ پاک ہے۔ تمام تعریفیں اللہ کے لیے ہیں۔ اللہ سب سے بڑا ہے۔',
      'reference': 'Muslim – The most beloved statements to Allah are these four.',
    },
    // 3. Hawqalah
    {
      'arabic': 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ',
      'english': 'Lā ḥawla wa lā quwwata illā bi-llāh.\nThere is no power (in averting evil) or strength (in attaining good) except through Allah.',
      'urdu': 'برائی سے بچنے کی طاقت اور بھلائی حاصل کرنے کی قوت صرف اللہ کی طرف سے ہے۔',
      'reference': 'Hākim, Tirmidhī – A treasure from the treasures of Paradise.',
    },
    // 4. Salawat (Durood Ibrahim)
    {
      'arabic': 'اَللّٰهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ ، كَمَا صَلَّيْتَ عَلَىٰ إِبْرَاهِيْمَ وَعَلَىٰ آلِ إِبْرَاهِيْمَ ، إِنَّكَ حَمِيْدٌ مَّجِيْدٌ ، اَللّٰهُمَّ بَارِكْ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ ، كَمَا بَارَكْتَ عَلَىٰ إِبْرَاهِيْمَ وَعَلَىٰ آلِ إِبْرَاهِيْمَ ، إِنَّكَ حَمِيْدٌ مَّجِيْدٌ',
      'english': 'O Allah, honour and have mercy upon Muhammad and the family of Muhammad as You have honoured and had mercy upon Ibrāhīm and the family of Ibrāhīm. Indeed, You are the Most Praiseworthy, the Most Glorious. O Allah, bless Muhammad and the family of Muhammad as You have blessed Ibrāhīm and the family of Ibrāhīm. Indeed, You are the Most Praiseworthy, the Most Glorious.',
      'urdu': 'اے اللہ، محمد اور آل محمد پر رحمت نازل فرما جیسا کہ تو نے ابراہیم اور آل ابراہیم پر رحمت نازل فرمائی۔ بیشک تو قابل تعریف اور بزرگی والا ہے۔ اے اللہ، محمد اور آل محمد میں برکت عطا فرما جیسا کہ تو نے ابراہیم اور آل ابراہیم میں برکت عطا فرمائی۔ بیشک تو قابل تعریف اور بزرگی والا ہے۔',
      'reference': 'Bukhārī 3370',
    },
    // 5. The Best Statement Uttered By All the Prophets
    {
      'arabic': 'لَا إِلٰهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيْكَ لَهُ ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيْرٌ',
      'english': 'Lā ilāha illā-Allāh, waḥdahū lā sharīka lah, lahu-l-mulk, wa lahu-l-ḥamd, wa Huwa ʿalā kulli shay’in Qadīr.\nThere is no god but Allah. He is Alone and He has no partner whatsoever. To Him Alone belong all sovereignty and all praise. He is over all things All-Powerful.',
      'urdu': 'اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے، اس کا کوئی شریک نہیں۔ اسی کے لیے بادشاہت ہے اور اسی کے لیے تمام تعریفیں ہیں، اور وہ ہر چیز پر قادر ہے۔',
      'reference': 'Tirmidhī 3585 – Best du‘ā’ of the day of ‘Arafah.',
    },
    // 6. The Best Words After the Quran (four statements)
    {
      'arabic': 'سُبْحَانَ اللهِ ، وَالْحَمْدُ لِلهِ وَلَا إِلٰهَ إِلَّا اللهُ ، وَاللهُ أَكْبَرُ',
      'english': 'Subḥāna-llāh, wal-lḥamdu li-llāh, wa lā ilāha illa-llāhu wa-llāhu akbar.\nAllah is free from imperfection. All praise be to Allah. There is no god worthy of worship but Allah. Allah is the Greatest.',
      'urdu': 'اللہ پاک ہے، تمام تعریفیں اللہ کے لیے ہیں، اللہ کے سوا کوئی معبود نہیں، اللہ سب سے بڑا ہے۔',
      'reference': 'Muslim 2137',
    },
    // 7. Heavy On the Scales & Beloved to Allah
    {
      'arabic': 'سُبْحَانَ اللهِ وَبِحَمْدِهِ ، سُبْحَانَ اللهِ الْعَظِيْم',
      'english': 'Subḥāna-llāhi wa bi-ḥamdihī, subḥāna-llāhi-l-aẓīm.\nAllah is free from imperfection and all praise is due to Him, Allah is free from imperfection, the Greatest.',
      'urdu': 'اللہ پاک ہے اور اسی کی تعریف ہے، اللہ عظیم پاک ہے۔',
      'reference': 'Bukhārī 6682',
    },
    // 8. Supplicate Frequently With… (Ya Dhal Jalali wal Ikram)
    {
      'arabic': 'يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
      'english': 'Yā Dha-l-Jalāli wa-l-Ikrām\nO The Lord of Majesty & Honour',
      'urdu': 'اے جلال اور اکرام والے رب',
      'reference': 'Tirmidhī 3525',
    },
    // 9. When Distressed, the Prophet ﷺ Would Say…
    {
      'arabic': 'يَا حَيُّ يَا قَيُّوْمُ ، بِرَحْمَتِكَ أَسْتَغِيْثُ',
      'english': 'Yā Ḥayyu yā Qayyūm, bi-raḥmatika astaghīth.\nO The Ever Living, The One Who sustains and protects all that exists; I seek assistance through Your Mercy.',
      'urdu': 'اے زندہ اور قائم رکھنے والے، میں تیری رحمت کے سہارے مدد مانگتا ہوں۔',
      'reference': 'Tirmidhī 3524',
    },
    // 10. For Difficult Times (Dua of Yunus)
    {
      'arabic': 'لَآ إِلٰهَ إِلَّآ أَنْتَ سُبۡحٰنَكَ إِنِّيْ كُنْتُ مِنَ الظّٰلِمِيْنَ',
      'english': 'Lā ilāha illā Anta subḥānaka innī kuntu mina-ẓ-ẓālimīn.\nThere is no god worthy of worship except You; You are free from all imperfection. Indeed, I have been of the wrongdoers.',
      'urdu': 'تیرے سوا کوئی معبود نہیں، تو پاک ہے، بیشک میں ظالموں میں سے ہوں۔',
      'reference': 'Tirmidhī 3505 – answered supplication.',
    },
    // 11. All of Your Sins Forgiven
    {
      'arabic': 'أَسْتَغْفِرُ اللهَ الْعَظِيْمَ الَّذِيْ لَا إِلٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّوْمُ ، وَأَتُوْبُ إِلَيْهِ',
      'english': 'Astaghfiru-l-llāha-l-aẓīm al-ladhī lā ilāha illā Huwa-l-Ḥayyu-l-Qayyūm, wa atūbu ilayh.\nI seek forgiveness from Allah, the Greatest, whom there is none worthy of worship except Him, The Ever Living, The One Who sustains and protects all that exists, I turn in repentance towards you.',
      'urdu': 'میں اللہ عظیم سے مغفرت طلب کرتا ہوں جس کے سوا کوئی معبود نہیں، وہ زندہ اور قائم ہے، اور میں اسی کی طرف توبہ کرتا ہوں۔',
      'reference': 'Tirmidhī 3577',
    },
    // 12. Dua of the Grief-stricken Prophet Yunus (same as #10 but included as separate per user)
    {
      'arabic': 'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      'english': 'Lā ilāha illā Anta subḥānaka innī kuntu mina-ẓ-ẓālimīn.',
      'urdu': 'تیرے سوا کوئی معبود نہیں، تو پاک ہے، بیشک میں ظالموں میں سے ہوں۔',
      'reference': 'Tirmidhī – explanation attached.',
    },
    // 13. Dua of Prophet Musa AS for Forgiveness
    {
      'arabic': 'رَبِّ إِنِّي ظَلَمْتُ نَفْسِي فَاغْفِرْ لِي',
      'english': 'Rabbi innī ẓalamtu nafsī fa-ghfirlī.\nMy Lord, I have certainly wronged myself, so forgive me.',
      'urdu': 'اے میرے رب، بیشک میں نے اپنے آپ پر ظلم کیا، پس مجھے بخش دے۔',
      'reference': 'Surah Al-Qasas 28:16',
    },
    // 14. Dua of Prophet Adam AS and Hawwa for Forgiveness
    {
      'arabic': 'رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
      'english': 'Rabbanā ẓalamnā anfusanā wa il-lam taghfir lanā wa tarḥamnā la-nakūnanna minal-khāsirīn.\nOur Lord, we have wronged ourselves. If You do not forgive us and have mercy upon us, we will surely be amongst the losers.',
      'urdu': 'اے ہمارے رب، ہم نے اپنی جانوں پر ظلم کیا۔ اگر تو نے ہمیں معاف نہ کیا اور ہم پر رحم نہ کیا تو ہم نقصان اٹھانے والوں میں سے ہو جائیں گے۔',
      'reference': 'Surah Al-A‘raf 7:23',
    },
    // 15. Dua of Prophet Musa for Forgiveness (another)
    {
      'arabic': 'أَنْتَ وَلِيُّنَا فَاغْفِرْ لَنَا وَارْحَمْنَا ۖ وَأَنْتَ خَيْرُ الْغَافِرِينَ',
      'english': 'Anta Walliyyunā fa-ghfir lanā war-ḥamnā wa Anta khayrul-ghāfirīn.\nYou are our Protector, so forgive us and have mercy upon us. You are the best of those who forgive.',
      'urdu': 'تو ہمارا ولی ہے، سو ہمیں بخش دے اور ہم پر رحم فرما، اور تو بہترین بخشش کرنے والا ہے۔',
      'reference': 'Surah Al-A‘raf 7:155',
    },
    // 16. Dua of the Pious for Forgiveness & Protection From Hell-fire
    {
      'arabic': 'رَبَّنَا إِنَّنَا آمَنَّا فَاغْفِرْ لَنَا ذُنُوبَنَا وَقِنَا عَذَابَ النَّارِ',
      'english': 'Rabbanā in-nanā āmannā fa-ghfir lanā dhunūbanā wa qinā ʿadhāba-n-nār.\nOur Lord, indeed we have believed, so forgive us our sins and protect us from the punishment of the Fire.',
      'urdu': 'اے ہمارے رب، ہم ایمان لائے ہیں، پس ہمارے گناہ معاف فرما اور ہمیں آگ کے عذاب سے بچا۔',
      'reference': 'Surah Aal-Imran 3:16',
    },
    // 17. Dua for Forgiveness & Mercy
    {
      'arabic': 'رَبِّ اغْفِرْ وَارْحَمْ وَأَنْتَ خَيْرُ الرَّاحِمِينَ',
      'english': 'Rabbi-ghfir wa-rḥam wa Anta khayru-r-rāḥimīn.\nMy Lord, forgive and have mercy. You are the Best of those who are merciful.',
      'urdu': 'اے میرے رب، بخش دے اور رحم فرما، اور تو بہترین رحم کرنے والا ہے۔',
      'reference': 'Surah Al-Mu’minun 23:118',
    },
    // 18. Dua for Yourself, the Deceased & the Ummah
    {
      'arabic': 'رَبَّنَا اغْفِرْ لَنَا وَلِإِخْوَانِنَا الَّذِينَ سَبَقُونَا بِالْإِيمَانِ وَلَا تَجْعَلْ فِي قُلُوبِنَا غِلًّا لِلَّذِينَ آمَنُوا رَبَّنَا إِنَّكَ رَءُوفٌ رَحِيمٌ',
      'english': 'Rabbana-ghfir lanā wa li-ikhwānina-l-ladhīna sabaqūnā bil-īmān, wa lā tajʿal fī qulūbinā ghilla-l-lil-ladhīna āmanū Rabbanā innaka Ra’ūfu-r-Raḥīm.\nOur Lord, forgive us and our brothers who preceded us in faith. Do not put in our hearts any hatred toward those who have believed. Our Lord, indeed You are the Most Compassionate, the Ever-Merciful.',
      'urdu': 'اے ہمارے رب، ہمیں اور ہمارے اُن بھائیوں کو بخش دے جو ہم سے پہلے ایمان لائے۔ اور ہمارے دلوں میں ایمان والوں کے لیے کوئی کینہ نہ رکھ۔ اے ہمارے رب، یقیناً تو نہایت شفقت والا، بہت رحم کرنے والا ہے۔',
      'reference': 'Surah Al-Hashr 59:10',
    },
    // 19. Dua of Asiya for a House Near Allah in Paradise
    {
      'arabic': 'رَبِّ ابْنِ لِي عِنْدَكَ بَيْتًا فِي الْجَنَّةِ',
      'english': 'Rabbi-b-ni lī ʿindaka baytan fi-l-Jannah.\nMy Lord, build for me, near You, a house in Paradise.',
      'urdu': 'اے میرے رب، میرے لیے اپنے پاس جنت میں ایک گھر بنا دے۔',
      'reference': 'Surah At-Tahrim 66:11',
    },
    // 20. Dua of Prophet Musa AS Expressing His Dire Need
    {
      'arabic': 'رَبِّ إِنِّي لِمَا أَنْزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ',
      'english': 'Rabbi innī limā anzalta illayya min khayrin faqīr.\nMy Lord, truly I am in dire need of any good which You may send me.',
      'urdu': 'اے میرے رب، تو جو کچھ بھلائی میری طرف نازل کرے، میں اس کا محتاج ہوں۔',
      'reference': 'Surah Al-Qasas 28:24',
    },
    // 21. Dua for Increase in Knowledge
    {
      'arabic': 'رَبِّ زِدْنِي عِلْمًا',
      'english': 'Rabbi zidnī ʿilmā.\nMy Lord, increase me in knowledge.',
      'urdu': 'اے میرے رب، میرے علم میں اضافہ فرما۔',
      'reference': 'Surah Ta-Ha 20:114',
    },
    // 22. Dua of Prophet Musa AS for Inner Peace & Strength
    {
      'arabic': 'رَبِّ اشْرَحْ لِي صَدْرِي. وَيَسِّرْ لِي أَمْرِي',
      'english': 'Rabbi-sh-shraḥ lī ṣadrī. Wa yassir lī amrī.\nMy Lord, put my heart at peace for me, and make my task easy for me.',
      'urdu': 'اے میرے رب، میرے سینے کو کھول دے اور میرے کام کو آسان کر دے۔',
      'reference': 'Surah Ta-Ha 20:25-26',
    },
    // 23. Dua of Prophet Ibrahim AS for Wisdom & a Good End
    {
      'arabic': 'رَبِّ هَبْ لِي حُكْمًا وَأَلْحِقْنِي بِالصَّالِحِينَ. وَاجْعَلْ لِي لِسَانَ صِدْقٍ فِي الْآخِرِينَ. وَاجْعَلْنِي مِنْ وَرَثَةِ جَنَّةِ النَّعِيمِ… وَلَا تُخْزِنِي يَوْمَ يُبْعَثُونَ. يَوْمَ لَا يَنْفَعُ مَالٌ وَلَا بَنُونَ. إِلَّا مَنْ أَتَى اللَّهَ بِقَلْبٍ سَلِيمٍ',
      'english': 'Rabbi hab lī ḥukma-w-wa alḥiqnī bi-ṣ-ṣāliḥīn. Wa-jʿal-lī lisāna ṣidqin fil-ākhirīn. Wa-jʿalnī mi-w-warathati Jannati-n-Naʿīm… Wa lā tukhzinī yawma yubʿathūn. Yawma lā yanfaʿu mālu-w-wa lā banūn. Illā man ata-llāha bi-qalbin salīm.\nMy Lord, grant me wisdom and join me with the righteous. And grant that I may be spoken of with honour amongst the later generations. And make me amongst those who will inherit the Garden of Bliss… And do not disgrace me on the Day they will be resurrected – the Day when neither wealth nor children will be of any use – except for the one who comes to Allah with a sound heart.',
      'urdu': 'اے میرے رب، مجھے حکم عطا فرما اور مجھے نیک لوگوں میں شامل فرما۔ اور میرا ذکر پچھلوں میں اچھا رکھ۔ اور مجھے نعمتوں والی جنت کے وارثوں میں سے بنا… اور مجھے اس دن رسوا نہ کر جب لوگ اٹھائے جائیں گے۔ جس دن نہ مال فائدہ دے گا نہ اولاد، مگر جو اللہ کے پاس سلامت دل لے کر آئے۔',
      'reference': 'Surah Ash-Shu‘ara 26:83-89',
    },
    // 24. Dua of Prophet Ibrahim AS for His Progeny & Parents
    {
      'arabic': 'رَبِّ اجْعَلْنِي مُقِيمَ الصَّلَاةِ وَمِنْ ذُرِّيَّتِي ۚ رَبَّنَا وَتَقَبَّلْ دُعَاءِ. رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ',
      'english': 'Rabbij-ʿalnī muqīma-ṣ-ṣalāti wa min dhurriy-yatī Rabbanā wa taqabbal duʿā’. Rabbana-ghfir lī wa li-wālidayya wa lil-mu’minīna yawma yaqūmul-ḥisāb.\nMy Lord, make me steadfast in salah, and my offspring as well. Our Lord, accept my prayer. Our Lord, forgive me, my parents, and all the believers on the Day when the Reckoning will take place.',
      'urdu': 'اے میرے رب، مجھے اور میری اولاد کو نماز قائم کرنے والا بنا۔ اے ہمارے رب، میری دعا قبول فرما۔ اے ہمارے رب، مجھے، میرے والدین کو اور تمام مومنوں کو اس دن بخش دے جب حساب قائم ہوگا۔',
      'reference': 'Surah Ibrahim 14:40-41',
    },
    // 25. Dua for Parents
    {
      'arabic': 'رَبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
      'english': 'Rabbi-r-ḥamhumā kamā rabbayānī ṣaghīrā.\nMy Lord, have mercy upon them (my parents) as they raised and nurtured me when I was young.',
      'urdu': 'اے میرے رب، اُن دونوں پر رحم فرما جیسا کہ اُنہوں نے مجھے بچپن میں پالا۔',
      'reference': 'Surah Al-Isra 17:24',
    },
    // 26. Dua for a Joyous Household
    {
      'arabic': 'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
      'english': 'Rabbanā hab lanā min azwājinā wa dhuriyyātinā qurrata aʿyuni-w-wajʿalnā lil-muttaqīna imāmā.\nOur Lord, grant us spouses and offspring who will be a joy to our eyes, and make us leaders of those who have taqwa (piety).',
      'urdu': 'اے ہمارے رب، ہمیں ہماری بیویوں اور اولاد سے آنکھوں کی ٹھنڈک عطا فرما، اور ہمیں پرہیزگاروں کا پیشوا بنا دے۔',
      'reference': 'Surah Al-Furqan 25:74',
    },
    // 27. Dua for Seeking Protection from Shaytan
    {
      'arabic': 'رَبِّ أَعُوذُ بِكَ مِنْ هَمَزَاتِ الشَّيَاطِينِ. وَأَعُوذُ بِكَ رَبِّ أَنْ يَحْضُرُونِ',
      'english': 'Rabbi aʿūdhu bika min hamazāti-sh-shayāṭīn. Wa aʿūdhu bika Rabbi ay-yaḥḍurūn.\nMy Lord, I seek protection with You from the promptings of the devils; and I seek protection in You, my Lord, from their coming near me.',
      'urdu': 'اے میرے رب، میں شیاطین کے وسوسوں سے تیری پناہ مانگتا ہوں۔ اور اے میرے رب، میں تیری پناہ مانگتا ہوں کہ وہ میرے پاس آئیں۔',
      'reference': 'Surah Al-Mu’minun 23:97-98',
    },
    // 28. Dua for Forgiveness & Ease (last verses of Surah Baqarah)
    {
      'arabic': 'رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
      'english': 'Rabbanā lā tu’ākidhnā in-nasīnā aw akhṭa’nā, Rabbanā wa lā taḥmil ʿalaynā iṣran kamā ḥamaltahū ʿala-l-ladhīna min qablinā, Rabbanā wa lā tuḥammilnā mā lā ṭāqata lanā bih, waʿfu ʿanna wa-ghfir lanā war-ḥamnā Anta Mawlānā fa-nṣurnā ʿala-l-qawmil-kafirīn.\nOur Lord, do not impose blame upon us if we have forgotten or erred. Our Lord, and do not lay upon us a burden as You laid upon those before us. Our Lord, and do not burden us with that which we have no ability to bear. Pardon us, forgive us and have mercy upon us. You are our Protector, so help us against the disbelieving people.',
      'urdu': 'اے ہمارے رب، ہمیں نہ پکڑ اگر ہم بھول گئے یا غلطی کر بیٹھے۔ اے ہمارے رب، ہم پر ایسا بوجھ نہ ڈال جیسا تو نے ہم سے پہلے لوگوں پر ڈالا۔ اے ہمارے رب، ہم پر وہ بوجھ نہ ڈال جس کی ہمیں طاقت نہیں۔ اور ہمیں معاف کر، بخش دے اور رحم فرما۔ تو ہمارا مولیٰ ہے، سو کافروں کے خلاف ہماری مدد فرما۔',
      'reference': 'Surah Al-Baqarah 2:285-286',
    },
    // 29. Dua for Forgiveness & Victory
    {
      'arabic': 'رَبَّنَا اغْفِرْ لَنَا ذُنُوبَنَا وَإِسْرَافَنَا فِي أَمْرِنَا وَثَبِّتْ أَقْدَامَنَا وَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
      'english': 'Rabbana-ghfir lanā dhunūbanā wa isrāfanā fī amrinā wa thabbit aqdāmanā wa-nṣurnā ʿala-l-qawmil-kafirīn.\nOur Lord, forgive us our sins and our extravagance in our affairs. Make our feet firm, and help us against the disbelieving people.',
      'urdu': 'اے ہمارے رب، ہمارے گناہ معاف فرما اور ہمارے معاملے میں ہماری زیادتیوں کو معاف کر، ہمارے قدم جما دے اور کافروں کے خلاف ہماری مدد فرما۔',
      'reference': 'Surah Aal-Imran 3:147',
    },
    // 30. Dua for Firmness & Victory (same as above but different reference)
    {
      'arabic': 'رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَثَبِّتْ أَقْدَامَنَا وَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
      'english': 'Rabbanā afrigh ʿalaynā ṣabra-w-wa thabbit aqdāmanā wa-nṣurnā ʿala-l-qawmil-kafirīn.\nOur Lord, pour upon us patience, make our feet firm, and help us against the disbelieving people.',
      'urdu': 'اے ہمارے رب، ہم پر صبر نازل فرما، ہمارے قدم جما دے اور کافروں کے خلاف ہماری مدد فرما۔',
      'reference': 'Surah Al-Baqarah 2:250',
    },
    // 31. Dua of Prophet Lut AS for Help Against The Corrupt
    {
      'arabic': 'رَبِّ انْصُرْنِي عَلَى الْقَوْمِ الْمُفْسِدِينَ',
      'english': 'Rabbin-ṣurnī ʿala-l-qawmi-l-mufsidīn.\nMy Lord, support me against the people who spread corruption.',
      'urdu': 'اے میرے رب، مجھے فساد پھیلانے والوں کے خلاف نصرت دے۔',
      'reference': 'Surah Al-‘Ankabut 29:30',
    },
    // 32. Hasbunallahu wa ni'mal wakeel
    {
      'arabic': 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      'english': 'Hasbunallahu wa ni‘mal wakeel.\nAllah (Alone) is Sufficient for us, and He is the Best Disposer of affairs (for us).',
      'urdu': 'اللہ ہمارے لیے کافی ہے اور وہ بہترین کارساز ہے۔',
      'reference': 'Surah Aal-Imran 3:173',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? 'اذکار اور دعائیں' : 'Dhikr & Duas'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _duas.length,
        itemBuilder: (context, index) {
          final dua = _duas[index];
          final arabic = dua['arabic']!;
          final translation = isUrdu ? dua['urdu']! : dua['english']!;
          final reference = dua['reference']!;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    arabic,
                    style: const TextStyle(fontSize: 20, fontFamily: 'serif', height: 1.5),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    translation,
                    style: TextStyle(fontSize: 16, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reference,
                    style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}