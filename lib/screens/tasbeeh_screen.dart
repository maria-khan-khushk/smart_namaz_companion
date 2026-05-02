import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'guidance_screen.dart';

// ── 99 Names data ────────────────────────────────────────────────────────────
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

// ── Dhikr presets (no chips — selected via bottom sheet) ─────────────────────
const List<Map<String, dynamic>> _dhikrPresets = [
  {'arabic': 'سُبْحَانَ اللّٰہ',  'label': 'SubhanAllah',    'urdu': 'سبحان اللہ',    'count': 33},
  {'arabic': 'اَلْحَمْدُ لِلّٰہ', 'label': 'Alhamdulillah',  'urdu': 'الحمد للہ',     'count': 33},
  {'arabic': 'اَللّٰہُ اَکْبَر',  'label': 'AllahuAkbar',    'urdu': 'اللہ اکبر',     'count': 34},
  {'arabic': 'اَسْتَغْفِرُاللّٰہ','label': 'Astaghfirullah', 'urdu': 'استغفر اللہ',   'count': 100},
  {'arabic': 'لَا إِلٰهَ إِلَّا اللّٰہ', 'label': 'La ilaha illallah', 'urdu': 'لا الہ الا اللہ', 'count': 100},
];

class TasbeehScreen extends StatefulWidget {
  @override
  _TasbeehScreenState createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Counter state
  int _counter   = 0;
  int _target    = 33;
  int _selectedPreset = 0;
  bool _targetReachedShown = false;

  // Animations
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double>   _pulseAnim;
  late Animation<double>   _progressAnim;
  double _animatedProgress = 0;

