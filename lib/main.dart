import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:monster_battle_game/party_screen.dart';
import 'package:monster_battle_game/battle_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:monster_battle_game/firebase_options.dart';

// Enum untuk merepresentasikan elemen monster
enum MonsterElement { Api, Air, Tumbuhan }

// Enum untuk tipe serangan (Moveset)
enum MoveType { normal, elemental, special, recover }

// Kelas model untuk serangan monster
class MonsterMove {
  final String name;
  final MoveType type;
  final int power;
  final String? effect;
  final int cost;
  const MonsterMove({
    required this.name,
    required this.type,
    required this.power,
    this.effect,
    this.cost = 0,
  });
}

// Kelas model untuk data monster
class Monster {
  final String name;
  final MonsterElement element;
  final String imagePath;
  double attack;
  double defense;
  int speed;
  int stamina;
  int hp;
  int level;
  int currentExp;
  int expToNextLevel;
  final List<MonsterMove> moves;

  Monster({
    required this.name,
    required this.element,
    required this.imagePath,
    required this.attack,
    required this.defense,
    required this.speed,
    required this.stamina,
    required this.hp,
    required this.level,
    this.currentExp = 0,
    required this.moves,
  }) : expToNextLevel = calculateExpForNextLevel(level);

  // Fungsi untuk mendapatkan warna berdasarkan elemen
  Color get elementColor {
    switch (element) {
      case MonsterElement.Api:
        return Colors.red.shade400;
      case MonsterElement.Air:
        return Colors.blue.shade400;
      case MonsterElement.Tumbuhan:
        return Colors.green.shade400;
    }
  }

  // Fungsi untuk menghitung EXP yang dibutuhkan untuk level berikutnya
  static int calculateExpForNextLevel(int level) {
    if (level <= 0) return 75;
    // Pola: 75, 80, 90, 105, ...
    // Kenaikan: 5, 10, 15, ... (kelipatan 5)
    int baseExp = 75;
    int totalIncrease =
        (level - 1) * level * 5 ~/ 2; // Rumus jumlah deret aritmatika
    return baseExp + totalIncrease;
  }

