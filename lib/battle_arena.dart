import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:monster_battle_game/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;

part 'battle_ui_ux.dart';
part 'battle_logic.dart';

// 1. MENU BATTLE UTAMA
// ============================================================================
class BattleMenuScreen extends StatefulWidget {
  final List<Monster> party;

  const BattleMenuScreen({super.key, required this.party});

  @override
  State<BattleMenuScreen> createState() => _BattleMenuScreenState();
}

class _BattleMenuScreenState extends State<BattleMenuScreen> {
  // Simulasi kuota pertarungan harian
  int _wildBattlesLeft = 10;

  void _startPvPBattle() {
    if (widget.party.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Party kamu kosong!')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PvPMenuScreen(party: widget.party),
      ),
    );
  }

  void _startWildBattle() {
    if (_wildBattlesLeft > 0) {
      if (widget.party.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Party kamu kosong!')));
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WildBattleArena(
            playerMonster:
                widget.party.first, // Gunakan monster pertama di party
            party: widget.party, // Bawa seluruh party ke pertarungan
            onBattleEnd: (bool won) {
              if (won) {
                // Ketika battle selesai dan menang, kurangi kuota
                // dan perbarui UI saat kembali ke layar ini.
                if (mounted) {
                  setState(() {
                    _wildBattlesLeft--;
                  });
                }
              }
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kuota Wild Battle hari ini sudah habis!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Battle Arena',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Mode Pertarungan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            // Sub Menu: Wild Battle
            GestureDetector(
              onTap: _startWildBattle,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pets,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Wild Battle',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lawan monster liar secara acak.\nSisa hari ini: $_wildBattlesLeft/10',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Sub Menu: PvP Battle
            GestureDetector(
              onTap: _startPvPBattle,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade600, Colors.purple.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PvP Battle',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lawan pemain lain secara online.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Sub Menu: Infinite Tower
            GestureDetector(
              onTap: _startInfiniteTower,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade600, Colors.orange.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_tree,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Infinite Tower',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hadapi 100 trainer dari level 1-100.\nHadiah meningkat seiring level!',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startInfiniteTower() {
    if (widget.party.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Party kamu kosong!')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InfiniteTowerScreen(party: widget.party),
      ),
    );
  }
}

// ============================================================================
// WIDGET UNTUK EFEK TEKS BERJALAN (TYPEWRITER)
// ============================================================================

class PvPMenuScreen extends StatefulWidget {
  final List<Monster> party;

  const PvPMenuScreen({super.key, required this.party});

  @override
  State<PvPMenuScreen> createState() => _PvPMenuScreenState();
}

class _PvPMenuScreenState extends State<PvPMenuScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _createRoom() {
    // 1. Buat kode room 6 digit secara acak
    final roomCode = (Random().nextInt(900000) + 100000).toString();

    // 2. Tampilkan dialog menunggu lawan TERLEBIH DAHULU agar UI tidak "nge-freeze"
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Room Dibuat',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Bagikan kode ini ke temanmu:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                ),
                child: SelectableText(
                  roomCode,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                    letterSpacing: 10,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text(
                'Menunggu lawan bergabung...',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  // Hapus room dari database jika host membatalkan
                  _firestore.collection('rooms').doc(roomCode).delete();
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    // 3. Simpan data room ke Firestore (berjalan di background)
    _firestore
        .collection('rooms')
        .doc(roomCode)
        .set({
          'roomId': roomCode,
          'status': 'waiting',
          'host': {
            'name': widget.party.first.name,
            'hp': widget.party.first.hp,
            'maxHp': widget.party.first.hp,
            'stamina': widget.party.first.stamina,
            'maxStamina': widget.party.first.stamina,
            'level': widget.party.first.level,
            'element': widget.party.first.element.name,
            'attack': widget.party.first.attack,
            'defense': widget.party.first.defense,
            'burnTurns': 0,
            'bindTurns': 0,
            'paralysisTurns': 0,
            'invulnerableTurns': 0,
            'consecutiveAbsorb': 0,
          },
          'createdAt': FieldValue.serverTimestamp(),
        })
        .catchError((error) {
          // Jika gagal nulis ke database, kita print errornya
          print("Gagal membuat room di Firestore: $error");
        });

    // 4. Dengarkan perubahan pada Firestore (apabila Guest masuk)
    StreamSubscription? roomSubscription;
    roomSubscription = _firestore
        .collection('rooms')
        .doc(roomCode)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data()!;
            if (data['status'] == 'playing') {
              roomSubscription
                  ?.cancel(); // Berhenti listen agar tidak double-trigger
              // Lawan masuk!
              if (Navigator.canPop(context)) {
                Navigator.pop(context); // Tutup dialog loading
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lawan ditemukan! Memasuki arena...'),
                ),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PvPBattleArena(
                    roomCode: roomCode,
                    playerMonster: widget.party.first,
                    party: widget.party,
                    isHost: true,
                  ),
                ),
              );
            }
          }
        });
  }

  void _joinRoom() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Gabung Room',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan 6 digit kode dari Host.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final roomCode = _codeController.text;
              if (roomCode.length == 6) {
                // 1. Cek apakah room ada dan statusnya 'waiting'
                final doc = await _firestore
                    .collection('rooms')
                    .doc(roomCode)
                    .get();
                if (doc.exists && doc.data()?['status'] == 'waiting') {
                  // 2. Update status room jadi 'playing' dan masukkan data guest
                  await doc.reference.update({
                    'status': 'playing',
                    'currentTurn': 'host', // Host mendapat giliran pertama
                    'turnCount': 1,
                    'log': 'Pertarungan dimulai! Giliran Host.',
                    'guest': {
                      'name': widget.party.first.name,
                      'hp': widget.party.first.hp,
                      'maxHp': widget.party.first.hp,
                      'stamina': widget.party.first.stamina,
                      'maxStamina': widget.party.first.stamina,
                      'level': widget.party.first.level,
                      'element': widget.party.first.element.name,
                      'attack': widget.party.first.attack,
                      'defense': widget.party.first.defense,
                      'burnTurns': 0,
                      'bindTurns': 0,
                      'paralysisTurns': 0,
                      'invulnerableTurns': 0,
                      'consecutiveAbsorb': 0,
                    },
                  });

                  if (!mounted) return;
                  Navigator.pop(dialogContext); // Tutup dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Berhasil gabung! Memasuki arena...'),
                    ),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PvPBattleArena(
                        roomCode: roomCode,
                        playerMonster: widget.party.first,
                        party: widget.party,
                        isHost: false,
                      ),
                    ),
                  );
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Room tidak ditemukan atau sudah penuh!'),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Gabung Pertarungan'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PvP Battle',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Arena Multiplayer',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tantang temanmu dan buktikan siapa yang terkuat secara online!',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            // Card 1: Buat Room
            GestureDetector(
              onTap: _createRoom,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade600,
                      Colors.deepOrange.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_box_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Buat Room',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Buat arena baru dan bagikan kodemu.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Card 2: Gabung Room
            GestureDetector(
              onTap: _joinRoom,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade500, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sensor_door_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gabung Room',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Masukkan kode dan tantang temanmu.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 4. PVP BATTLE ARENA (REAL-TIME)
// ============================================================================

class InfiniteTowerScreen extends StatefulWidget {
  final List<Monster> party;

  const InfiniteTowerScreen({super.key, required this.party});

  @override
  State<InfiniteTowerScreen> createState() => _InfiniteTowerScreenState();
}

class _InfiniteTowerScreenState extends State<InfiniteTowerScreen> {
  int _highestLevel = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Mulai dari lantai dasar (Index 0 = Level 1)
    _pageController = PageController(initialPage: 0);
    _loadProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highestLevel = prefs.getInt('infinite_tower_progress') ?? 0;
    });

    // Animasi sinematik merangkak naik ke lantai terakhir saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _pageController.hasClients) {
          // 1 Halaman berisi 5 level.
          int targetPage = _highestLevel ~/ 5;
          if (targetPage > 19) {
            targetPage = 19; // Maksimal index 19 (Level 96-100)
          }

          if (targetPage > 0) {
            _pageController.animateToPage(
              targetPage,
              duration: Duration(milliseconds: 1000 + (targetPage * 150)),
              curve: Curves.easeInOutCubic,
            );
          }
        }
      });
    });
  }

  Future<void> _saveProgress(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('infinite_tower_progress', level);
    setState(() {
      _highestLevel = level;
    });
  }

  int _calculateReward(int level) {
    // Hadiah meningkat seiring level: base 100 + 50 per level
    return 100 + (level - 1) * 50;
  }

  Future<void> _startBattle(int level) async {
    if (widget.party.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Party kamu kosong!')));
      return;
    }

    // Generate trainer monster dengan level sesuai
    final trainerParty = await _generateTrainerParty(level);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InfiniteTowerBattleArena(
          playerParty: widget.party,
          trainerParty: trainerParty,
          towerLevel: level,
          onBattleEnd: (won) async {
            if (won) {
              // Jika menang, update progress jika level lebih tinggi
              if (level > _highestLevel) {
                await _saveProgress(level);
              }
              // Berikan hadiah
              final reward = _calculateReward(level);
              _showRewardDialog(reward);
            }
          },
        ),
      ),
    );
  }

  MonsterElement _getElement(String elementStr) {
    if (elementStr == 'Api') return MonsterElement.Api;
    if (elementStr == 'Air') return MonsterElement.Air;
    if (elementStr == 'Listrik') return MonsterElement.Listrik;
    if (elementStr == 'Tanah') return MonsterElement.Tanah;
    if (elementStr == 'Terbang') return MonsterElement.Terbang;
    return MonsterElement.Tumbuhan;
  }

  // Helper function to generate moves (extracted for reusability)
  List<MonsterMove> _generateMonsterMoves(
    MonsterElement element,
    Random random,
  ) {
    List<MonsterMove> moves = [];
    List<String> normalMoveNames = [
      'Pound',
      'Scratch',
      'Tackle',
      'Swift',
      'Strike',
      'Slam',
      'Dash',
      'Hit',
      'Bash',
    ];
    List<String> recoverMoveNames = [
      'Focus',
      'Rest',
      'Meditate',
      'Charge',
      'Gather',
      'Heal',
      'Calm',
    ];
    String randomNormal =
        normalMoveNames[random.nextInt(normalMoveNames.length)];
    String randomRecover =
        recoverMoveNames[random.nextInt(recoverMoveNames.length)];

    moves.add(
      MonsterMove(
        name: randomRecover,
        type: MoveType.recover,
        power: 0,
        cost: -15,
      ),
    );
    moves.add(
      MonsterMove(
        name: randomNormal,
        type: MoveType.normal,
        power: 40,
        cost: -7,
      ),
    );

    switch (element) {
      case MonsterElement.Api:
        List<String> elMoves = [
          'Ember',
          'Fireball',
          'Flame Burst',
          'Heat Wave',
          'Scorcher',
        ];
        List<String> spMoves = [
          'Flame Spin',
          'Fire Spin',
          'Inferno',
          'Burn Blast',
          'Blaze Bind',
        ];
        moves.add(
          MonsterMove(
            name: elMoves[random.nextInt(elMoves.length)],
            type: MoveType.elemental,
            power: 50,
            cost: 10,
          ),
        );
        moves.add(
          MonsterMove(
            name: spMoves[random.nextInt(spMoves.length)],
            type: MoveType.special,
            power: 45,
            effect: 'Burn 3 turn',
            cost: 10,
          ),
        );
        break;
      case MonsterElement.Air:
        List<String> elMoves = [
          'Bubble',
          'Water Gun',
          'Aqua Jet',
          'Splash Hit',
          'Tidal Wave',
        ];
        List<String> spMoves = [
          'Bind',
          'Water Whip',
          'Whirlpool',
          'Aqua Bind',
          'Tsunami Hold',
        ];
        moves.add(
          MonsterMove(
            name: elMoves[random.nextInt(elMoves.length)],
            type: MoveType.elemental,
            power: 45,
            cost: 10,
          ),
        );
        moves.add(
          MonsterMove(
            name: spMoves[random.nextInt(spMoves.length)],
            type: MoveType.special,
            power: 30,
            effect: 'Bind 1 turn',
            cost: 10,
          ),
        );
        break;
      case MonsterElement.Tumbuhan:
        List<String> elMoves = [
          'Vine Whip',
          'Razor Leaf',
          'Seed Bomb',
          'Leaf Strike',
          'Nature Hit',
        ];
        List<String> spMoves = [
          'Absorb',
          'Mega Drain',
          'Leech Seed',
          'Giga Drain',
          'Life Siphon',
        ];
        moves.add(
          MonsterMove(
            name: elMoves[random.nextInt(elMoves.length)],
            type: MoveType.elemental,
            power: 40,
            cost: 10,
          ),
        );
        moves.add(
          MonsterMove(
            name: spMoves[random.nextInt(spMoves.length)],
            type: MoveType.special,
            power: 20,
            effect: 'Drain HP & Heal',
            cost: 10,
          ),
        );
        break;
      case MonsterElement.Listrik:
        List<String> elMoves = [
          'Electric Shock',
          'Thunder Shock',
          'Spark',
          'Lightning Strike',
          'Volt Tackle',
        ];
        List<String> spMoves = [
          'Paralysis',
          'Thunder Wave',
          'Static',
          'Stun Volt',
          'Shock Trap',
        ];
        moves.add(
          MonsterMove(
            name: elMoves[random.nextInt(elMoves.length)],
            type: MoveType.elemental,
            power: 50,
            cost: 10,
          ),
        );
        moves.add(
          MonsterMove(
            name: spMoves[random.nextInt(spMoves.length)],
            type: MoveType.special,
            power: 30,
            effect: 'Paralysis 1 turn',
            cost: 10,
          ),
        );
        break;
      case MonsterElement.Tanah:
        List<String> elMoves = [
          'Rock Tomb',
          'Mud Slap',
          'Rock Throw',
          'Earth Tremor',
          'Sand Attack',
        ];
        List<String> spMoves = [
          'Grounding',
          'Dig',
          'Burrow',
          'Sand Hide',
          'Earth Shield',
        ];
        moves.add(
          MonsterMove(
            name: elMoves[random.nextInt(elMoves.length)],
            type: MoveType.elemental,
            power: 50,
            cost: 10,
          ),
        );
        moves.add(
          MonsterMove(
            name: spMoves[random.nextInt(spMoves.length)],
            type: MoveType.special,
            power: 20,
            effect: 'Miss 2 turn',
            cost: 15,
          ),
        );
        break;
      case MonsterElement.Terbang:
        List<String> elMoves = [
          'Air Cut',
          'Gust',
          'Wind Strike',
          'Aero Slash',
          'Breeze Hit',
        ];
        List<String> spMoves = [
          'Fly Away',
          'Fly',
          'Sky Drop',
          'Cloud Hide',
          'High Hover',
        ];
        moves.add(
          MonsterMove(
            name: elMoves[random.nextInt(elMoves.length)],
            type: MoveType.elemental,
            power: 45,
            cost: 10,
          ),
        );
        moves.add(
          MonsterMove(
            name: spMoves[random.nextInt(spMoves.length)],
            type: MoveType.special,
            power: 40,
            effect: 'Miss 1 turn',
            cost: 15,
          ),
        );
        break;
    }
    return moves;
  }

  Future<List<Monster>> _generateTrainerParty(int level) async {
    final random = Random();
    List<Monster> trainerParty = [];
    List<Map<String, String>> monsterData = [];

    try {
      final String fileData = await rootBundle.loadString(
        'assets/monsters.csv',
      );
      List<String> lines = fileData.split('\n');
      if (lines.isNotEmpty && lines.first.toLowerCase().contains('nama')) {
        lines.removeAt(0);
      }
      lines.removeWhere((line) => line.trim().isEmpty);

      for (String line in lines) {
        List<String> columns = line.split(RegExp(r'[,;]'));
        if (columns.length >= 3) {
          monsterData.add({
            'name': columns[1].replaceAll('"', '').trim(),
            'element': columns[2].replaceAll('"', '').trim(),
          });
        }
      }
    } catch (e) {
      print('Gagal membaca assets/monsters.csv: $e');
      // Fallback if CSV fails
      monsterData.add({'name': 'Fallback Monster', 'element': 'Api'});
      monsterData.add({'name': 'Backup Monster', 'element': 'Air'});
    }

    // Trainer di tower memiliki lebih dari 1 monster (minimal 2, bertambah sesuai level)
    int numberOfMonsters = 2 + (level ~/ 15);
    if (numberOfMonsters > 5) numberOfMonsters = 5; // Maksimal 5 monster

    for (int i = 0; i < numberOfMonsters; i++) {
      Map<String, String> selectedMonsterInfo;
      if (monsterData.isNotEmpty) {
        selectedMonsterInfo = monsterData[random.nextInt(monsterData.length)];
      } else {
        selectedMonsterInfo = {'name': 'Trainer Monster', 'element': 'Api'};
      }

      MonsterElement selectedElement = _getElement(
        selectedMonsterInfo['element']!,
      );
      String monsterName = selectedMonsterInfo['name']!;

      int monsterLevel = max(
        1,
        level + random.nextInt(3) - 1,
      ); // Slight variation around tower level

      int hp = 80 + ((monsterLevel - 1) * 5);
      double attack = 80 + ((monsterLevel - 1) * 3);
      double defense = 70 + ((monsterLevel - 1) * 2.5);
      int speed = 60 + (monsterLevel - 1) * 2;
      int stamina = 50 + (monsterLevel - 1) * 5;

      List<MonsterMove> generatedMoves = _generateMonsterMoves(
        selectedElement,
        random,
      );

      trainerParty.add(
        Monster(
          name: monsterName, // Hanya menggunakan nama monster dari CSV
          element: selectedElement,
          imagePath: 'assets/images/trainer_monster.png', // Placeholder
          hp: hp,
          attack: attack,
          defense: defense,
          speed: speed,
          stamina: stamina,
          level: monsterLevel,
          moves: generatedMoves,
        ),
      );
    }
    return trainerParty;
  }

  void _showRewardDialog(int reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selamat!'),
        content: Text('Kamu mendapatkan $reward koin sebagai hadiah!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Tower'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // Progress Info
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.orange.shade700,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level Tertinggi: $_highestLevel',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Hadapi trainer dari level 1-100!',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tower Levels (Step-based Scrolling / Vertical PageView)
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              // Set true agar Index 0 (Level 1) berada di bawah, dan kita mengusap ke atas
              reverse: true,
              itemCount: 20, // 100 level / 5 = 20 halaman
              itemBuilder: (context, index) {
                return _buildTowerPage(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- BANTUAN RENDER TOWER ---

  Widget _buildTowerPage(int pageIndex) {
    // Tentukan aset gambar berdasarkan pageIndex (1 page = 5 level)
    String imagePath =
        'assets/images/tower_middle.png'; // Default untuk Level 6-95

    if (pageIndex == 0) {
      imagePath = 'assets/images/tower_bottom.png'; // Level 1-5
    } else if (pageIndex == 19) {
      imagePath = 'assets/images/tower_top.png'; // Level 96-100
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade500, // Warna dasar dinding menara
        border: const Border.symmetric(
          // Pilar hitam tebal di pinggir agar terlihat seperti struktur bangunan
          vertical: BorderSide(color: Colors.black87, width: 30),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Latar Belakang Gambar Pagoda/Tower
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback warna jika gambar belum dimasukkan ke folder assets
              return Container(color: Colors.grey.shade800);
            },
          ),
          // Tekstur bayangan batu bata placeholder
          const Opacity(
            opacity: 0.1,
            child: Icon(Icons.grid_4x4, size: 500, color: Colors.black),
          ),

          // 5 Lantai per Halaman
          Column(
            children: List.generate(5, (floorIndex) {
              // Hitung level (Dari atas ke bawah).
              // Misal pageIndex 0.
              // floorIndex 0 (Paling atas layar) -> Lv 5.
              // floorIndex 4 (Paling bawah layar) -> Lv 1.
              int level = (pageIndex * 5) + (5 - floorIndex);
              return Expanded(child: _buildFloorItem(level));
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorItem(int level) {
    final isUnlocked = level <= _highestLevel + 1;
    final isCompleted = level <= _highestLevel;

    // Keamanan jika level melebihi 100
    if (level > 100) return const SizedBox.shrink();

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Garis Pembatas Lantai (Floor base)
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            border: const Border(
              top: BorderSide(color: Colors.grey, width: 2),
              bottom: BorderSide(color: Colors.black, width: 4),
            ),
          ),
        ),

        // Pintu Masuk / Tombol Level
        Padding(
          padding: const EdgeInsets.only(
            bottom: 16.0,
          ), // Berdiri tepat di atas garis lantai
          child: GestureDetector(
            onTap: isUnlocked ? () => _startBattle(level) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 100,
              height: 110, // Ukuran disesuaikan agar 5 pintu muat di layar
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.shade800
                    : isUnlocked
                    ? Colors.blue.shade800
                    : Colors.black87,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
                border: Border.all(
                  color: isUnlocked ? Colors.amber : Colors.grey.shade700,
                  width: isUnlocked ? 3 : 2,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lv.$level',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.white : Colors.white54,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    isCompleted
                        ? Icons.check_circle
                        : isUnlocked
                        ? Icons.flash_on
                        : Icons.lock,
                    color: isUnlocked ? Colors.amber : Colors.white54,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// INFINITE TOWER BATTLE ARENA
// ============================================================================