  // 99 Names search
  String _namesSearch = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _pulseAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _progressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeOut))
      ..addListener(() => setState(() => _animatedProgress = _progressAnim.value));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Counter actions ────────────────────────────────────────────────────────

  void _increment() {
    if (_counter >= _target) return;
    HapticFeedback.lightImpact();
    _pulseController.forward().then((_) => _pulseController.reverse());
    setState(() => _counter++);
    _animateProgress(_counter / _target);
    if (_counter == _target && !_targetReachedShown) {
      _targetReachedShown = true;
      HapticFeedback.mediumImpact();
      _showCompletion();
    }
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() { _counter = 0; _targetReachedShown = false; });
    _animateProgress(0);
  }

  void _animateProgress(double to) {
    _progressAnim = Tween<double>(begin: _animatedProgress, end: to)
        .animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOut));
    _progressController.forward(from: 0);
  }

  void _applyPreset(int index) {
    setState(() {
      _selectedPreset = index;
      _target  = _dhikrPresets[index]['count'] as int;
      _counter = 0;
      _targetReachedShown = false;
    });
    _animateProgress(0);
  }

  // ── Dhikr picker — bottom sheet ────────────────────────────────────────────

  Future<void> _openDhikrPicker(bool isUrdu, Color primary) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _DhikrPickerSheet(
        isUrdu: isUrdu,
        primary: primary,
        cardColor: Theme.of(context).cardColor,
        selected: _selectedPreset,
        presets: _dhikrPresets,
      ),
    );
    if (result != null) _applyPreset(result);
  }

  // ── Custom target ──────────────────────────────────────────────────────────

  Future<void> _setCustomTarget(bool isUrdu) async {
    final ctrl = TextEditingController(text: _target.toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isUrdu ? 'حد مقرر کریں' : 'Set Target'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isUrdu ? 'مطلوبہ تعداد' : 'Enter count',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isUrdu ? 'منسوخ' : 'Cancel',
                style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color)),
          ),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v != null && v > 0) {
                setState(() {
                  _target = v;
                  if (_counter > _target) _counter = _target;
                  _targetReachedShown = _counter == _target;
                  _selectedPreset = -1;
                });
                _animateProgress(_counter / _target);
              }
              Navigator.pop(ctx);
            },
            child: Text(isUrdu ? 'محفوظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showCompletion() {
    final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text(isUrdu ? 'ماشاءاللہ! تسبیح مکمل ہوگئی' : 'Mashallah! Tasbeeh complete',
            style: const TextStyle(fontWeight: FontWeight.w500)),
      ]),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isUrdu   = Provider.of<LanguageProvider>(context).isUrdu;
    final primary  = Theme.of(context).primaryColor;
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isUrdu ? 'تسبیح' : 'Tasbeeh'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Text('🤲', style: TextStyle(fontSize: 20)),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => GuidanceScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: [
            Tab(icon: const Icon(Icons.radio_button_checked_rounded, size: 17),
                text: isUrdu ? 'تسبیح' : 'Counter'),
            Tab(icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                text: isUrdu ? '۹۹ نام' : '99 Names'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCounterTab(isUrdu, primary, isDark),
          _buildNamesTab(isUrdu, primary, isDark),
        ],
      ),
    );
  }

  // ── Tab 1: Counter ─────────────────────────────────────────────────────────

  Widget _buildCounterTab(bool isUrdu, Color primary, bool isDark) {
    final cardColor  = Theme.of(context).cardColor;
    final textSec    = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;
    final textPri    = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final preset     = _selectedPreset >= 0 ? _dhikrPresets[_selectedPreset] : null;
    final progress   = _counter / _target;
    final isDone     = _counter == _target;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(children: [

        // ── Selected dhikr banner ─────────────────────────────────────
        GestureDetector(
          onTap: () => _openDhikrPicker(isUrdu, primary),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: primary.withOpacity(isDark ? 0.2 : 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  preset != null
                      ? (isUrdu ? preset['urdu'] as String : preset['label'] as String)
                      : (isUrdu ? 'کسٹم' : 'Custom'),
                  style: TextStyle(fontSize: 13, color: textSec),
                ),
                const SizedBox(height: 2),
                Text(
                  preset != null ? preset['arabic'] as String : '—',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: primary, fontFamily: 'serif'),
                ),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(isUrdu ? 'تبدیل کریں' : 'Change',
                      style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: primary),
                ]),
              ),
            ]),
          ),
        ),

        const SizedBox(height: 32),

        // ── Ring counter — tap to count ───────────────────────────────
        GestureDetector(
          onTap: _increment,
          child: ScaleTransition(
            scale: _pulseAnim,
            child: SizedBox(
              width: 220, height: 220,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: _animatedProgress,
                  primaryColor: isDone ? Colors.green : primary,
                  trackColor: isDark ? Colors.white10 : Colors.grey.shade100,
                ),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    '$_counter',
                    style: TextStyle(
                      fontSize: 68,
                      fontWeight: FontWeight.bold,
                      color: isDone ? Colors.green : primary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _setCustomTarget(isUrdu),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primary.withOpacity(0.25)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                          '/ $_target',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primary),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit_rounded, size: 10, color: primary),
                      ]),
                    ),
                  ),
                ])),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),
        Text(
          isUrdu ? 'گنتی کے لیے دائرے کو ٹیپ کریں' : 'Tap the ring to count',
          style: TextStyle(fontSize: 12, color: textSec),
        ),

        const SizedBox(height: 28),

        // ── Progress + stat row ────────────────────────────────────────
        Row(children: [
          _statTile(
            isUrdu ? 'باقی' : 'Remaining',
            '${_target - _counter}',
            primary, isDark, isDone: false,
          ),
          const SizedBox(width: 10),
          _statTile(
            isUrdu ? 'مکمل' : 'Complete',
            '${(progress * 100).toStringAsFixed(0)}%',
            isDone ? Colors.green : primary, isDark,
            isDone: isDone,
          ),
          const SizedBox(width: 10),
          _statTile(
            isUrdu ? 'ہدف' : 'Target',
            '$_target',
            primary, isDark, isDone: false,
          ),
        ]),

        const SizedBox(height: 24),

        // ── Action buttons ─────────────────────────────────────────────
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(isUrdu ? 'ری سیٹ' : 'Reset'),
              style: OutlinedButton.styleFrom(
                foregroundColor: textSec,
                side: BorderSide(color: Colors.grey.withOpacity(0.35)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _increment,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(isUrdu ? 'ایک بڑھائیں' : 'Add Count'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDone ? Colors.green : primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _statTile(String label, String value, Color color, bool isDark,
      {required bool isDone}) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDone
            ? Colors.green.withOpacity(isDark ? 0.15 : 0.08)
            : color.withOpacity(isDark ? 0.15 : 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
            textAlign: TextAlign.center),
      ]),
    ));
  }

  // ── Tab 2: 99 Names ────────────────────────────────────────────────────────

  Widget _buildNamesTab(bool isUrdu, Color primary, bool isDark) {
    final textSec  = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;
    final cardColor = Theme.of(context).cardColor;
    final filtered = _namesSearch.isEmpty
        ? _allahNames
        : _allahNames.where((n) =>
            n['arabic']!.contains(_namesSearch) ||
            n['english']!.toLowerCase().contains(_namesSearch.toLowerCase()) ||
            n['urdu']!.contains(_namesSearch)).toList();

    return Column(children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _namesSearch = v),
          decoration: InputDecoration(
            hintText: isUrdu ? 'نام تلاش کریں...' : 'Search names...',
            prefixIcon: Icon(Icons.search_rounded, color: primary),
            suffixIcon: _namesSearch.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _namesSearch = '');
                    })
                : null,
            filled: true,
            fillColor: primary.withOpacity(0.06),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          isUrdu ? '${filtered.length} نام' : '${filtered.length} names',
          style: TextStyle(fontSize: 11, color: textSec),
        ),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: filtered.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 10,
              crossAxisSpacing: 10, childAspectRatio: 1.5),
          itemBuilder: (ctx, i) {
            final name   = filtered[i];
            final number = _allahNames.indexOf(name) + 1;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary.withOpacity(0.13)),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
                    blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('$number',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary)),
                ),
                const SizedBox(height: 6),
                Expanded(child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(name['arabic']!,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                          color: primary, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                )),
                const SizedBox(height: 3),
                Text(isUrdu ? name['urdu']! : name['english']!,
                    style: TextStyle(fontSize: 10, color: textSec),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dhikr picker — bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DhikrPickerSheet extends StatefulWidget {
  final bool isUrdu;
  final Color primary;
  final Color cardColor;
  final int selected;
  final List<Map<String, dynamic>> presets;

  const _DhikrPickerSheet({
    required this.isUrdu, required this.primary, required this.cardColor,
    required this.selected, required this.presets,
  });

  @override
  State<_DhikrPickerSheet> createState() => _DhikrPickerSheetState();
}

class _DhikrPickerSheetState extends State<_DhikrPickerSheet> {
  late int _sel;
  @override void initState() { super.initState(); _sel = widget.selected; }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final textPri  = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final textSec  = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Row(children: [
            Text(widget.isUrdu ? 'ذکر منتخب کریں' : 'Select Dhikr',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPri)),
          ]),
        ),

        // Dhikr list
        ...widget.presets.asMap().entries.map((entry) {
          final i     = entry.key;
          final p     = entry.value;
          final sel   = _sel == i;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _sel = i); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: sel
                    ? widget.primary.withOpacity(isDark ? 0.25 : 0.08)
                    : isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: sel ? widget.primary : Colors.grey.withOpacity(0.18),
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                // Arabic text
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    p['arabic'] as String,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                        color: sel ? widget.primary : textPri),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.isUrdu ? p['urdu'] as String : p['label'] as String,
                    style: TextStyle(fontSize: 12, color: textSec),
                  ),
                ])),
                // Count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel ? widget.primary : widget.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('× ${p['count']}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: sel ? Colors.white : widget.primary)),
                ),
                if (sel) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle_rounded, color: widget.primary, size: 20),
                ],
              ]),
            ),
          );
        }).toList(),

        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, _sel),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(widget.isUrdu ? 'منتخب کریں' : 'Select',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ring painter
// ─────────────────────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color trackColor;
  _RingPainter({required this.progress, required this.primaryColor, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const sw = 13.0;
    canvas.drawCircle(center, radius,
        Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, 2 * pi * progress, false,
        Paint()..color = primaryColor..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) =>
      o.progress != progress || o.primaryColor != primaryColor;
}