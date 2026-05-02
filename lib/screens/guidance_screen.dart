import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/theme.dart';

// ── All sections & duas ───────────────────────────────────────────────────────
const List<Map<String, dynamic>> _sections = [
  {
    'heading': 'Basic Daily Tasbeeh',
    'headingUrdu': 'بنیادی روزانہ تسبیحات',
    'icon': Icons.radio_button_checked_rounded,
    'duas': [
      {'arabic':'سُبْحَانَ اللَّهِ','english':'SubhanAllah — Glory be to Allah · 33×','urdu':'سبحان اللہ — اللہ پاک ہے · ٣٣ مرتبہ','reference':'Sunan Ibn Mājah 3807'},
      {'arabic':'اَلْحَمْدُ لِلَّهِ','english':'Alhamdulillah — Praise be to Allah · 33×','urdu':'الحمد للہ — تمام تعریفیں اللہ کے لیے · ٣٣ مرتبہ','reference':'Sahih Muslim 1344'},
      {'arabic':'اَللَّهُ أَكْبَرُ','english':'AllahuAkbar — Allah is the Greatest · 33×','urdu':'اللہ اکبر — اللہ سب سے بڑا ہے · ٣٣ مرتبہ','reference':'Sahih Muslim 1344'},
      {'arabic':'لَا إِلَٰهَ إِلَّا اللَّهُ','english':'La ilaha illallah — There is no god but Allah.','urdu':'لا الہ الا اللہ — اللہ کے سوا کوئی معبود نہیں۔','reference':'Sahih Bukhari 6306'},
      {'arabic':'أَسْتَغْفِرُ اللَّهَ','english':'Astaghfirullah — I seek forgiveness from Allah.','urdu':'استغفر اللہ — میں اللہ سے مغفرت طلب کرتا ہوں۔','reference':'Sahih Bukhari 6306'},
      {'arabic':'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ','english':'La hawla wa la quwwata illa billah — There is no power or strength except through Allah.','urdu':'برائی سے بچنے کی طاقت اور بھلائی حاصل کرنے کی قوت صرف اللہ کی طرف سے ہے۔','reference':'Tirmidhī — A treasure from the treasures of Paradise'},
      {'arabic':'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيمِ','english':'Bismillah ir-rahman ir-raheem — In the name of Allah, the Most Gracious, the Most Merciful.','urdu':'اللہ کے نام سے شروع کرتا ہوں جو بے حد مہربان اور نہایت رحم کرنے والا ہے۔','reference':'Quran 1:1 — Recommended before every action'},
    ],
  },
  {
    'heading': 'Morning & Evening Adhkar',
    'headingUrdu': 'صبح و شام کے اذکار',
    'icon': Icons.wb_twilight_rounded,
    'duas': [
      {'arabic':'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلّٰهِ، وَالْحَمْدُ لِلّٰهِ','english':'We have reached the morning and the kingdom belongs to Allah. Praise be to Allah. (Say in the morning)','urdu':'ہم نے صبح کی اور بادشاہت اللہ کی ہے، اور تمام تعریفیں اللہ کے لیے ہیں۔ (صبح کے وقت پڑھیں)','reference':'Muslim 2723'},
      {'arabic':'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلّٰهِ، وَالْحَمْدُ لِلّٰهِ','english':'We have reached the evening and the kingdom belongs to Allah. Praise be to Allah. (Say in the evening)','urdu':'ہم نے شام کی اور بادشاہت اللہ کی ہے، اور تمام تعریفیں اللہ کے لیے ہیں۔ (شام کے وقت پڑھیں)','reference':'Muslim 2723'},
      {'arabic':'اَللّٰهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُوْرُ','english':'O Allah, by Your leave we have reached the morning, and by Your leave we have reached the evening. By You we live and by You we die, and to You is the resurrection.','urdu':'اے اللہ، تیری ہی توفیق سے ہم نے صبح کی اور شام کی، تیرے ہی ذریعے ہم جیتے اور مرتے ہیں، اور تیری ہی طرف اٹھنا ہے۔','reference':'Tirmidhi 3391 — Morning dua'},
      {'arabic':'اَللّٰهُمَّ أَنْتَ رَبِّيْ لَآ إِلٰهَ إِلَّا أَنْتَ، خَلَقْتَنِيْ وَأَنَا عَبْدُكَ، وَأَنَا عَلَىٰ عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوْذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوْءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوْءُ بِذَنْبِيْ فَاغْفِرْ لِيْ فَإِنَّهُ لَا يَغْفِرُ الذُّنُوْبَ إِلَّا أَنْتَ','english':'Sayyid al-Istighfar: O Allah, You are my Lord. There is no god but You. You created me and I am Your servant. I am upon Your covenant and promise as much as I can. I seek refuge in You from the evil of what I have done. I acknowledge before You Your blessings upon me, and I acknowledge my sins. Forgive me, for none forgives sins but You.','urdu':'سید الاستغفار: اے اللہ تو میرا رب ہے، تیرے سوا کوئی معبود نہیں، تو نے مجھے پیدا کیا اور میں تیرا بندہ ہوں، میں اپنی استطاعت کے مطابق تیرے عہد پر قائم ہوں، اپنے کیے کے شر سے تیری پناہ مانگتا ہوں، تیری نعمتوں کا اقرار کرتا ہوں، اپنے گناہ کا اقرار کرتا ہوں، پس مجھے بخش دے کیونکہ گناہ بخشنے والا صرف تو ہی ہے۔','reference':'Bukhari 6306 — The master supplication of forgiveness'},
      {'arabic':'أَعُوذُ بِكَلِمَاتِ اللهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ','english':'I seek refuge in the perfect words of Allah from the evil of what He has created. (3×)','urdu':'میں اللہ کے کامل کلمات کی پناہ مانگتا ہوں اس کی مخلوق کی برائی سے۔ (تین مرتبہ)','reference':'Muslim 2708 — For protection at evening'},
      {'arabic':'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ','english':'In the name of Allah with Whose name nothing on earth or in heaven can cause harm, and He is the All-Hearing, All-Knowing. (3×)','urdu':'اللہ کے نام سے جس کے نام کے ساتھ زمین یا آسمان میں کوئی چیز نقصان نہیں پہنچا سکتی، اور وہ سننے والا جاننے والا ہے۔ (تین مرتبہ)','reference':'Tirmidhi 3388 — 3× morning and evening protects from all harm'},
    ],
  },
  {
    'heading': 'Comprehensive Dhikr & Daily Prayers',
    'headingUrdu': 'جامع اذکار اور روزانہ دعائیں',
    'icon': Icons.auto_awesome_rounded,
    'duas': [
      {'arabic':'لَا إِلٰهَ إِلَّا اللّٰهُ','english':'La ilaha illallah — There is no god but Allah. The best of all dhikr.','urdu':'اللہ کے سوا کوئی معبود نہیں۔ یہ سب سے افضل ذکر ہے۔','reference':'Nasāʾī — Best dhikr'},
      {'arabic':'سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ ، سُبْحَانَ اللّٰهِ الْعَظِيْمِ','english':'SubhanAllahi wa bihamdihi, SubhanAllahil Azeem — Allah is free from imperfection and all praise is due to Him; Allah the Magnificent is free from imperfection. Two phrases beloved to Allah, light on the tongue, heavy in the scales.','urdu':'اللہ پاک ہے اور اسی کی تعریف ہے، اللہ عظیم پاک ہے۔ دو کلمے جو اللہ کو بہت محبوب ہیں، زبان پر ہلکے اور میزان میں بھاری ہیں۔','reference':'Bukhari 6682'},
      {'arabic':'سُبْحَانَ اللهِ ، وَالْحَمْدُ لِلهِ وَلَا إِلٰهَ إِلَّا اللهُ ، وَاللهُ أَكْبَرُ','english':'SubhanAllah, Alhamdulillah, La ilaha illallah, AllahuAkbar — Allah is free from imperfection. All praise be to Allah. There is no god worthy of worship but Allah. Allah is the Greatest.','urdu':'اللہ پاک ہے، تمام تعریفیں اللہ کے لیے ہیں، اللہ کے سوا کوئی معبود نہیں، اللہ سب سے بڑا ہے۔','reference':'Muslim 2137'},
      {'arabic':'لَا إِلٰهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيْكَ لَهُ ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيْرٌ','english':'La ilaha illallah wahdahu la sharika lah, lahul mulk wa lahul hamd, wa Huwa ala kulli shayin Qadir — There is no god but Allah. He is Alone and He has no partner. To Him belongs all sovereignty and praise. He is over all things All-Powerful. Best dua on the Day of Arafah.','urdu':'اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے، اس کا کوئی شریک نہیں۔ اسی کے لیے بادشاہت ہے اور اسی کی تعریف ہے، اور وہ ہر چیز پر قادر ہے۔','reference':'Tirmidhi 3585 — Best dua of Arafah'},
      {'arabic':'اَللّٰهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَىٰ إِبْرَاهِيْمَ وَعَلَىٰ آلِ إِبْرَاهِيْمَ إِنَّكَ حَمِيْدٌ مَّجِيْدٌ','english':'Allahumma salli ala Muhammadin wa ala ali Muhammadin kama sallayta ala Ibrahima wa ala ali Ibrahima innaka Hamidun Majeed — O Allah, honour and have mercy upon Muhammad and his family as You honoured Ibrahim and his family. Indeed, You are the Most Praiseworthy, the Most Glorious.','urdu':'اے اللہ، محمد ﷺ اور آل محمد پر رحمت نازل فرما جیسا کہ تو نے ابراہیم اور آل ابراہیم پر رحمت نازل فرمائی۔ بیشک تو قابل تعریف اور بزرگی والا ہے۔','reference':'Bukhari 3370'},
    ],
  },
  {
    'heading': 'Before & After Salah',
    'headingUrdu': 'نماز سے پہلے اور بعد',
    'icon': Icons.mosque_rounded,
    'duas': [
      {'arabic':'اَللّٰهُمَّ رَبَّ هٰذِهِ الدَّعْوَةِ التَّامَّةِ وَالصَّلَاةِ الْقَائِمَةِ، آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ وَابْعَثْهُ مَقَامًا مَّحْمُودًا الَّذِي وَعَدْتَهُ','english':'O Allah, Lord of this perfect call and this prayer that will be established, grant Muhammad the intercession and the high rank, and raise him to the praiseworthy station that You have promised him.','urdu':'اے اللہ، اس کامل پکار اور قائم ہونے والی نماز کے رب، محمد ﷺ کو وسیلہ اور فضیلت عطا فرما، اور انہیں اس مقام محمود پر پہنچا جس کا تو نے وعدہ فرمایا ہے۔','reference':'Bukhari 614 — After hearing the adhan'},
      {'arabic':'اَللّٰهُمَّ اغْفِرْ لِيْ ذَنْبِيْ وَوَسِّعْ لِيْ فِيْ دَارِيْ وَبَارِكْ لِيْ فِيْ رِزْقِيْ','english':'O Allah, forgive my sins, expand my dwelling for me, and bless me in my sustenance.','urdu':'اے اللہ، میرے گناہ بخش دے، میرے گھر میں کشادگی عطا فرما اور میرے رزق میں برکت دے۔','reference':'Nasai — After Fajr salah'},
      {'arabic':'أَسْتَغْفِرُ اللهَ (× ٣) اَللّٰهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ','english':'I seek forgiveness from Allah (×3). O Allah, You are Peace and from You comes peace. Blessed are You, O Possessor of Majesty and Honour.','urdu':'میں اللہ سے معافی مانگتا ہوں (تین مرتبہ)۔ اے اللہ، تو سلامتی ہے اور سلامتی تیری طرف سے ہے۔ اے جلال و اکرام والے، تو بابرکت ہے۔','reference':'Muslim 591 — After completing salah'},
      {'arabic':'لَا إِلٰهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ. اَللّٰهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ وَلَا مُعْطِيَ لِمَا مَنَعْتَ وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ','english':'There is no god but Allah, Alone with no partner. To Him belong sovereignty and praise and He is over all things Powerful. O Allah, none can withhold what You give, and none can give what You withhold, and the wealth of the wealthy does not benefit them against You.','urdu':'اللہ کے سوا کوئی معبود نہیں، وہ اکیلا ہے، اس کا کوئی شریک نہیں۔ اسی کی بادشاہت ہے اور اسی کی تعریف ہے اور وہ ہر چیز پر قادر ہے۔ اے اللہ، تو جو دے اسے کوئی روک نہیں سکتا، تو جو روکے اسے کوئی دے نہیں سکتا، اور کسی دولت مند کی دولت تیرے سامنے نفع نہیں دیتی۔','reference':'Bukhari 844 — After every obligatory salah'},
      {'arabic':'آيَةُ الْكُرْسِيّ','english':'Ayat al-Kursi — Whoever recites Ayat al-Kursi after every obligatory prayer, nothing will prevent him from entering Paradise except death. (Surah Al-Baqarah 2:255)','urdu':'آیۃ الکرسی — جو شخص ہر فرض نماز کے بعد آیۃ الکرسی پڑھے، اسے جنت میں جانے سے صرف موت روکتی ہے۔ (سورہ البقرہ ٢:٢٥٥)','reference':'Nasai — After every obligatory salah'},
    ],
  },
  {
    'heading': 'For Special Situations',
    'headingUrdu': 'خاص حالات کے لیے',
    'icon': Icons.star_rounded,
    'duas': [
      {'arabic':'يَا ذَا الْجَلَالِ وَالْإِكْرَامِ','english':'Ya Dhal Jalali wal Ikram — O Lord of Majesty and Honour. Recite abundantly.','urdu':'اے جلال اور اکرام والے رب۔ کثرت سے پڑھیں۔','reference':'Tirmidhi 3525'},
      {'arabic':'يَا حَيُّ يَا قَيُّوْمُ ، بِرَحْمَتِكَ أَسْتَغِيْثُ','english':'Ya Hayyu ya Qayyum, bi rahmatika astaghith — O The Ever Living, The Sustainer of all existence; I seek assistance through Your Mercy.','urdu':'اے زندہ اور قائم رکھنے والے، میں تیری رحمت کے سہارے مدد مانگتا ہوں۔','reference':'Tirmidhi 3524'},
      {'arabic':'لَآ إِلٰهَ إِلَّآ أَنْتَ سُبۡحٰنَكَ إِنِّيْ كُنْتُ مِنَ الظّٰلِمِيْنَ','english':'La ilaha illa Anta subhanaka inni kuntu mina dhzalimin — There is no god worthy of worship except You; You are free from imperfection. Indeed, I have been of the wrongdoers. The dua of Yunus (AS) from the belly of the whale — Allah answered it immediately.','urdu':'تیرے سوا کوئی معبود نہیں، تو پاک ہے، بیشک میں ظالموں میں سے ہوں۔ یونس علیہ السلام کی دعا جو مچھلی کے پیٹ میں پڑھی — اللہ نے فوری قبول فرمائی۔','reference':'Tirmidhi 3505'},
      {'arabic':'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ','english':'Hasbunallahu wa nimal wakeel — Allah alone is sufficient for us, and He is the best disposer of affairs. Ibrahim (AS) and Muhammad ﷺ both said this in times of hardship.','urdu':'اللہ ہمارے لیے کافی ہے اور وہ بہترین کارساز ہے۔ ابراہیم علیہ السلام اور نبی ﷺ نے مشکل وقت میں یہ پڑھا۔','reference':'Surah Aal-Imran 3:173'},
      {'arabic':'رَبِّ إِنِّي لِمَا أَنزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ','english':'Rabbi inni lima anzalta ilayya min khairin faqeer — My Lord, I am truly in need of whatever good You send down to me. Musa (AS) said this in desperate need — Allah sent him a wife and provision within hours.','urdu':'اے میرے رب! جو خیر بھی تو مجھ پر نازل کرے، میں اس کا محتاج ہوں۔ موسیٰ علیہ السلام نے شدید ضرورت میں پڑھا — اللہ نے چند گھنٹوں میں جواب دیا۔','reference':'Surah Al-Qasas 28:24'},
    ],
  },
  {
    'heading': 'For Difficult Situations',
    'headingUrdu': 'مشکل حالات کے لیے',
    'icon': Icons.shield_rounded,
    'duas': [
      {'arabic':'اَللّٰهُمَّ لَا سَهْلَ إِلَّا مَا جَعَلْتَهُ سَهْلًا ، وَأَنْتَ تَجْعَلُ الْحَزْنَ إِذَا شِئْتَ سَهْلًا','english':'Allahumma la sahla illa ma jaaltahu sahla, wa anta tajal al hazna idha shita sahla — O Allah, there is no ease except in that which You have made easy, and You make the difficulty easy when You wish.','urdu':'اے اللہ! کوئی بھی کام آسان نہیں مگر جسے تو نے آسان کر دیا، اور تو جب چاہے مشکل کو آسان کر دیتا ہے۔','reference':'Ibn Hibban 2427'},
      {'arabic':'اَللّٰهُمَّ إِنِّيْ أَعُوْذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ وَالْعَجْزِ وَالْكَسَلِ وَالْبُخْلِ وَالْجُبْنِ وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ','english':'Allahumma inni audhu bika minal hammi wal hazan wal ajzi wal kasali wal bukhli wal jubni wa dalaaid dayn wa ghalabatir rijal — O Allah, I seek refuge in You from worry and grief, from weakness and laziness, from stinginess and cowardice, from the burden of debt and the oppression of people.','urdu':'اے اللہ! میں غم و فکر، عاجزی اور سستی، بخل اور بزدلی، قرض کے بوجھ اور لوگوں کے غلبے سے تیری پناہ مانگتا ہوں۔','reference':'Bukhari 6369 — Comprehensive protection dua'},
      {'arabic':'إِنَّا لِلّٰهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ ، اَللّٰهُمَّ أْجُرْنِيْ فِيْ مُصِيبَتِيْ وَأَخْلِفْ لِيْ خَيْرًا مِّنْهَا','english':'Inna lillahi wa inna ilayhi rajioon. Allahumma ajurni fi musibati wa akhlif li khayran minha — Indeed, we belong to Allah and to Him we shall return. O Allah, reward me for my affliction and replace it with something better.','urdu':'بیشک ہم اللہ کے ہیں اور اسی کی طرف لوٹنا ہے۔ اے اللہ مجھے میری مصیبت کا اجر دے اور اس سے بہتر عطا فرما۔ ام سلمہ نے یہ پڑھا تو اللہ نے انہیں نبی ﷺ جیسا شوہر عطا فرمایا۔','reference':'Muslim 918'},
    ],
  },
  {
    'heading': 'For Firmness of Heart & Faith',
    'headingUrdu': 'دل اور ایمان کی مضبوطی کے لیے',
    'icon': Icons.favorite_rounded,
    'duas': [
      {'arabic':'يَا مُقَلِّبَ الْقُلُوْبِ ثَبِّتْ قَلْبِيْ عَلَىٰ دِيْنِكَ','english':'Ya Muqallibal qulubi thabbit qalbi ala dinik — O Changer of the hearts, make my heart firm upon Your religion. The Prophet ﷺ recited this frequently.','urdu':'اے دلوں کو پھیرنے والے! میرے دل کو اپنے دین پر ثابت رکھ۔ نبی ﷺ اسے کثرت سے پڑھتے تھے۔','reference':'Tirmidhi 3522'},
      {'arabic':'اَللّٰهُمَّ جَدِّدِ الْإِيْمَانَ فِيْ قَلْبِيْ','english':'Allahumma jaddidil imana fi qalbi — O Allah, keep faith rejuvenated in my heart.','urdu':'اے اللہ! میرے دل میں ایمان کی تجدید فرما۔','reference':'Hakim 1/4'},
      {'arabic':'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً إِنَّكَ أَنتَ الْوَهَّابُ','english':'Rabbana la tuzigh qulubana bada idh hadaytana wa hab lana mil ladunka rahmah, innaka antal Wahhab — Our Lord, do not let our hearts deviate after You have guided us, and grant us mercy from Yourself. Indeed, You are the Bestower.','urdu':'اے ہمارے رب، ہمارے دلوں کو ٹیڑھا نہ کر بعد اس کے کہ تو نے ہمیں ہدایت دی، اور ہمیں اپنے پاس سے رحمت عطا فرما۔ بیشک تو بہت عطا کرنے والا ہے۔','reference':'Surah Aal-Imran 3:8'},
    ],
  },
  {
    'heading': 'When Feeling Depressed or Anxious',
    'headingUrdu': 'اداسی اور پریشانی کے وقت',
    'icon': Icons.healing_rounded,
    'duas': [
      {'arabic':'حَسْبِيَ اللّٰهُ لَا إِلٰهَ إِلَّا هُوَ ، عَلَيْهِ تَوَكَّلْتُ ، وَهُوَ رَبُّ الْعَرْشِ الْعَظِيْمِ','english':'Hasbiyallahu la ilaha illa Huwa, alayhi tawakkaltu wa Huwa Rabbul Arshil Azeem — Allah is sufficient for me. There is no god except Him. I have placed my trust in Him. He is Lord of the Magnificent Throne. (7× morning and evening)','urdu':'اللہ میرے لیے کافی ہے، اس کے سوا کوئی معبود نہیں، اسی پر میں نے بھروسہ کیا، اور وہ عرش عظیم کا رب ہے۔ (صبح شام سات مرتبہ)','reference':'Ibn al-Sunni 71'},
      {'arabic':'رَبِّ أَنِّيْ مَسَّنِيَ الضُّرُّ وَأَنْتَ أَرْحَمُ الرّٰحِمِيْنَ','english':'Rabbi inni massaniyadh dhurru wa Anta arhamur rahimeen — My Lord, indeed adversity has touched me, and You are the Most Merciful of the merciful. The dua of Ayyub (AS) after years of illness — Allah responded.','urdu':'اے میرے رب! مجھے تکلیف پہنچی ہے اور تو سب سے بڑھ کر رحم کرنے والا ہے۔ ایوب علیہ السلام کی دعا برسوں کی بیماری کے بعد — اللہ نے قبول فرمائی۔','reference':'Surah Al-Anbiya 21:83'},
      {'arabic':'اَللّٰهُمَّ إِنِّيْ أَعُوْذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ','english':'Allahumma inni audhu bika minal hammi wal hazan — O Allah, I seek refuge in You from worry and grief.','urdu':'اے اللہ! میں غم اور فکر سے تیری پناہ مانگتا ہوں۔','reference':'Bukhari 6369'},
      {'arabic':'اَللّٰهُمَّ رَحْمَتَكَ أَرْجُو فَلَا تَكِلْنِيْ إِلَىٰ نَفْسِيْ طَرْفَةَ عَيْنٍ وَأَصْلِحْ لِيْ شَأْنِيْ كُلَّهُ','english':'Allahumma rahmataka arju fala takilni ila nafsi tarfata ayn wa aslih li sha ni kullahu — O Allah, I hope for Your mercy. Do not leave me to myself even for a blink of an eye. Rectify all my affairs for me.','urdu':'اے اللہ! میں تیری رحمت کا امید وار ہوں، مجھے ایک پل کے لیے بھی اپنے نفس کے حوالے نہ کر، اور میرے تمام معاملات درست فرما۔','reference':'Abu Dawud 5090'},
    ],
  },
  {
    'heading': 'Protection & Security',
    'headingUrdu': 'حفاظت اور سلامتی',
    'icon': Icons.security_rounded,
    'duas': [
      {'arabic':'اَللّٰهُمَّ إِنِّيْ أَعُوْذُ بِكَ مِنْ عَذَابِ جَهَنَّمَ ، وَمِنْ عَذَابِ الْقَبْرِ ، وَمِنْ فِتْنَةِ الْمَحْيَا وَالْمَمَاتِ ، وَمِنْ شَرِّ فِتْنَةِ الْمَسِيْحِ الدَّجَّالِ','english':'O Allah, I seek Your protection from the punishment of Hellfire, the punishment of the grave, the trials of life and death, and the evil of the tribulation of Dajjal.','urdu':'اے اللہ! میں جہنم کے عذاب، قبر کے عذاب، زندگی اور موت کی آزمائش، اور مسیح دجال کے فتنے کے شر سے تیری پناہ مانگتا ہوں۔','reference':'Muslim 588'},
      {'arabic':'اَللّٰهُمَّ إِنِّيْ أَعُوْذُ بِكَ مِنْ زَوَالِ نِعْمَتِكَ وَتَحَوُّلِ عَافِيَتِكَ وَفُجَاءَةِ نِقْمَتِكَ وَجَمِيعِ سَخَطِكَ','english':'O Allah, I seek refuge in You from the decline of Your blessings, the passing of safety, the sudden onset of Your punishment and from all that displeases You.','urdu':'اے اللہ! میں تیری نعمتوں کے زوال، عافیت کے بدل جانے، اچانک تیرے عذاب کے آ جانے اور تیرے ہر غضب سے تیری پناہ مانگتا ہوں۔','reference':'Muslim 2739'},
      {'arabic':'اَللّٰهُمَّ إِنِّيْ أَعُوْذُ بِكَ أَنْ أُشْرِكَ بِكَ وَأَنَا أَعْلَمُ ، وَأَسْتَغْفِرُكَ لِمَا لَا أَعْلَمُ','english':'O Allah, I seek Your protection from knowingly committing shirk and seek Your forgiveness for unknowingly committing it.','urdu':'اے اللہ! میں تیری پناہ مانگتا ہوں اس بات سے کہ میں جان بوجھ کر شرک کروں، اور جو میں نہیں جانتا اس کی معافی مانگتا ہوں۔','reference':'Ahmad 3731'},
      {'arabic':'أَعُوذُ بِاللهِ السَّمِيعِ الْعَلِيمِ مِنَ الشَّيْطَانِ الرَّجِيمِ','english':'Audhu billahis sameel aleem minash shaytanir rajeem — I seek refuge in Allah, the All-Hearing, the All-Knowing, from the accursed Shaytan.','urdu':'میں اللہ کی پناہ مانگتا ہوں جو سننے والا اور جاننے والا ہے، مردود شیطان سے۔','reference':'Tirmidhi 3542'},
    ],
  },
  {
    'heading': 'Duas from the Quran',
    'headingUrdu': 'قرآنی دعائیں',
    'icon': Icons.menu_book_rounded,
    'duas': [
      {'arabic':'رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ','english':'Rabbana dhalamna anfusana wa in lam taghfir lana wa tarhamna la nakunanna minal khasirin — Our Lord, we have wronged ourselves. If You do not forgive us and have mercy upon us, we will surely be amongst the losers. (Dua of Adam & Hawa)','urdu':'اے ہمارے رب، ہم نے اپنی جانوں پر ظلم کیا۔ اگر تو نے معاف نہ کیا اور رحم نہ کیا تو ہم نقصان اٹھانے والوں میں سے ہو جائیں گے۔ (آدم و حوا کی دعا)','reference':'Surah Al-Araf 7:23'},
      {'arabic':'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي','english':'Rabbish rahli sadri wa yassir li amri — My Lord, expand my chest for me, and make my task easy for me. (Dua of Musa AS before facing Pharaoh)','urdu':'اے میرے رب، میرے سینے کو کھول دے اور میرے کام کو آسان کر دے۔ (موسیٰ علیہ السلام کی دعا فرعون کا سامنا کرنے سے پہلے)','reference':'Surah Taha 20:25-26'},
      {'arabic':'رَبِّ زِدْنِي عِلْمًا','english':'Rabbi zidni ilma — My Lord, increase me in knowledge. A short but immensely powerful dua.','urdu':'اے میرے رب، میرے علم میں اضافہ فرما۔ مختصر مگر بہت طاقتور دعا۔','reference':'Surah Taha 20:114'},
      {'arabic':'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ','english':'Rabbana atina fid dunya hasanatan wa fil akhirati hasanatan wa qina adhabannar — Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire. The most comprehensive dua in the Quran.','urdu':'اے ہمارے رب، ہمیں دنیا میں بھلائی دے اور آخرت میں بھلائی دے اور ہمیں آگ کے عذاب سے بچا۔ قرآن کی سب سے جامع دعا۔','reference':'Surah Al-Baqarah 2:201'},
      {'arabic':'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا','english':'Rabbana hab lana min azwajina wa dhurriyyatina qurrata ayunin wajalna lil muttaqina imama — Our Lord, grant us from our spouses and offspring comfort to our eyes and make us an example for the righteous.','urdu':'اے ہمارے رب، ہمیں ہماری بیویوں اور اولاد سے آنکھوں کی ٹھنڈک عطا فرما، اور ہمیں پرہیزگاروں کا پیشوا بنا دے۔','reference':'Surah Al-Furqan 25:74'},
      {'arabic':'رَبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا','english':'Rabbi irhamhuma kama rabbayani saghira — My Lord, have mercy upon them both (my parents) as they raised me when I was young.','urdu':'اے میرے رب، اُن دونوں پر رحم فرما جیسا کہ اُنہوں نے مجھے بچپن میں پالا۔','reference':'Surah Al-Isra 17:24'},
      {'arabic':'رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا','english':'Rabbana la tuakhidhna in nasina aw akhta na — Our Lord, do not take us to account if we have forgotten or erred.','urdu':'اے ہمارے رب، ہمیں نہ پکڑ اگر ہم بھول گئے یا غلطی کر بیٹھے۔','reference':'Surah Al-Baqarah 2:286'},
      {'arabic':'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا','english':'Rabbana la tuzigh qulubana bada idh hadaytana — Our Lord, do not let our hearts deviate after You have guided us.','urdu':'اے ہمارے رب، ہمارے دلوں کو ٹیڑھا نہ کر بعد اس کے کہ تو نے ہمیں ہدایت دی۔','reference':'Surah Aal-Imran 3:8'},
    ],
  },
  {
    'heading': 'For Decisions (Istikhara)',
    'headingUrdu': 'فیصلہ کرتے وقت — استخارہ',
    'icon': Icons.help_outline_rounded,
    'duas': [
      {'arabic':'اَللّٰهُمَّ إِنِّيْ أَسْتَخِيْرُكَ بِعِلْمِكَ ، وَأَسْتَقْدِرُكَ بِقُدْرَتِكَ ، وَأَسْأَلُكَ مِنْ فَضْلِكَ الْعَظِيمِ ، فَإِنَّكَ تَقْدِرُ وَلَا أَقْدِرُ ، وَتَعْلَمُ وَلَا أَعْلَمُ ، وَأَنْتَ عَلَّامُ الْغُيُوبِ','english':'Allahumma inni astakhiruka bi ilmika wa astaqdiruka bi qudratika wa asaluka min fadlikal azim, fa innaka taqdiru wa la aqdiru wa talamu wa la alamu wa Anta allamul ghuyub — O Allah, I seek Your counsel through Your knowledge, seek Your assistance through Your power, and ask of Your great bounty. For You have power and I do not, You know and I do not, and You are the Knower of all unseen things.','urdu':'اے اللہ! میں تیرے علم سے تجھ سے خیر مانگتا ہوں، تیری قدرت سے تجھ سے قدرت مانگتا ہوں، اور تیرے بڑے فضل سے مانگتا ہوں۔ بیشک تو قادر ہے اور میں نہیں، تو جاننے والا ہے اور میں نہیں، اور تو غیب کا خوب جاننے والا ہے۔','reference':'Bukhari 1166 — Complete Istikhara dua, pray 2 rakah nafl first'},
    ],
  },
];

