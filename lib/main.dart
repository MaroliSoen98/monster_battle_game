import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monster_battle_game/party_screen.dart';
import 'package:monster_battle_game/battle_arena.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:monster_battle_game/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Enum untuk merepresentasikan elemen monster
enum MonsterElement { Api, Air, Tumbuhan, Listrik, Tanah, Terbang }

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

  // Convert ke format JSON untuk disimpan
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.index,
    'power': power,
    'effect': effect,
    'cost': cost,
  };

  factory MonsterMove.fromJson(Map<String, dynamic> json) => MonsterMove(
    name: json['name'],
    type: MoveType.values[json['type']],
    power: json['power'],
    effect: json['effect'],
    cost: json['cost'],
  );
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

  // Convert ke format JSON untuk disimpan
  Map<String, dynamic> toJson() => {
    'name': name,
    'element': element.index,
    'imagePath': imagePath,
    'attack': attack,
    'defense': defense,
    'speed': speed,
    'stamina': stamina,
    'hp': hp,
    'level': level,
    'currentExp': currentExp,
    'moves': moves.map((m) => m.toJson()).toList(),
  };

  factory Monster.fromJson(Map<String, dynamic> json) => Monster(
    name: json['name'],
    element: MonsterElement.values[json['element']],
    imagePath: json['imagePath'],
    attack: json['attack'],
    defense: json['defense'],
    speed: json['speed'],
    stamina: json['stamina'],
    hp: json['hp'],
    level: json['level'],
    currentExp: json['currentExp'] ?? 0,
    moves: (json['moves'] as List).map((m) => MonsterMove.fromJson(m)).toList(),
  );

  // Fungsi untuk mendapatkan warna berdasarkan elemen
  Color get elementColor {
    switch (element) {
      case MonsterElement.Api:
        return Colors.red.shade400;
      case MonsterElement.Air:
        return Colors.blue.shade400;
      case MonsterElement.Tumbuhan:
        return Colors.green.shade400;
      case MonsterElement.Listrik:
        return Colors.yellow.shade600;
      case MonsterElement.Tanah:
        return Colors.brown.shade500;
      case MonsterElement.Terbang:
        return Colors.lightBlue.shade100;
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

// Class khusus untuk menangani proses Save & Load ke memori internal (Cache)
class SaveManager {
  static Future<void> saveParty(List<Monster> party) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      party.map((m) => m.toJson()).toList(),
    );
    await prefs.setString('saved_party', encodedData);

    // --- CLOUD SAVE ---
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'party': party.map((m) => m.toJson()).toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Cloud save party error: $e');
      }
    }
  }

  static Future<List<Monster>?> loadParty() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('saved_party');
    if (encodedData != null) {
      final List<dynamic> decodedData = jsonDecode(encodedData);
      return decodedData.map((m) => Monster.fromJson(m)).toList();
    }
    return null;
  }

  static Future<void> saveBox(List<Monster> box) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(box.map((m) => m.toJson()).toList());
    await prefs.setString('saved_box', encodedData);

    // --- CLOUD SAVE ---
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'box': box.map((m) => m.toJson()).toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Cloud save box error: $e');
      }
    }
  }

  static Future<List<Monster>> loadBox() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('saved_box');
    if (encodedData != null) {
      final List<dynamic> decodedData = jsonDecode(encodedData);
      return decodedData.map((m) => Monster.fromJson(m)).toList();
    }
    return [];
  }

  static Future<void> saveGold(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('player_gold', amount);

    // --- CLOUD SAVE ---
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'gold': amount,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Cloud save gold error: $e');
      }
    }
  }

  static Future<int> loadGold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('player_gold') ?? 0;
  }

  static Future<void> saveBalls(int basic, int power, int locked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('basic_ball_qty', basic);
    await prefs.setInt('power_ball_qty', power);
    await prefs.setInt('locked_ball_qty', locked);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'balls': {'basic': basic, 'power': power, 'locked': locked},
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Cloud save balls error: $e');
      }
    }
  }

  static Future<void> saveEncounteredMonster(String monsterName) async {
    final prefs = await SharedPreferences.getInstance();
    // Gunakan .toList() agar data yang dikembalikan bersifat mutable (bisa ditambah)
    List<String> encountered =
        prefs.getStringList('encountered_monsters')?.toList() ?? [];
    if (!encountered.contains(monsterName)) {
      encountered.add(monsterName);
      await prefs.setStringList('encountered_monsters', encountered);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'encountered_monsters': encountered,
                'lastUpdated': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Cloud save encountered error: $e');
        }
      }
    }
  }

  static Future<List<String>> loadEncounteredMonsters() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('encountered_monsters') ?? [];
  }

  static Future<void> saveTowerProgress(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('infinite_tower_progress', level);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'tower_progress': level,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Cloud save tower error: $e');
      }
    }
  }

  // Sync dari Cloud saat login (Dipanggil oleh AuthWrapper)
  static Future<List<Monster>?> loadOrSyncData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          final prefs = await SharedPreferences.getInstance();
          List<Monster>? cloudParty;

          if (data.containsKey('party')) {
            final List<dynamic> partyData = data['party'];
            cloudParty = partyData.map((m) => Monster.fromJson(m)).toList();
            await prefs.setString('saved_party', jsonEncode(partyData));
          }
          if (data.containsKey('box')) {
            final List<dynamic> boxData = data['box'];
            await prefs.setString('saved_box', jsonEncode(boxData));
          }
          if (data.containsKey('gold')) {
            await prefs.setInt('player_gold', data['gold']);
          }
          if (data.containsKey('balls')) {
            final balls = data['balls'];
            await prefs.setInt('basic_ball_qty', balls['basic'] ?? 10);
            await prefs.setInt('power_ball_qty', balls['power'] ?? 5);
            await prefs.setInt('locked_ball_qty', balls['locked'] ?? 3);
          }
          if (data.containsKey('tower_progress')) {
            await prefs.setInt(
              'infinite_tower_progress',
              data['tower_progress'],
            );
          }
          if (data.containsKey('wild_battles_left') &&
              data.containsKey('last_quota_recovery_time')) {
            await prefs.setInt('wild_battles_left', data['wild_battles_left']);
            await prefs.setString(
              'last_quota_recovery_time',
              data['last_quota_recovery_time'],
            );
          }
          if (data.containsKey('encountered_monsters')) {
            final List<dynamic> encounteredData = data['encountered_monsters'];
            await prefs.setStringList(
              'encountered_monsters',
              encounteredData.map((e) => e.toString()).toList(),
            );
          }

          if (cloudParty != null) return cloudParty;
        }
      } catch (e) {
        debugPrint('Cloud sync error: $e');
      }
    }
    // Fallback jika tidak ada data di cloud atau pengguna tidak terhubung
    return await loadParty();
  }

  // Hapus semua data lokal saat logout
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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
      title: 'Duel Monster',
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      // Gunakan AuthWrapper untuk mengecek status login Firebase
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ============================================================================
// SHOP SCREEN
// ============================================================================
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _currentGold = 0;
  List<Map<String, dynamic>> _shopItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    _currentGold = await SaveManager.loadGold();
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _shopItems = [
        {
          'name': 'Basic Ball',
          'price': 100,
          'quantity': prefs.getInt('basic_ball_qty') ?? 10,
          'color': Colors.red,
          'key': 'basic_ball_qty',
        },
        {
          'name': 'Power Ball',
          'price': 250,
          'quantity': prefs.getInt('power_ball_qty') ?? 5,
          'color': Colors.blue,
          'key': 'power_ball_qty',
        },
        {
          'name': 'Master Ball', // Mengubah Locked Ball menjadi Master Ball
          'price': 350,
          'quantity': prefs.getInt('locked_ball_qty') ?? 3,
          'color': Colors.purple,
          'key': 'locked_ball_qty',
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _buyItem(int index) async {
    final item = _shopItems[index];
    if (_currentGold >= item['price']) {
      setState(() {
        _currentGold -= item['price'] as int;
        item['quantity']++;
      });
      await SaveManager.saveGold(_currentGold);
      await SaveManager.saveBalls(
        _shopItems[0]['quantity'],
        _shopItems[1]['quantity'],
        _shopItems[2]['quantity'],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil membeli ${item['name']}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gold tidak cukup!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shop')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shop',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monetization_on,
                  color: Colors.amber.shade700,
                  size: 30,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gold: $_currentGold',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _shopItems.length,
              itemBuilder: (context, index) {
                final item = _shopItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.catching_pokemon,
                          color: item['color'],
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Harga: ${item['price']} Gold',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              Text(
                                'Dimiliki: ${item['quantity']}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _buyItem(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: item['color'],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Beli'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading saat mengecek state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }
        // Jika user sudah login
        if (snapshot.hasData) {
          return FutureBuilder<List<Monster>?>(
            future: SaveManager.loadOrSyncData(),
            builder: (context, syncSnapshot) {
              if (syncSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 100,
                          height: 100,
                        ),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const Text('Menyinkronkan data Cloud...'),
                      ],
                    ),
                  ),
                );
              }
              final party = syncSnapshot.data;
              if (party != null && party.isNotEmpty) {
                return MainScreen(party: party);
              } else {
                return const MonsterSelectionScreen();
              }
            },
          );
        }
        // Jika user belum login
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();

        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

        if (googleUser == null) return;

        final googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login gagal: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 48.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              width: 80,
                              height: 80,
                            ),
                            const SizedBox(height: 24),
                            const CircularProgressIndicator(
                              color: Colors.blueAccent,
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 100,
                            height: 100,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Duel Monster',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Masuk untuk memulai pertarungan!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Standar Google Sign-In Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: _signInWithGoogle,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Colors.black12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                                shadowColor: Colors.black12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://developers.google.com/identity/images/g-logo.png',
                                    height: 24,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.g_mobiledata,
                                              color: Colors.blue,
                                              size: 32,
                                            ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Roboto',
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
      ),
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
  late final List<Widget> _prebuiltMonsterCards;

  // Daftar monster yang bisa dipilih
  final List<Monster> monsters = [
    Monster(
      name: 'Apiroar',
      element: MonsterElement.Api,
      imagePath:
          'assets/images/fire_monster_front.png', // Ganti dengan path gambar Anda
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
        const MonsterMove(
          name: 'Heal',
          type: MoveType.recover,
          power: 15,
          cost: 0,
        ),
      ],
    ),
    Monster(
      name: 'Aquadash',
      element: MonsterElement.Air,
      imagePath:
          'assets/images/water_monster_front.png', // Ganti dengan path gambar Anda
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
          effect: 'Bind 1 turn',
          cost: 10,
        ),
        const MonsterMove(
          name: 'Focus',
          type: MoveType.recover,
          power: 0,
          cost: -15,
        ), // Recover
        const MonsterMove(
          name: 'Heal',
          type: MoveType.recover,
          power: 15,
          cost: 0,
        ),
      ],
    ),
    Monster(
      name: 'Gaiaroot',
      element: MonsterElement.Tumbuhan,
      imagePath:
          'assets/images/plant_monster_front.png', // Ganti dengan path gambar Anda
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
        const MonsterMove(
          name: 'Heal',
          type: MoveType.recover,
          power: 15,
          cost: 0,
        ),
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
      viewportFraction:
          0.55, // Sesuaikan fraction untuk sensitivitas geseran (swipe) carousel
      initialPage: initialPage,
    );

    // Optimisasi: Pre-build widget kartu dan bungkus dengan RepaintBoundary
    // agar Flutter tidak me-rebuild bayangan dan UI kartu berulang kali saat digeser.
    _prebuiltMonsterCards = monsters.map((monster) {
      return RepaintBoundary(child: MonsterCard(monster: monster));
    }).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Optimisasi: Pre-cache gambar agar tidak lag (jank) saat pertama kali dimuat
    for (var monster in monsters) {
      precacheImage(AssetImage(monster.imagePath), context);
    }
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
      case MonsterElement.Listrik:
        return Icons.bolt;
      case MonsterElement.Tanah:
        return Icons.terrain;
      case MonsterElement.Terbang:
        return Icons.flutter_dash;
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
                        // Gunakan AnimatedBuilder spesifik hanya di dalam item
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double page = index.toDouble();
                            if (_pageController.position.haveDimensions) {
                              page = _pageController.page ?? page;
                            }
                            double value = (page - index).clamp(-1.0, 1.0);

                            // Animasi scale & opacity yang native dan jauh lebih ringan
                            double scale = (1 - (value.abs() * 0.15)).clamp(
                              0.8,
                              1.0,
                            );
                            double opacity = (1 - (value.abs() * 0.5)).clamp(
                              0.4,
                              1.0,
                            );

                            return Center(
                              child: Transform.scale(
                                scale: scale,
                                child: Opacity(opacity: opacity, child: child),
                              ),
                            );
                          },
                          child: SizedBox(
                            height: 420,
                            child:
                                _prebuiltMonsterCards[index % monsters.length],
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
                onPressed: () async {
                  final selectedMonster = monsters[_selectedIndex];
                  final newParty = [selectedMonster];

                  // Simpan data pertama kali dipilih ke memori internal
                  await SaveManager.saveParty(newParty);

                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => MainScreen(party: newParty),
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
      case MonsterElement.Listrik:
        return Icons.bolt;
      case MonsterElement.Tanah:
        return Icons.terrain;
      case MonsterElement.Terbang:
        return Icons.flutter_dash;
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
                    // Gambar Monster
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(
                          16.0,
                        ), // Padding agar gambar tidak terlalu besar
                        child: Image.asset(
                          monster.imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Template visual (placeholder) ukuran gambar
                            return Container(
                              decoration: BoxDecoration(
                                color: monster.elementColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: monster.elementColor.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.pets, // Ikon jejak kaki
                                      size: 80, // Ukuran ikon besar
                                      color: monster.elementColor.withOpacity(
                                        0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Area Gambar\n(Maksimal Segini)',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: monster.elementColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

// ============================================================================
// WIDGET DRAWER (HAMBURGER MENU - SUB MENU)
// ============================================================================
class AppDrawer extends StatelessWidget {
  final List<Monster>? party;
  final VoidCallback? onPartyUpdated;

  const AppDrawer({super.key, this.party, this.onPartyUpdated});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width:
          MediaQuery.of(context).size.width *
          0.5, // Tepat memakan separuh layar
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            margin: EdgeInsets.zero,
            child: const SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.menu_open, color: Colors.white, size: 36),
                  SizedBox(height: 12),
                  Text(
                    'Sub Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.menu_book,
                    color: Colors.blueAccent,
                  ),
                  title: const Text('Pokedex'),
                  onTap: () {
                    Navigator.pop(context); // Tutup drawer saat diklik
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PokedexScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.inventory_2,
                    color: Colors.blueAccent,
                  ),
                  title: const Text('Monster Box'),
                  onTap: () {
                    Navigator.pop(context); // Tutup drawer saat diklik
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MonsterBoxScreen(party: party ?? []),
                      ),
                    ).then((_) {
                      if (onPartyUpdated != null) {
                        onPartyUpdated!();
                      }
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.store, color: Colors.blueAccent),
                  title: const Text('Shop'),
                  onTap: () {
                    Navigator.pop(context); // Tutup drawer saat diklik
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShopScreen(),
                      ),
                    ).then((_) {
                      // Refresh gold dan ball quantity setelah kembali dari shop
                      if (onPartyUpdated != null) onPartyUpdated!();
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.blueAccent),
                  title: const Text('Pengaturan'),
                  onTap: () {
                    Navigator.pop(context); // Tutup drawer
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menu Pengaturan belum tersedia'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: Colors.blueAccent,
                  ),
                  title: const Text('Tentang'),
                  onTap: () {
                    Navigator.pop(context); // Tutup drawer
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Duel Monster v1.0.0')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// POKEDEX SCREEN
// ============================================================================
class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  List<Map<String, dynamic>> _allMonsters = [];
  List<String> _encountered = [];
  List<String> _captured = [];
  bool _isLoading = true;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadPokedexData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPokedexData() async {
    // 1. Load captured
    final party = await SaveManager.loadParty() ?? [];
    final box = await SaveManager.loadBox();
    _captured = party.map((m) => m.name.trim()).toList();
    // Monster yang di dalam box tetap dihitung milik pemain
    _captured.addAll(box.map((m) => m.name.trim()).toList());

    // 2. Load encountered
    _encountered = await SaveManager.loadEncounteredMonsters();

    // Gabungkan pokemon yang dimiliki ke dalam daftar ditemui (encountered)
    for (String capturedMonster in _captured) {
      if (!_encountered.contains(capturedMonster)) {
        _encountered.add(capturedMonster);
      }
    }

    // 3. Load all from CSV
    List<Map<String, dynamic>> loadedMonsters = [];
    try {
      final String fileData = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/monsters.csv');
      List<String> lines = fileData.split('\n');
      if (lines.isNotEmpty && lines.first.toLowerCase().contains('nama')) {
        lines.removeAt(0);
      }
      lines.removeWhere((line) => line.trim().isEmpty);

      for (String line in lines) {
        List<String> columns = line.split(RegExp(r'[,;]'));
        if (columns.length >= 3) {
          final name = columns[1].replaceAll('"', '').trim();
          // Jangan masukkan ke daftar jika nama monster sudah ada (mencegah duplikat)
          if (!loadedMonsters.any((m) => m['name'] == name)) {
            loadedMonsters.add({
              'name': name,
              'element': _getElementFromString(
                columns[2].replaceAll('"', '').trim(),
              ),
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Gagal membaca monsters.csv: $e');
    }

    setState(() {
      _allMonsters = loadedMonsters;
      _isLoading = false;
    });
  }

  MonsterElement _getElementFromString(String elementStr) {
    if (elementStr == 'Api') return MonsterElement.Api;
    if (elementStr == 'Air') return MonsterElement.Air;
    if (elementStr == 'Listrik') return MonsterElement.Listrik;
    if (elementStr == 'Tanah') return MonsterElement.Tanah;
    if (elementStr == 'Terbang') return MonsterElement.Terbang;
    return MonsterElement.Tumbuhan;
  }

  IconData _getElementIcon(MonsterElement element) {
    switch (element) {
      case MonsterElement.Api:
        return Icons.local_fire_department;
      case MonsterElement.Air:
        return Icons.water_drop;
      case MonsterElement.Tumbuhan:
        return Icons.eco;
      case MonsterElement.Listrik:
        return Icons.bolt;
      case MonsterElement.Tanah:
        return Icons.terrain;
      case MonsterElement.Terbang:
        return Icons.flutter_dash;
    }
  }

  Color _getElementColor(MonsterElement element) {
    switch (element) {
      case MonsterElement.Api:
        return Colors.red.shade400;
      case MonsterElement.Air:
        return Colors.blue.shade400;
      case MonsterElement.Tumbuhan:
        return Colors.green.shade400;
      case MonsterElement.Listrik:
        return Colors.yellow.shade600;
      case MonsterElement.Tanah:
        return Colors.brown.shade500;
      case MonsterElement.Terbang:
        return Colors.lightBlue.shade100;
    }
  }

  Widget _buildInfoChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildPokedexCard(
    String name,
    MonsterElement element,
    bool isCaptured,
    bool isEncountered,
  ) {
    Color cardColor;
    Color iconColor;
    String displayName;
    Widget content;

    if (isCaptured) {
      cardColor = _getElementColor(element);
      iconColor = Colors.white;
      displayName = name;
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getElementIcon(element), color: iconColor, size: 40),
          const SizedBox(height: 8),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      );
    } else if (isEncountered) {
      cardColor = Colors.grey.shade300;
      iconColor = Colors.grey.shade500;
      displayName = name;
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getElementIcon(element), color: iconColor, size: 40),
          const SizedBox(height: 8),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      );
    } else {
      cardColor = Colors.grey.shade200;
      iconColor = Colors.grey.shade400;
      displayName = '???';
      content = Center(child: Icon(Icons.lock, color: iconColor, size: 40));
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Stack(
        children: [
          if (isCaptured || isEncountered)
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                _getElementIcon(element),
                size: 60,
                color: isCaptured
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.5),
              ),
            ),
          Center(child: content),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pokedex')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    const int itemsPerPage = 9;
    final int pageCount = (_allMonsters.length / itemsPerPage).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pokedex',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: _allMonsters.isEmpty
          ? const Center(child: Text('Data Monster Kosong'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoChip(
                        'Dimiliki',
                        _captured.toSet().length,
                        Colors.green,
                      ),
                      _buildInfoChip(
                        'Ditemui',
                        _encountered.toSet().length,
                        Colors.orange,
                      ),
                      _buildInfoChip('Total', _allMonsters.length, Colors.blue),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() {}),
                    itemCount: pageCount,
                    itemBuilder: (context, pageIndex) {
                      final startIndex = pageIndex * itemsPerPage;
                      final endIndex = math.min(
                        startIndex + itemsPerPage,
                        _allMonsters.length,
                      );
                      final pageItems = _allMonsters.sublist(
                        startIndex,
                        endIndex,
                      );

                      return GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: pageItems.length,
                        itemBuilder: (context, index) {
                          final monster = pageItems[index];
                          final String name = monster['name'];
                          final MonsterElement element = monster['element'];

                          final bool isCaptured = _captured.contains(name);
                          final bool isEncountered = _encountered.contains(
                            name,
                          );

                          return _buildPokedexCard(
                            name,
                            element,
                            isCaptured,
                            isEncountered,
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Halaman ${(_pageController.hasClients ? _pageController.page?.round() ?? 0 : 0) + 1} dari $pageCount\nGeser untuk melihat halaman lain',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================================================
// MONSTER BOX SCREEN
// ============================================================================
class MonsterBoxScreen extends StatefulWidget {
  final List<Monster> party;

  const MonsterBoxScreen({super.key, required this.party});

  @override
  State<MonsterBoxScreen> createState() => _MonsterBoxScreenState();
}

class _MonsterBoxScreenState extends State<MonsterBoxScreen> {
  List<Monster> _box = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final box = await SaveManager.loadBox();
    setState(() {
      _box = box;
      _isLoading = false;
    });
  }

  Future<void> _moveToBox(int index) async {
    if (widget.party.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Party harus menyisakan minimal 1 monster!'),
        ),
      );
      return;
    }
    setState(() {
      _box.add(widget.party.removeAt(index));
    });
    await SaveManager.saveParty(widget.party);
    await SaveManager.saveBox(_box);
  }

  Future<void> _moveToParty(int index) async {
    if (widget.party.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Party sudah penuh (Maks 5)!')),
      );
      return;
    }
    setState(() {
      widget.party.add(_box.removeAt(index));
    });
    await SaveManager.saveParty(widget.party);
    await SaveManager.saveBox(_box);
  }

  IconData _getElementIcon(MonsterElement element) {
    switch (element) {
      case MonsterElement.Api:
        return Icons.local_fire_department;
      case MonsterElement.Air:
        return Icons.water_drop;
      case MonsterElement.Tumbuhan:
        return Icons.eco;
      case MonsterElement.Listrik:
        return Icons.bolt;
      case MonsterElement.Tanah:
        return Icons.terrain;
      case MonsterElement.Terbang:
        return Icons.flutter_dash;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Monster Box')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monster Box',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Party (${widget.party.length}/5) - Ketuk untuk simpan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.party.length,
                    itemBuilder: (context, index) {
                      final monster = widget.party[index];
                      return GestureDetector(
                        onTap: () => _moveToBox(index),
                        child: Container(
                          width: 85,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: monster.elementColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getElementIcon(monster.element),
                                color: Colors.white,
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: Text(
                                  monster.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Text(
                                'Lv ${monster.level}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'In Box (${_box.length}) - Ketuk untuk bawa',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _box.isEmpty
                        ? const Center(child: Text('Monster Box Kosong'))
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.8,
                                ),
                            itemCount: _box.length,
                            itemBuilder: (context, index) {
                              final monster = _box[index];
                              return GestureDetector(
                                onTap: () => _moveToParty(index),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: monster.elementColor.withOpacity(
                                      0.8,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _getElementIcon(monster.element),
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                        ),
                                        child: Text(
                                          monster.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      Text(
                                        'Lv ${monster.level}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
