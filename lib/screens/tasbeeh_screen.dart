import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
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
  {'arabic': 'سبحان الله',  'label': 'SubhanAllah',    'urdu': 'سبحان اللہ',    'count': 33},
  {'arabic': 'الحمد لله', 'label': 'Alhamdulillah',  'urdu': 'الحمد للہ',     'count': 33},
  {'arabic': 'الله أكبر',  'label': 'AllahuAkbar',    'urdu': 'اللہ اکبر',     'count': 34},
  {'arabic': 'أستغفر الله','label': 'Astaghfirullah', 'urdu': 'استغفر اللہ',   'count': 100},
  {'arabic': 'لا إله إلا الله', 'label': 'La ilaha illallah', 'urdu': 'لا الہ الا اللہ', 'count': 100},
];

class TasbeehScreen extends StatefulWidget {
  @override
  _TasbeehScreenState createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
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

  // Enhancement state
  bool _isProximityEnabled = false;
  bool _isTtsEnabled = false;
  bool _isVibrationEnabled = true;
  bool _isBackgroundEnabled = false;
  late FlutterTts _tts;
  StreamSubscription? _proximitySub;
  StreamSubscription? _volumeSub;
  final AudioPlayer _silentPlayer = AudioPlayer();
  bool _proximityHandNearby = false;
  bool _isTtsReady = false;
  bool _isShakeEnabled = false;
  bool _isTtsSpeakDhikr = false;
  StreamSubscription? _shakeSub;
  DateTime? _lastShake;
  DateTime? _lastProximityEvent;
  String _tasbeehSensitivity = 'Medium';

  // Debounced save timer — avoids hammering disk on every tap
  Timer? _saveDebounce;