  // Fungsi untuk menaikkan level dan status monster
  Map<String, num> levelUp() {
    level++;
    // Peningkatan stat disesuaikan dengan skala baru
    int hpGain = 10;
    double attackGain = 3;
    double defenseGain = 3;
    int speedGain = 2;
    int staminaGain = 5;

    hp += hpGain;
    attack += attackGain;
    defense += defenseGain;
    speed += speedGain;
    stamina += staminaGain;

    // Mengembalikan nilai peningkatannya untuk ditampilkan di UI
    return {
      'HP': hpGain,
      'Attack': attackGain,
      'Defense': defenseGain,
      'Speed': speedGain,
      'Stamina': staminaGain,
    };
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Inisialisasi Firebase beserta konfigurasinya
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monster Battle Game',
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const MonsterSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MonsterSelectionScreen extends StatefulWidget {
  const MonsterSelectionScreen({super.key});

  @override
  State<MonsterSelectionScreen> createState() => _MonsterSelectionScreenState();
}

class _MonsterSelectionScreenState extends State<MonsterSelectionScreen> {
  late final PageController _pageController;
  int _selectedIndex = 1; // Mulai dari monster tengah (index 1)

  // Daftar monster yang bisa dipilih
  final List<Monster> monsters = [
    Monster(
      name: 'Apiroar',
      element: MonsterElement.Api,
      imagePath:
          'assets/images/fire_monster.png', // Ganti dengan path gambar Anda
      level: 1,
      hp: 60,
      attack: 80,
      defense: 60,
      speed: 70,
      stamina: 50,
      moves: [
        const MonsterMove(
          name: 'Scratch',
          type: MoveType.normal,
          power: 40,
          cost: -7,
        ),
        const MonsterMove(
          name: 'Ember',
          type: MoveType.elemental,
          power: 50,
          cost: 10,
        ),
        const MonsterMove(
          name: 'Flame Spin',
          type: MoveType.special,
          power: 45,
          effect: 'Burn 3 turn',
          cost: 10,
        ),
        const MonsterMove(
          name: 'Focus',
          type: MoveType.recover,
          power: 0,
          cost: -15,
        ), // Recover
      ],
    ),
    Monster(
      name: 'Aquadash',
      element: MonsterElement.Air,
      imagePath:
          'assets/images/water_monster.png', // Ganti dengan path gambar Anda
      level: 1,
      hp: 70,
      attack: 70,
      defense: 70,
      speed: 80,
      stamina: 50,
      moves: [
        const MonsterMove(
          name: 'Pound',
          type: MoveType.normal,
          power: 40,
          cost: -7,
        ),
        const MonsterMove(
          name: 'Bubble',
          type: MoveType.elemental,
          power: 45,
          cost: 10,
        ),
        const MonsterMove(
          name: 'Bind',
          type: MoveType.special,
          power: 30,
          effect: 'Bind 3 turn',
          cost: 10,
        ),
        const MonsterMove(
          name: 'Focus',
          type: MoveType.recover,
          power: 0,
          cost: -15,
        ), // Recover
      ],
    ),
    Monster(
      name: 'Gaiaroot',
      element: MonsterElement.Tumbuhan,
      imagePath:
          'assets/images/plant_monster.png', // Ganti dengan path gambar Anda
      level: 1,
      hp: 85,
      attack: 60,
      defense: 80,
      speed: 50,
      stamina: 50,
      moves: [
        const MonsterMove(
          name: 'Tackle',
          type: MoveType.normal,
          power: 40,
          cost: -7,
        ),
        const MonsterMove(
          name: 'Vine Whip',
          type: MoveType.elemental,
          power: 40,
          cost: 10,
        ),
        const MonsterMove(
          name: 'Absorb',
          type: MoveType.special,
          power: 20,
          effect: 'Drain HP & Heal',
          cost: 10,
        ),
        const MonsterMove(
          name: 'Focus',
          type: MoveType.recover,
          power: 0,
          cost: -15,
        ), // Recover
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Tentukan halaman awal yang besar untuk "infinite" scroll,
    // pastikan halaman awal menunjuk ke _selectedIndex yang benar.
    final int initialPage =
        (10000 ~/ monsters.length) * monsters.length + _selectedIndex;

    _pageController = PageController(
      viewportFraction: 0.6, // Perbesar kartu utama, perkecil kartu samping
      initialPage: initialPage,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  IconData _getElementIcon(MonsterElement element) {
    switch (element) {
      case MonsterElement.Api:
        return Icons.local_fire_department;
      case MonsterElement.Air:
        return Icons.water_drop;
      case MonsterElement.Tumbuhan:
        return Icons.eco;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pilih Partner Bertarungmu',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // Carousel Kartu Monster
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: 20000, // Infinite scroll
                      onPageChanged: (index) {
                        setState(() {
                          _selectedIndex = index % monsters.length;
                        });
                      },
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double value = 0.0;
                            if (_pageController.position.haveDimensions) {
                              value = _pageController.page! - index;
                            }
                            final double scale = (1 - (value.abs() * 0.3))
                                .clamp(0.7, 1.0);
                            return Center(
                              child: SizedBox(
                                height: Curves.easeOut.transform(scale) * 420,
                                child: child,
                              ),
                            );
                          },
                          child: MonsterCard(
                            monster: monsters[index % monsters.length],
                          ),
                        );
                      },
                    ),
                    // Tombol Navigasi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded),
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tombol Pilih
              ElevatedButton(
                onPressed: () {
                  final selectedMonster = monsters[_selectedIndex];
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) =>
                          MainScreen(party: [selectedMonster]),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: monsters[_selectedIndex].elementColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Pilih Partner Ini'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN SCREEN (HUB / NAVBAR)
// ============================================================================
class MainScreen extends StatefulWidget {
  final List<Monster> party;

  const MainScreen({super.key, required this.party});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      PartyScreen(party: widget.party),
      BattleMenuScreen(party: widget.party),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.catching_pokemon),
            label: 'Party',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.flash_on,
            ), // Ikon petir yang merepresentasikan action / VS / Battle
            label: 'Battle',
          ),
        ],
      ),
    );
  }
}

// Widget untuk menampilkan kartu monster
class MonsterCard extends StatelessWidget {
  final Monster monster;

  const MonsterCard({super.key, required this.monster});

  IconData _getElementIcon(MonsterElement element) {
    switch (element) {
      case MonsterElement.Api:
        return Icons.local_fire_department;
      case MonsterElement.Air:
        return Icons.water_drop;
      case MonsterElement.Tumbuhan:
        return Icons.eco;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aspect Ratio Kartu (mirip TCG, tinggi ~1.4x lebar)
    return AspectRatio(
      aspectRatio: 63 / 88,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Layer 1: Latar Belakang Gradien
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        monster.elementColor.withOpacity(0.4),
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              ),
              // Layer 2: Pola Elemen
              Positioned.fill(
                child: Transform.rotate(
                  angle: -math.pi / 6,
                  child: Icon(
                    _getElementIcon(monster.element),
                    size: 250,
                    color: Colors.black.withOpacity(0.03),
                  ),
                ),
              ),
              // Layer 3: Konten Kartu
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nama dan Elemen
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            monster.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                          ),
                        ),
                        Icon(
                          _getElementIcon(monster.element),
                          color: monster.elementColor,
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Placeholder Gambar
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.08),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Gambar ${monster.name}',
                            style: const TextStyle(color: Colors.black45),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Statistik
                    _buildStatBar('HP', monster.hp, 200, Colors.green),
                    const SizedBox(height: 6),
                    _buildStatBar('Attack', monster.attack, 100, Colors.orange),
                    const SizedBox(height: 6),
                    _buildStatBar(
                      'Speed',
                      monster.speed,
                      100,
                      Colors.lightBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper untuk menampilkan baris statistik dengan bar
  Widget _buildStatBar(String label, num value, int maxValue, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: $value',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / maxValue,
          backgroundColor: Colors.grey.shade300,
          color: color,
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
