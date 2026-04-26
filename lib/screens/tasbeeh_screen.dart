import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'guidance_screen.dart';

const List<Map<String, String>> _allahNames = [
  {'arabic': 'الرَّحْمَنُ', 'english': 'The Most Gracious', 'urdu': 'بہت مہربان'},
  {'arabic': 'الرَّحِيمُ', 'english': 'The Most Merciful', 'urdu': 'نہایت رحم کرنے والا'},
  {'arabic': 'الْمَلِكُ', 'english': 'The King', 'urdu': 'بادشاہ'},
  {'arabic': 'الْقُدُّوسُ', 'english': 'The Most Holy', 'urdu': 'پاک'},
  {'arabic': 'السَّلَامُ', 'english': 'The Source of Peace', 'urdu': 'سلامتی دینے والا'},
  {'arabic': 'الْمُؤْمِنُ', 'english': 'The Granter of Security', 'urdu': 'امن دینے والا'},
  {'arabic': 'الْمُهَيْمِنُ', 'english': 'The Guardian', 'urdu': 'نگہبان'},
  {'arabic': 'الْعَزِيزُ', 'english': 'The Almighty', 'urdu': 'سب پر غالب'},
  {'arabic': 'الْجَبَّارُ', 'english': 'The Compeller', 'urdu': 'زبردست'},
  {'arabic': 'الْمُتَكَبِّرُ', 'english': 'The Supreme', 'urdu': 'بڑائی والا'},
  {'arabic': 'الْخَالِقُ', 'english': 'The Creator', 'urdu': 'پیدا کرنے والا'},
  {'arabic': 'الْبَارِئُ', 'english': 'The Originator', 'urdu': 'بنانے والا'},
  {'arabic': 'الْمُصَوِّرُ', 'english': 'The Fashioner', 'urdu': 'صورت دینے والا'},
  {'arabic': 'الْغَفَّارُ', 'english': 'The Forgiving', 'urdu': 'بہت بخشنے والا'},
  {'arabic': 'الْقَهَّارُ', 'english': 'The Subduer', 'urdu': 'قہر کرنے والا'},
  {'arabic': 'الْوَهَّابُ', 'english': 'The Bestower', 'urdu': 'عطا کرنے والا'},
  {'arabic': 'الرَّزَّاقُ', 'english': 'The Provider', 'urdu': 'رزق دینے والا'},
  {'arabic': 'الْفَتَّاحُ', 'english': 'The Opener', 'urdu': 'کھولنے والا'},
  {'arabic': 'الْعَلِيمُ', 'english': 'The All-Knowing', 'urdu': 'سب جاننے والا'},
  {'arabic': 'الْقَابِضُ', 'english': 'The Restrainer', 'urdu': 'روکنے والا'},
  {'arabic': 'الْبَاسِطُ', 'english': 'The Extender', 'urdu': 'پھیلانے والا'},
  {'arabic': 'الْخَافِضُ', 'english': 'The Reducer', 'urdu': 'نیچے کرنے والا'},
  {'arabic': 'الرَّافِعُ', 'english': 'The Exalter', 'urdu': 'اونچا کرنے والا'},
  {'arabic': 'الْمُعِزُّ', 'english': 'The Honourer', 'urdu': 'عزت دینے والا'},
  {'arabic': 'الْمُذِلُّ', 'english': 'The Humiliator', 'urdu': 'ذلیل کرنے والا'},
  {'arabic': 'السَّمِيعُ', 'english': 'The All-Hearing', 'urdu': 'سننے والا'},
  {'arabic': 'الْبَصِيرُ', 'english': 'The All-Seeing', 'urdu': 'دیکھنے والا'},
  {'arabic': 'الْحَكَمُ', 'english': 'The Judge', 'urdu': 'فیصلہ کرنے والا'},
  {'arabic': 'الْعَدْلُ', 'english': 'The Just', 'urdu': 'انصاف کرنے والا'},
  {'arabic': 'اللَّطِيفُ', 'english': 'The Subtle One', 'urdu': 'باریک بین'},
  {'arabic': 'الْخَبِيرُ', 'english': 'The All-Aware', 'urdu': 'باخبر'},
  {'arabic': 'الْحَلِيمُ', 'english': 'The Forbearing', 'urdu': 'بردبار'},
  {'arabic': 'الْعَظِيمُ', 'english': 'The Magnificent', 'urdu': 'عظمت والا'},
  {'arabic': 'الْغَفُورُ', 'english': 'The Forgiving', 'urdu': 'معاف کرنے والا'},
  {'arabic': 'الشَّكُورُ', 'english': 'The Appreciative', 'urdu': 'قدردان'},
  {'arabic': 'الْعَلِيُّ', 'english': 'The Most High', 'urdu': 'سب سے بلند'},
  {'arabic': 'الْكَبِيرُ', 'english': 'The Most Great', 'urdu': 'بہت بڑا'},
  {'arabic': 'الْحَفِيظُ', 'english': 'The Preserver', 'urdu': 'حفاظت کرنے والا'},
  {'arabic': 'الْمُقِيتُ', 'english': 'The Sustainer', 'urdu': 'قوت دینے والا'},
  {'arabic': 'الْحَسِيبُ', 'english': 'The Reckoner', 'urdu': 'حساب لینے والا'},
  {'arabic': 'الْجَلِيلُ', 'english': 'The Majestic', 'urdu': 'جلال والا'},
  {'arabic': 'الْكَرِيمُ', 'english': 'The Most Generous', 'urdu': 'بہت کریم'},
  {'arabic': 'الرَّقِيبُ', 'english': 'The Watchful', 'urdu': 'نگرانی کرنے والا'},
  {'arabic': 'الْمُجِيبُ', 'english': 'The Responsive', 'urdu': 'قبول کرنے والا'},
  {'arabic': 'الْوَاسِعُ', 'english': 'The All-Encompassing', 'urdu': 'وسعت والا'},
  {'arabic': 'الْحَكِيمُ', 'english': 'The Wise', 'urdu': 'حکمت والا'},
  {'arabic': 'الْوَدُودُ', 'english': 'The Loving', 'urdu': 'محبت کرنے والا'},
  {'arabic': 'الْمَجِيدُ', 'english': 'The Glorious', 'urdu': 'بزرگی والا'},
  {'arabic': 'الْبَاعِثُ', 'english': 'The Resurrector', 'urdu': 'اٹھانے والا'},
  {'arabic': 'الشَّهِيدُ', 'english': 'The Witness', 'urdu': 'گواہ'},
  {'arabic': 'الْحَقُّ', 'english': 'The Truth', 'urdu': 'سچا'},
  {'arabic': 'الْوَكِيلُ', 'english': 'The Trustee', 'urdu': 'وکیل'},
  {'arabic': 'الْقَوِيُّ', 'english': 'The Strong', 'urdu': 'طاقتور'},
  {'arabic': 'الْمَتِينُ', 'english': 'The Firm', 'urdu': 'مضبوط'},
  {'arabic': 'الْوَلِيُّ', 'english': 'The Protecting Friend', 'urdu': 'دوست'},
  {'arabic': 'الْحَمِيدُ', 'english': 'The Praiseworthy', 'urdu': 'تعریف کے لائق'},
  {'arabic': 'الْمُحْصِي', 'english': 'The Counter', 'urdu': 'گننے والا'},
  {'arabic': 'الْمُبْدِئُ', 'english': 'The Originator', 'urdu': 'شروع کرنے والا'},
  {'arabic': 'الْمُعِيدُ', 'english': 'The Restorer', 'urdu': 'واپس کرنے والا'},
  {'arabic': 'الْمُحْيِي', 'english': 'The Giver of Life', 'urdu': 'زندگی دینے والا'},
  {'arabic': 'الْمُمِيتُ', 'english': 'The Taker of Life', 'urdu': 'موت دینے والا'},
  {'arabic': 'الْحَيُّ', 'english': 'The Ever-Living', 'urdu': 'ہمیشہ زندہ'},
  {'arabic': 'الْقَيُّومُ', 'english': 'The Sustainer', 'urdu': 'قائم رکھنے والا'},
  {'arabic': 'الْوَاجِدُ', 'english': 'The Finder', 'urdu': 'پانے والا'},
  {'arabic': 'الْمَاجِدُ', 'english': 'The Noble', 'urdu': 'شریف'},
  {'arabic': 'الْوَاحِدُ', 'english': 'The One', 'urdu': 'اکیلا'},
  {'arabic': 'الْأَحَدُ', 'english': 'The Unique', 'urdu': 'یکتا'},
  {'arabic': 'الصَّمَدُ', 'english': 'The Eternal', 'urdu': 'بے نیاز'},
  {'arabic': 'الْقَادِرُ', 'english': 'The Able', 'urdu': 'قدرت والا'},
  {'arabic': 'الْمُقْتَدِرُ', 'english': 'The Powerful', 'urdu': 'بہت قادر'},
  {'arabic': 'الْمُقَدِّمُ', 'english': 'The Expediter', 'urdu': 'آگے کرنے والا'},
  {'arabic': 'الْمُؤَخِّرُ', 'english': 'The Delayer', 'urdu': 'پیچھے کرنے والا'},
  {'arabic': 'الْأَوَّلُ', 'english': 'The First', 'urdu': 'پہلا'},
  {'arabic': 'الْآخِرُ', 'english': 'The Last', 'urdu': 'آخری'},
  {'arabic': 'الظَّاهِرُ', 'english': 'The Manifest', 'urdu': 'ظاہر'},
  {'arabic': 'الْبَاطِنُ', 'english': 'The Hidden', 'urdu': 'پوشیدہ'},
  {'arabic': 'الْوَالِي', 'english': 'The Governor', 'urdu': 'حاکم'},
  {'arabic': 'الْمُتَعَالِي', 'english': 'The Most Exalted', 'urdu': 'سب سے اعلیٰ'},
  {'arabic': 'الْبَرُّ', 'english': 'The Source of Goodness', 'urdu': 'نیکی کا سرچشمہ'},
  {'arabic': 'التَّوَّابُ', 'english': 'The Acceptor of Repentance', 'urdu': 'توبہ قبول کرنے والا'},
  {'arabic': 'الْمُنْتَقِمُ', 'english': 'The Avenger', 'urdu': 'بدلہ لینے والا'},
  {'arabic': 'الْعَفُوُّ', 'english': 'The Pardoner', 'urdu': 'معاف کرنے والا'},
  {'arabic': 'الرَّؤُوفُ', 'english': 'The Most Kind', 'urdu': 'شفقت کرنے والا'},
  {'arabic': 'مَالِكُ الْمُلْكِ', 'english': 'Owner of Sovereignty', 'urdu': 'بادشاہی کا مالک'},
  {'arabic': 'ذُو الْجَلَالِ وَالْإِكْرَامِ', 'english': 'Lord of Majesty', 'urdu': 'جلال و اکرام والا'},
  {'arabic': 'الْمُقْسِطُ', 'english': 'The Equitable', 'urdu': 'انصاف دینے والا'},
  {'arabic': 'الْجَامِعُ', 'english': 'The Gatherer', 'urdu': 'اکٹھا کرنے والا'},
  {'arabic': 'الْغَنِيُّ', 'english': 'The Self-Sufficient', 'urdu': 'بے پرواہ'},
  {'arabic': 'الْمُغْنِي', 'english': 'The Enricher', 'urdu': 'مالدار بنانے والا'},
  {'arabic': 'الْمَانِعُ', 'english': 'The Withholder', 'urdu': 'روکنے والا'},
  {'arabic': 'الضَّارُّ', 'english': 'The Distresser', 'urdu': 'نقصان دینے والا'},
  {'arabic': 'النَّافِعُ', 'english': 'The Benefiter', 'urdu': 'فائدہ دینے والا'},
  {'arabic': 'النُّورُ', 'english': 'The Light', 'urdu': 'روشنی'},
  {'arabic': 'الْهَادِي', 'english': 'The Guide', 'urdu': 'ہدایت دینے والا'},
  {'arabic': 'الْبَدِيعُ', 'english': 'The Incomparable', 'urdu': 'بے مثال'},
  {'arabic': 'الْبَاقِي', 'english': 'The Everlasting', 'urdu': 'ہمیشہ رہنے والا'},
  {'arabic': 'الْوَارِثُ', 'english': 'The Inheritor', 'urdu': 'وارث'},
  {'arabic': 'الرَّشِيدُ', 'english': 'The Guide to Right Path', 'urdu': 'سیدھی راہ دکھانے والا'},
  {'arabic': 'الصَّبُورُ', 'english': 'The Patient', 'urdu': 'صبر کرنے والا'},
];