  // 99 Names search
  String _namesSearch = '';
  final TextEditingController _searchController = TextEditingController();
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _pulseAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _progressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeOut))
      ..addListener(() {
        // Update progress value WITHOUT triggering full-tree rebuild.
        // The CustomPaint's shouldRepaint() handles redrawing efficiently.
        _animatedProgress = _progressAnim.value;
        // Only rebuild the counter area, not the entire screen
        if (mounted) setState(() {});
      });

    _focusNode = FocusNode();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
    _initTts();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Save state immediately when app goes to background
      _saveStateNow();
    }
    if (state == AppLifecycleState.resumed) {
      // Refresh UI when coming back to foreground
      setState(() {});
      _animateProgress(_counter / _target);
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt('tasbeeh_counter') ?? 0;
      _isTtsEnabled = prefs.getBool('tasbeeh_tts') ?? false;
      _isVibrationEnabled = prefs.getBool('tasbeeh_vibration') ?? true;
      _isTtsSpeakDhikr = prefs.getBool('tasbeeh_tts_dhikr') ?? false;
      _tasbeehSensitivity = prefs.getString('tasbeeh_sensitivity') ?? 'Medium';
      // We don't auto-enable background mode for safety, but we could if desired.
    });
    _animateProgress(_counter / _target);
  }

  /// Debounced save — schedules a disk write after 3 seconds of inactivity.
  /// Prevents hammering SharedPreferences with 4 writes on every single tap.
  void _saveStateDebounced() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 3), _saveStateNow);
  }

  /// Immediate save — used on dispose and app pause to prevent data loss.
  Future<void> _saveStateNow() async {
    _saveDebounce?.cancel();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('tasbeeh_counter', _counter);
    prefs.setBool('tasbeeh_tts', _isTtsEnabled);
    prefs.setBool('tasbeeh_vibration', _isVibrationEnabled);
    prefs.setBool('tasbeeh_tts_dhikr', _isTtsSpeakDhikr);
  }

  void _toggleBackgroundMode(bool enabled) async {
    setState(() => _isBackgroundEnabled = enabled);
    if (enabled) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  void _toggleShake(bool enabled) {
    setState(() => _isShakeEnabled = enabled);
    _shakeSub?.cancel();
    if (enabled) {
      // Listen to accelerometer for shake
      _shakeSub = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
        // Simple shake detection logic
        double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        double threshold = 12.0; // Low sensitivity
        if (_tasbeehSensitivity == 'High') threshold = 4.0;
        else if (_tasbeehSensitivity == 'Medium') threshold = 8.0;

        if (acceleration > threshold) { 
          final now = DateTime.now();
          if (_lastShake == null || now.difference(_lastShake!).inMilliseconds > 600) {
            _increment();
            _lastShake = now;
          }
        }
      });
    }
  }

  Future<void> _initTts() async {
    try {
      _tts = FlutterTts();
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);

      _tts.setCompletionHandler(() {});
      _tts.setErrorHandler((msg) {
        debugPrint("TTS Error: $msg");
      });

      // Warm up engines
      if (Theme.of(context).platform == TargetPlatform.android) {
        await _tts.setEngine("com.google.android.tts");
      }

      setState(() => _isTtsReady = true);
    } catch (e) {
      debugPrint("TTS Initialization error: $e");
      _isTtsReady = false;
    }
  }

  void _toggleProximity(bool enabled) {
    setState(() => _isProximityEnabled = enabled);
    _proximitySub?.cancel();
    if (enabled) {
      _proximitySub = ProximitySensor.events.listen((int event) {
        // Event 1 = hand nearby, 0 = hand away
        if (event == 1) {
          final now = DateTime.now();
          if (!_proximityHandNearby && (_lastProximityEvent == null || now.difference(_lastProximityEvent!).inMilliseconds > 500)) {
            _increment();
            _proximityHandNearby = true;
            _lastProximityEvent = now;
          }
        } else {
          _proximityHandNearby = false;
        }
      });
    }
  }

  Future<void> _speak(String text, {String? lang}) async {
    if (_isTtsEnabled && _isTtsReady) {
      await _tts.stop();
      if (lang != null) {
        await _tts.setLanguage(lang);
      } else {
        // Auto-detect based on app language if not specified
        final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
        await _tts.setLanguage(isUrdu ? "ur-PK" : "en-US");
      }
      await _tts.speak(text);
    }
  }

  @override
  void dispose() {
    // Save state immediately before screen is destroyed
    _saveStateNow();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _searchController.dispose();
    _proximitySub?.cancel();
    _shakeSub?.cancel();
    _saveDebounce?.cancel();
    _tts.stop();
    _silentPlayer.dispose();
    WakelockPlus.disable();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Counter actions ────────────────────────────────────────────────────────

  void _increment() {
    if (_counter >= _target) return;

    _counter++;
    _saveStateDebounced();

    // Only update UI if app is in foreground
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed ||
        WidgetsBinding.instance.lifecycleState == null) {
      if (_isVibrationEnabled) {
        Vibration.vibrate(duration: 40, amplitude: 128);
      } else {
        HapticFeedback.lightImpact();
      }
      _pulseController.forward().then((_) => _pulseController.reverse());
      setState(() {});
      _animateProgress(_counter / _target);
    } else {
      // In background, just vibrate and update local progress
      if (_isVibrationEnabled) {
        Vibration.vibrate(duration: 60, amplitude: 160);
      }
      _animatedProgress = _counter / _target;
    }

    // TTS for increment
    if (_counter == _target) {
      final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
      _speak(
        isUrdu ? 'تسبيح مکمل ہوگئی' : 'Tasbeeh Completed',
        lang: isUrdu ? "ur-PK" : "en-US"
      );
    } else {
      if (_isTtsSpeakDhikr) {
        String dhikrText = "";
        String dhikrLang = "ar-SA"; // Default to Arabic for Dhikr

        if (_tabController.index == 0 && _selectedPreset >= 0) {
          dhikrText = _dhikrPresets[_selectedPreset]['arabic'];
        } else {
          // Default or 99 Names
          dhikrText = "يا الله";
        }
        _speak(dhikrText, lang: dhikrLang);
      } else {
        final isUrdu = Provider.of<LanguageProvider>(context, listen: false).isUrdu;
        _speak(_counter.toString(), lang: isUrdu ? "ur-PK" : "en-US");
      }
    }

    if (_counter == _target && !_targetReachedShown) {
      _targetReachedShown = true;
      if (_isVibrationEnabled) {
        Vibration.vibrate(pattern: [0, 200, 100, 200]);
      } else {
        HapticFeedback.mediumImpact();
      }
      _speak("Mashallah! Tasbeeh complete");
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
      appBar: _buildAppBar(isUrdu, primary),
      body: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp ||
                event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
              _increment();
            }
          }
        },
        child: Column(
          children: [
            if (_tabController.index == 0) _buildSettingsBar(isUrdu, primary, isDark),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCounterTab(isUrdu, primary, isDark),
                  _buildNamesTab(isUrdu, primary, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isUrdu, Color primary) {
    return AppBar(
      title: Text(isUrdu ? 'تسبیح' : 'Tasbeeh'),
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.volunteer_activism_rounded),
          tooltip: isUrdu ? 'دعائیں' : 'Duas',
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
    );
  }

  Widget _buildSettingsBar(bool isUrdu, Color primary, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: primary.withOpacity(0.1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _settingsToggle(
              icon: Icons.waves_rounded,
              active: _isProximityEnabled,
              onTap: () => _toggleProximity(!_isProximityEnabled),
              label: isUrdu ? 'وِیو' : 'Wave',
              tooltip: isUrdu ? 'ہاتھ ہلا کر گنتی کریں (سینسر)' : 'Wave hand over sensor to count',
              color: primary,
            ),
            const SizedBox(width: 16),
            _settingsToggle(
              icon: Icons.volume_up_rounded,
              active: _isTtsEnabled,
              onTap: () => setState(() => _isTtsEnabled = !_isTtsEnabled),
              label: isUrdu ? 'آواز' : 'Voice',
              tooltip: isUrdu ? 'ذکر یا نمبر کی آواز فعال کریں' : 'Enable voice for dhikr or numbers',
              color: primary,
            ),
            const SizedBox(width: 16),
            _settingsToggle(
              icon: _isTtsSpeakDhikr ? Icons.text_fields_rounded : Icons.numbers_rounded,
              active: _isTtsEnabled,
              onTap: () {
                setState(() => _isTtsSpeakDhikr = !_isTtsSpeakDhikr);
                _saveStateNow();
              },
              label: isUrdu
                ? (_isTtsSpeakDhikr ? 'ذکر' : 'نمبر')
                : (_isTtsSpeakDhikr ? 'Dhikr' : 'Number'),
              tooltip: isUrdu ? 'ذکر یا نمبر کے درمیان تبدیلی' : 'Switch between speaking Dhikr or Numbers',
              color: primary,
            ),
            const SizedBox(width: 16),
            _settingsToggle(
              icon: Icons.vibration_rounded,
              active: _isVibrationEnabled,
              onTap: () => setState(() => _isVibrationEnabled = !_isVibrationEnabled),
              label: isUrdu ? 'تھرتھراہٹ' : 'Haptic',
              tooltip: isUrdu ? 'گنتی پر موبائل تھرتھراہٹ' : 'Vibrate on each count',
              color: primary,
            ),
            const SizedBox(width: 16),
            _settingsToggle(
              icon: Icons.auto_awesome_motion_rounded,
              active: _isShakeEnabled,
              onTap: () => _toggleShake(!_isShakeEnabled),
              label: isUrdu ? 'ہلائیں' : 'Shake',
              tooltip: isUrdu ? 'موبائل ہلا کر گنتی کریں' : 'Shake phone to count',
              color: primary,
            ),
            const SizedBox(width: 16),
            _settingsToggle(
              icon: Icons.phonelink_lock_rounded,
              active: _isBackgroundEnabled,
              onTap: () => _toggleBackgroundMode(!_isBackgroundEnabled),
              label: isUrdu ? 'بیک گراؤنڈ' : 'Background',
              tooltip: isUrdu ? 'اسکرین بند ہونے پر بھی گنتی جاری رکھیں' : 'Continue counting even with screen off',
              color: primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsToggle({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    required String label,
    required Color color,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? label,
      preferBelow: false,
      child: SizedBox(
        width: 54,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: active ? color : color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: active ? color.withOpacity(0.3) : Colors.transparent,
                      blurRadius: active ? 8 : 0.0001,
                      offset: active ? const Offset(0, 3) : Offset.zero,
                    )
                  ],
                ),
                child: Icon(
                  icon,
                  color: active ? Colors.white : color.withOpacity(0.6),
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  color: active ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
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

        const SizedBox(height: 18),

        // ── Ring counter — tap to count ───────────────────────────────
        GestureDetector(
          onTap: _increment,
          child: ScaleTransition(
            scale: _pulseAnim,
            child: SizedBox(
              width: 188, height: 188,
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
                      fontSize: 58,
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

        const SizedBox(height: 16),

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

        const SizedBox(height: 16),

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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDone
            ? Colors.green.withOpacity(isDark ? 0.15 : 0.08)
            : color.withOpacity(isDark ? 0.15 : 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
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