class GuidanceScreen extends StatefulWidget {
  @override
  _GuidanceScreenState createState() => _GuidanceScreenState();
}

class _GuidanceScreenState extends State<GuidanceScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  int? _expandedSection;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _sections;
    final q = _query.toLowerCase();
    return _sections.map((s) {
      final duas = (s['duas'] as List<Map<String, dynamic>>).where((d) =>
          (d['arabic'] as String).contains(_query) ||
          (d['english'] as String).toLowerCase().contains(q) ||
          (d['urdu'] as String).contains(_query) ||
          (d['reference'] as String).toLowerCase().contains(q)).toList();
      if (duas.isEmpty) return null;
      return {...s, 'duas': duas};
    }).whereType<Map<String, dynamic>>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu   = Provider.of<LanguageProvider>(context).isUrdu;
    final primary  = Theme.of(context).primaryColor;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final textPri  = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final textSec  = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;
    final cardColor = Theme.of(context).cardColor;
    final sections = _filtered;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isUrdu ? 'اذکار اور دعائیں' : 'Dhikr & Duas'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() { _query = v; _expandedSection = null; }),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: isUrdu ? 'دعا تلاش کریں...' : 'Search duas...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white70),
                        onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: sections.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.search_off_rounded, size: 52, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(isUrdu ? 'کوئی نتیجہ نہیں' : 'No results found',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade400)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: sections.length,
              itemBuilder: (ctx, si) {
                final section = sections[si];
                final heading = isUrdu
                    ? section['headingUrdu'] as String
                    : section['heading'] as String;
                final duas = section['duas'] as List<Map<String, dynamic>>;
                final icon  = section['icon'] as IconData;
                final isExpanded = _query.isNotEmpty || _expandedSection == si;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section header ─────────────────────────────────
                    GestureDetector(
                      onTap: () => setState(() =>
                          _expandedSection = isExpanded && _query.isEmpty ? null : si),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? primary.withOpacity(isDark ? 0.25 : 0.08)
                              : cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isExpanded
                                ? primary.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.12),
                          ),
                        ),
                        child: Row(children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: primary.withOpacity(isDark ? 0.3 : 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(heading,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                    color: isExpanded ? primary : textPri)),
                            Text('${duas.length} ${isUrdu ? "دعائیں" : "duas"}',
                                style: TextStyle(fontSize: 11, color: textSec)),
                          ])),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: isExpanded ? primary : Colors.grey,
                          ),
                        ]),
                      ),
                    ),

                    // ── Dua cards ──────────────────────────────────────
                    if (isExpanded) ...[
                      const SizedBox(height: 8),
                      ...duas.map((dua) => _buildDuaCard(
                          dua, isUrdu, primary, cardColor, textPri, textSec, isDark)),
                    ],

                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildDuaCard(Map<String, dynamic> dua, bool isUrdu, Color primary,
      Color cardColor, Color textPri, Color textSec, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(0.08)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Arabic
          Text(
            dua['arabic'] as String,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 22,
              height: 1.7,
              color: primary,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 10),
          // Divider
          Container(height: 1, color: primary.withOpacity(0.08)),
          const SizedBox(height: 10),
          // Translation
          Text(
            isUrdu ? dua['urdu'] as String : dua['english'] as String,
            style: TextStyle(fontSize: 14, color: textPri, height: 1.5),
          ),
          const SizedBox(height: 8),
          // Reference + copy button row
          Row(children: [
            Icon(Icons.bookmark_outline_rounded, size: 13, color: textSec),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                dua['reference'] as String,
                style: TextStyle(fontSize: 11, color: textSec, fontStyle: FontStyle.italic),
              ),
            ),
            // Copy arabic button
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: dua['arabic'] as String));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isUrdu ? 'کاپی ہوگئی' : 'Arabic text copied'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: primary,
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.copy_rounded, size: 12, color: primary),
                  const SizedBox(width: 4),
                  Text(isUrdu ? 'کاپی' : 'Copy',
                      style: TextStyle(fontSize: 11, color: primary, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}