class TasbeehScreen extends StatefulWidget {
  @override
  _TasbeehScreenState createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  int _counter = 0;
  int _target = 33;
  bool _targetReachedShown = false;

  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnim;
  late Animation<double> _progressAnim;
  double _animatedProgress = 0;

  final List<Map<String, dynamic>> _presets = [
    {'label': 'SubhanAllah', 'urdu': 'سبحان اللہ', 'count': 33},
    {'label': 'Alhamdulillah', 'urdu': 'الحمد للہ', 'count': 33},
    {'label': 'AllahuAkbar', 'urdu': 'اللہ اکبر', 'count': 34},
    {'label': 'Astaghfirullah', 'urdu': 'استغفر اللہ', 'count': 100},
  ];
  int _selectedPreset = 0;

  String _namesSearch = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() => _animatedProgress = _progressAnim.value);
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _increment() {
    if (_counter >= _target) return;
    HapticFeedback.lightImpact();
    _pulseController.forward().then((_) => _pulseController.reverse());
    setState(() => _counter++);
    final newProgress = _counter / _target;
    _progressAnim = Tween<double>(begin: _animatedProgress, end: newProgress)
        .animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOut));
    _progressController.forward(from: 0);
    if (_counter == _target && !_targetReachedShown) {
      _targetReachedShown = true;
      HapticFeedback.mediumImpact();
      _showTargetCompletion();
    }
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() { _counter = 0; _targetReachedShown = false; });
    _progressAnim = Tween<double>(begin: _animatedProgress, end: 0)
        .animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOut));
    _progressController.forward(from: 0);
  }

  void _selectPreset(int index) {
    setState(() {
      _selectedPreset = index;
      _target = _presets[index]['count'] as int;
      _counter = 0;
      _targetReachedShown = false;
    });
    _progressAnim = Tween<double>(begin: _animatedProgress, end: 0)
        .animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOut));
    _progressController.forward(from: 0);
  }

  void _setCustomTarget() async {
    final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
    final controller = TextEditingController(text: _target.toString());
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isUrdu ? 'حد مقرر کریں' : 'Set Custom Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isUrdu ? 'مطلوبہ تعداد' : 'Enter count',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isUrdu ? 'منسوخ' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              final newTarget = int.tryParse(controller.text);
              if (newTarget != null && newTarget > 0) {
                setState(() {
                  _target = newTarget;
                  if (_counter > _target) _counter = _target;
                  _targetReachedShown = (_counter == _target);
                  _selectedPreset = -1;
                });
                final newProgress = _counter / _target;
                _progressAnim = Tween<double>(begin: _animatedProgress, end: newProgress)
                    .animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOut));
                _progressController.forward(from: 0);
              }
              Navigator.pop(context);
            },
            child: Text(isUrdu ? 'محفوظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showTargetCompletion() {
    final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white),
        const SizedBox(width: 8),
        Text(isUrdu ? 'مبارک ہو! آپ نے حد مکمل کر لی!' : 'Mashallah! Target complete!'),
      ]),
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isUrdu ? 'تسبیح' : 'Tasbeeh'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Text('🤲', style: TextStyle(fontSize: 22)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GuidanceScreen())),
            tooltip: isUrdu ? 'اذکار اور دعائیں' : 'Dhikr & Duas',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 15),
          tabs: [
            Tab(icon: const Icon(Icons.radio_button_checked, size: 18), text: isUrdu ? 'تسبیح' : 'Counter'),
            Tab(icon: const Icon(Icons.auto_awesome, size: 18), text: isUrdu ? '۹۹ نام' : '99 Names'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCounterTab(isUrdu, primaryColor, isDark),
          _buildNamesTab(isUrdu, primaryColor, isDark),
        ],
      ),
    );
  }

  Widget _buildCounterTab(bool isUrdu, Color primaryColor, bool isDark) {
    final cardColor = Theme.of(context).cardColor;
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _presets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final selected = _selectedPreset == i;
              return ChoiceChip(
                label: Text(
                  isUrdu ? _presets[i]['urdu'] as String : _presets[i]['label'] as String,
                  style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: selected ? Colors.white : textSecondary),
                ),
                selected: selected,
                onSelected: (_) => _selectPreset(i),
                selectedColor: primaryColor,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                side: BorderSide(color: selected ? primaryColor : Colors.grey.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: _increment,
          child: ScaleTransition(
            scale: _pulseAnim,
            child: SizedBox(
              width: 240, height: 240,
              child: CustomPaint(
                painter: _RingPainter(progress: _animatedProgress, primaryColor: primaryColor, trackColor: isDark ? Colors.white12 : Colors.grey.shade200),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$_counter', style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: primaryColor, height: 1)),
                  const SizedBox(height: 4),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(isUrdu ? 'حد: ' : 'of ', style: TextStyle(fontSize: 14, color: textSecondary)),
                    GestureDetector(
                      onTap: _setCustomTarget,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: primaryColor.withOpacity(0.4))),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('$_target', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor)),
                          const SizedBox(width: 3),
                          Icon(Icons.edit, size: 11, color: primaryColor),
                        ]),
                      ),
                    ),
                  ]),
                ])),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(isUrdu ? 'گنتی کے لیے دائرے کو ٹیپ کریں' : 'Tap the circle to count', style: TextStyle(fontSize: 13, color: textSecondary)),
        const SizedBox(height: 28),
        Row(children: [
          _statCard(isUrdu ? 'باقی' : 'Remaining', '${_target - _counter}', primaryColor.withOpacity(0.08), primaryColor),
          const SizedBox(width: 12),
          _statCard(isUrdu ? 'تکمیل' : 'Complete', '${(_counter / _target * 100).toStringAsFixed(0)}%', _counter == _target ? Colors.green.withOpacity(0.12) : primaryColor.withOpacity(0.08), _counter == _target ? Colors.green : primaryColor),
        ]),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(isUrdu ? 'ری سیٹ' : 'Reset'),
            style: OutlinedButton.styleFrom(foregroundColor: textSecondary, side: BorderSide(color: Colors.grey.withOpacity(0.4)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: ElevatedButton.icon(
            onPressed: _increment,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(isUrdu ? 'ایک بڑھائیں' : 'Add Count'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
          )),
        ]),
      ]),
    );
  }

  Widget _buildNamesTab(bool isUrdu, Color primaryColor, bool isDark) {
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;
    final cardColor = Theme.of(context).cardColor;
    final filtered = _namesSearch.isEmpty
        ? _allahNames
        : _allahNames.where((n) =>
            n['arabic']!.contains(_namesSearch) ||
            n['english']!.toLowerCase().contains(_namesSearch.toLowerCase()) ||
            n['urdu']!.contains(_namesSearch)).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _namesSearch = v),
          decoration: InputDecoration(
            hintText: isUrdu ? 'نام تلاش کریں...' : 'Search names...',
            prefixIcon: Icon(Icons.search, color: primaryColor),
            suffixIcon: _namesSearch.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _namesSearch = ''); })
                : null,
            filled: true,
            fillColor: primaryColor.withOpacity(0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(isUrdu ? '${filtered.length} نام' : '${filtered.length} names', style: TextStyle(fontSize: 12, color: textSecondary)),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: filtered.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.5),
          itemBuilder: (context, index) {
            final name = filtered[index];
            final number = _allahNames.indexOf(name) + 1;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: primaryColor.withOpacity(0.15))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text('$number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
                ),
                const SizedBox(height: 6),
                Expanded(child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(name['arabic']!, textAlign: TextAlign.right, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryColor, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                )),
                const SizedBox(height: 4),
                Text(isUrdu ? name['urdu']! : name['english']!, style: TextStyle(fontSize: 11, color: textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  Widget _statCard(String label, String value, Color bgColor, Color valueColor) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, color: valueColor.withOpacity(0.7), fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: valueColor)),
      ]),
    ));
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color trackColor;
  _RingPainter({required this.progress, required this.primaryColor, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 14.0;
    canvas.drawCircle(center, radius, Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round);
    if (progress > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false, Paint()..color = primaryColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress || old.primaryColor != primaryColor;
}