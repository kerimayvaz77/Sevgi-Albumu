import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'models/album_entry.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/database_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'screens/splash_screen.dart';
import 'screens/my_home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'tr_TR';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sevgi Albümü',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      locale: const Locale('tr', 'TR'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF4B6E),
          primary: const Color(0xFFFF4B6E),
          secondary: const Color(0xFFFF8FA3),
          tertiary: const Color(0xFFFFB3C1),
        ),
        scaffoldBackgroundColor: const Color(0xFFFF4B6E),
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      home: SplashScreen(child: MyHomePage()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final DatabaseService _databaseService = DatabaseService();
  List<AlbumEntry> _entries = [];
  List<File> _selectedImages = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final ImagePicker _picker = ImagePicker();
  final List<AnimationController> _heartControllers = [];
  final List<Offset> _heartPositions = [];
  final Random _random = Random();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;
  final List<String> _bannerImages = [
    'assets/images/banner/1.jpeg',
    'assets/images/banner/2.jpeg',
    'assets/images/banner/3.jpeg',
    'assets/images/banner/4.jpeg',
    'assets/images/banner/5.jpeg',
    'assets/images/banner/6.jpeg',
    'assets/images/banner/7.jpeg',
    'assets/images/banner/8.jpeg',
    'assets/images/banner/9.jpeg',
    'assets/images/banner/10.jpeg',
    'assets/images/banner/11.jpeg',
    'assets/images/banner/12.jpeg',
    'assets/images/banner/13.jpeg',
    'assets/images/banner/14.jpeg',
    'assets/images/banner/15.jpeg',
    'assets/images/banner/16.jpeg',
    'assets/images/banner/17.jpeg',
    'assets/images/banner/18.jpeg',
    'assets/images/banner/19.jpeg',
    'assets/images/banner/20.jpeg',
  ];

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _selectedDay = _focusedDay;
    _startBannerTimer();
    _initializeHeartAnimations();
  }

  Future<void> _loadEntries() async {
    try {
      print('Veritabanından kayıtlar yükleniyor...');
      final entries = await _databaseService.getEntries();
      print('Yüklenen kayıt sayısı: ${entries.length}');

      setState(() {
        _entries = entries;
        // Tarihe göre sırala (en yeniden en eskiye)
        _entries.sort((a, b) => b.date.compareTo(a.date));
      });
    } catch (e, stackTrace) {
      print('Kayıtları yükleme hatası: $e');
      print('Hata detayı: $stackTrace');
      setState(() {
        _entries = [];
      });
    }
  }

  Future<void> _addEntry(String title, String note, List<File> images) async {
    final entry = AlbumEntry(
      id: const Uuid().v4(),
      title: title,
      note: note,
      imagePaths: images.map((file) => file.path).toList(),
      date: DateTime.now(),
    );

    await _databaseService.insertEntry(entry);
    await _loadEntries();
  }

  void _initializeHeartAnimations() {
    for (int i = 0; i < 10; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );
      _heartControllers.add(controller);
      _heartPositions.add(_generateRandomPosition());
    }
  }

  Offset _generateRandomPosition() {
    return Offset(
      _random.nextDouble() * 300,
      _random.nextDouble() * 400,
    );
  }

  void _triggerHeartAnimations() {
    for (var controller in _heartControllers) {
      controller.forward(from: 0);
    }
    Future.delayed(const Duration(milliseconds: 1500), () {
      for (int i = 0; i < _heartPositions.length; i++) {
        _heartPositions[i] = _generateRandomPosition();
      }
    });
  }

  Widget _buildOptimizedImage(String imagePath,
      {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    try {
      if (!File(imagePath).existsSync()) {
        print('Resim dosyası bulunamadı: $imagePath');
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      }

      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

      // Güvenli bir şekilde cache boyutlarını hesapla
      final int? cacheWidth = width != null && width.isFinite
          ? (width * devicePixelRatio).round()
          : null;
      final int? cacheHeight = height != null && height.isFinite
          ? (height * devicePixelRatio).round()
          : null;

      return Image.file(
        File(imagePath),
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          print('Resim yükleme hatası: $error');
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.error_outline, color: Colors.grey),
          );
        },
      );
    } catch (e) {
      print('_buildOptimizedImage hatası: $e');
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.error, color: Colors.grey),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _bannerTimer?.cancel();
    for (var controller in _heartControllers) {
      controller.dispose();
    }
    DefaultCacheManager().emptyCache();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      setState(() {
        _currentBannerIndex = (_currentBannerIndex + 1) % _bannerImages.length;
        _triggerHeartAnimations();
      });
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final XFile? pickedFile = await _picker.pickImage(source: source);
        if (pickedFile != null && _selectedImages.length < 3) {
          setState(() {
            _selectedImages.add(File(pickedFile.path));
          });
          if (_selectedImages.isNotEmpty) {
            _showAddEntryDialog();
          }
        }
      } else {
        if (_selectedImages.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('En fazla 3 fotoğraf seçebilirsiniz'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        final List<XFile>? pickedFiles = await _picker.pickMultiImage();
        if (pickedFiles != null) {
          setState(() {
            final remainingSlots = 3 - _selectedImages.length;
            final filesToAdd = pickedFiles.take(remainingSlots);
            _selectedImages.addAll(filesToAdd.map((file) => File(file.path)));
          });
          if (_selectedImages.isNotEmpty) {
            _showAddEntryDialog();
          }
        }
      }
    } catch (e) {
      debugPrint('Resim seçme hatası: $e');
    }
  }

  void _showAddEntryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        title: Column(
          children: [
            Icon(
              Icons.favorite,
              color: Theme.of(context).colorScheme.primary,
              size: 40,
            ),
            const SizedBox(height: 10),
            const Text(
              'Yeni Bir Anı Ekle',
              style: TextStyle(
                fontSize: 24,
                color: Color(0xFFFF4B6E),
              ),
            ),
          ],
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  enableSuggestions: true,
                  decoration: InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'Bu özel anının başlığı...',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.title,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    filled: true,
                    fillColor: Colors.pink.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  enableSuggestions: true,
                  decoration: InputDecoration(
                    labelText: 'Not',
                    hintText: 'Bu anıyla ilgili düşüncelerini paylaş...',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.note_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    filled: true,
                    fillColor: Colors.pink.withOpacity(0.05),
                  ),
                ),
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length +
                          (_selectedImages.length < 3 ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _selectedImages.length) {
                          return GestureDetector(
                            onTap: () => _pickImage(ImageSource.gallery),
                            child: Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Fotoğraf Ekle\n(${3 - _selectedImages.length} kaldı)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(index == 0 ? 25 : 0),
                                  topRight: index == _selectedImages.length - 1
                                      ? const Radius.circular(25)
                                      : Radius.zero,
                                ),
                                image: DecorationImage(
                                  image: FileImage(_selectedImages[index]),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 15,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                  if (_selectedImages.isEmpty) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _titleController.clear();
              _noteController.clear();
              setState(() {
                _selectedImages.clear();
              });
            },
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_selectedImages.isNotEmpty &&
                  _titleController.text.trim().isNotEmpty &&
                  _noteController.text.trim().isNotEmpty) {
                _addEntry(
                  _titleController.text,
                  _noteController.text,
                  _selectedImages,
                );
                Navigator.of(context).pop();
                _titleController.clear();
                _noteController.clear();
                setState(() {
                  _selectedImages.clear();
                  _selectedIndex = 1;
                });
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  void _showEntryDetails(AlbumEntry entry) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) => Transform.scale(
            scale: value,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 300,
                        child: Row(
                          children:
                              List.generate(entry.imagePaths.length, (index) {
                            return Expanded(
                              child: Hero(
                                tag: '${entry.id}_detail_$index',
                                child: Container(
                                  margin: EdgeInsets.only(
                                    left: index == 0 ? 0 : 4,
                                    right: index == entry.imagePaths.length - 1
                                        ? 0
                                        : 4,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.only(
                                      topLeft:
                                          Radius.circular(index == 0 ? 25 : 0),
                                      topRight:
                                          index == entry.imagePaths.length - 1
                                              ? const Radius.circular(25)
                                              : Radius.zero,
                                    ),
                                    child: _buildOptimizedImage(
                                      entry.imagePaths[index],
                                      height: 300,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(25),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Row(
                          children: [
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.elasticOut,
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) =>
                                  Transform.scale(
                                scale: value,
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.9),
                                        Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withOpacity(0.9),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        _showEditDialog(entry);
                                      },
                                      customBorder: const CircleBorder(),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.elasticOut,
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) =>
                                  Transform.scale(
                                scale: value,
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.shade400,
                                        Colors.red.shade700,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        _showDeleteConfirmationDialog(entry);
                                      },
                                      customBorder: const CircleBorder(),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.elasticOut,
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) =>
                                  Transform.scale(
                                scale: value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => Navigator.pop(context),
                                      customBorder: const CircleBorder(),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) =>
                                    Transform.scale(
                                  scale: value,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.favorite,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  entry.title,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    foreground: Paint()
                                      ..shader = LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ],
                                      ).createShader(const Rect.fromLTWH(
                                          0.0, 0.0, 200.0, 70.0)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                                  Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd MMMM yyyy', 'tr_TR')
                                      .format(entry.date),
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          Text(
                            'Sevgi Notumuz',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ).createShader(
                                    const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              entry.note,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(AlbumEntry entry) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        title: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 40,
            ),
            const SizedBox(height: 10),
            const Text(
              'Anıyı Sil',
              style: TextStyle(
                fontSize: 24,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: const Text(
          'Bu anıyı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _databaseService.deleteEntry(entry.id);
              await _loadEntries();
              if (mounted) {
                Navigator.pop(context); // Close confirmation dialog
                Navigator.pop(context); // Close detail view
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  void _showEditDialog(AlbumEntry entry) {
    final titleController = TextEditingController(text: entry.title);
    final noteController = TextEditingController(text: entry.note);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        title: Column(
          children: [
            Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.primary,
              size: 40,
            ),
            const SizedBox(height: 10),
            const Text(
              'Anıyı Düzenle',
              style: TextStyle(
                fontSize: 24,
                color: Color(0xFFFF4B6E),
              ),
            ),
          ],
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  enableSuggestions: true,
                  decoration: InputDecoration(
                    labelText: 'Başlık',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.title,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    filled: true,
                    fillColor: Colors.pink.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: noteController,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  enableSuggestions: true,
                  decoration: InputDecoration(
                    labelText: 'Not',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.note_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    filled: true,
                    fillColor: Colors.pink.withOpacity(0.05),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty &&
                  noteController.text.trim().isNotEmpty) {
                final updatedEntry = AlbumEntry(
                  id: entry.id,
                  title: titleController.text.trim(),
                  note: noteController.text.trim(),
                  imagePaths: entry.imagePaths,
                  date: entry.date,
                );
                await _databaseService.updateEntry(updatedEntry);
                await _loadEntries();
                if (mounted) {
                  Navigator.pop(context); // Close edit dialog
                  Navigator.pop(context); // Close detail view
                }
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildAlbumCard(AlbumEntry entry) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () => _showEntryDetails(entry),
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: '${entry.id}_detail_0',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: _buildOptimizedImage(
                      entry.imagePaths[0],
                      width: double.infinity,
                      height: 200,
                    ),
                  ),
                ),
                if (entry.imagePaths.length > 1)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.imagePaths.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd.MM.yyyy').format(entry.date),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, child) => Transform.scale(
                          scale: value,
                          child: Icon(
                            Icons.favorite,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumPage() {
    if (_entries.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_album_outlined,
                size: 100,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(height: 20),
              const Text(
                'Henüz hiç anı eklemediniz',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Yeni bir anı eklemek için + butonuna tıklayın',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text(
              'Albümümüz',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      '${_entries.length} Anı',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildAlbumCard(_entries[index]),
              childCount: _entries.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarPage() {
    final today = DateTime.now();
    final isNotCurrentMonth =
        _focusedDay.month != today.month || _focusedDay.year != today.year;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Column(
        children: [
          if (isNotCurrentMonth)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: Container(
                  margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _focusedDay = today;
                          _selectedDay = today;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.95),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.elasticOut,
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) =>
                                  Transform.rotate(
                                angle: value * 2 * 3.14159,
                                child: Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'Bugüne Dön',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2025, 12, 31),
              focusedDay: _focusedDay,
              currentDay: DateTime.now(),
              locale: 'tr_TR',
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableGestures: AvailableGestures.all,
              daysOfWeekHeight: 40,
              rowHeight: 60,
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Theme.of(context).colorScheme.primary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                weekendStyle: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: const TextStyle(color: Colors.red),
                holidayTextStyle: const TextStyle(color: Colors.red),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                markerSize: 8,
                markerMargin: const EdgeInsets.symmetric(horizontal: 0.3),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: (day) {
                return _entries
                    .where((entry) =>
                        entry.date.year == day.year &&
                        entry.date.month == day.month &&
                        entry.date.day == day.day)
                    .toList();
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _selectedDay != null
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _entries
                          .where(
                              (entry) => isSameDay(entry.date, _selectedDay!))
                          .length,
                      itemBuilder: (context, index) {
                        final entriesForDay = _entries
                            .where(
                                (entry) => isSameDay(entry.date, _selectedDay!))
                            .toList();
                        final entry = entriesForDay[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: InkWell(
                            onTap: () => _showEntryDetails(entry),
                            borderRadius: BorderRadius.circular(15),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: Hero(
                                tag: '${entry.id}_calendar_${index}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildOptimizedImage(
                                    entry.imagePaths[0],
                                    width: 60,
                                    height: 60,
                                  ),
                                ),
                              ),
                              title: Text(
                                entry.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                entry.note,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'Lütfen bir gün seçin',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartAnimation(AnimationController controller, Offset position) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Transform.translate(
            offset: Offset(0, -100 * controller.value),
            child: Opacity(
              opacity: 1 - controller.value,
              child: Transform.scale(
                scale: 0.5 + (controller.value * 0.5),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomePage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'Sevgi Albümü',
              style: TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Her an seninle olmak en büyük mutluluğum ❤️',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              height: 300,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      );
                    },
                    child: ClipRRect(
                      key: ValueKey<int>(_currentBannerIndex),
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        _bannerImages[_currentBannerIndex],
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  ..._heartControllers.asMap().entries.map((entry) {
                    return _buildHeartAnimation(
                      entry.value,
                      _heartPositions[entry.key],
                    );
                  }).toList(),
                ],
              ),
            ),
            if (_entries.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Son Anılarımız',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedIndex = 1),
                      child: Row(
                        children: [
                          Text(
                            'Tümünü Gör',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white.withOpacity(0.9),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 320,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _entries.length.clamp(0, 5),
                  itemBuilder: (context, index) {
                    final entry = _entries[_entries.length - 1 - index];
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 16),
                      child: _buildAlbumCard(entry),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: IndexedStack(
            key: ValueKey<int>(_selectedIndex),
            index: _selectedIndex,
            children: [
              _buildHomePage(),
              _buildAlbumPage(),
              _buildCalendarPage(),
            ],
          ),
        ),
      ),
      floatingActionButton: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(32.5),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        _buildModalButton(
                          icon: Icons.photo_library,
                          color: Colors.blue,
                          label: 'Galeriden Seç',
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildModalButton(
                          icon: Icons.camera_alt,
                          color: Theme.of(context).colorScheme.primary,
                          label: 'Kamera ile Çek',
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) => Transform.rotate(
                  angle: value * 2 * math.pi,
                  child: const Icon(
                    Icons.add_photo_alternate,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomAppBar(
            height: 70,
            padding: EdgeInsets.zero,
            notchMargin: 10,
            elevation: 0,
            color: Colors.transparent,
            shape: const CircularNotchedRectangle(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    icon: Icons.home_rounded,
                    label: 'Ana Sayfa',
                    isSelected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                  const SizedBox(width: 60),
                  _buildNavItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Takvim',
                    isSelected: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: isSelected ? 1.2 : 0.8),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: Icon(
                  icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  size: 26,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 8 : 0,
            ),
            ClipRect(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isSelected ? 70 : 0,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.clip,
                  softWrap: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
