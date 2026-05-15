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
      drawer: AppDrawer(
        party: widget.party,
        onPartyUpdated: () => setState(() {}),
      ),
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
              onTap: _startJourney,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.brown.shade600, Colors.brown.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.4),
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
                        Icons.explore_outlined,
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
                            'Journey',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Jelajahi kepulauan Indonesia.\nLawan para trainer di setiap wilayah!',
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

  void _startJourney() {
    if (widget.party.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Party kamu kosong!')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JourneyScreen(party: widget.party),
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
          // Menambahkan waktu kedaluwarsa 24 jam dari sekarang
          'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 24)),
          ),
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

class _IslandData {
  final String name;
  final String description;
  final int startLevel;
  final int endLevel;
  final Color themeColor;
  final List<Offset> nodePositions; // Posisi relatif (0.0 - 1.0) di dalam pulau
  final double mapLeft; // Koordinat global X di map raksasa
  final double mapTop; // Koordinat global Y di map raksasa
  final double mapWidth; // Lebar pulau di map global
  final double mapHeight; // Tinggi pulau di map global

  const _IslandData({
    required this.name,
    required this.description,
    required this.startLevel,
    required this.endLevel,
    required this.themeColor,
    required this.nodePositions,
    required this.mapLeft,
    required this.mapTop,
    required this.mapWidth,
    required this.mapHeight,
  });
}

class JourneyScreen extends StatefulWidget {
  final List<Monster> party;

  const JourneyScreen({super.key, required this.party});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  int _highestLevel = 0;
  final TransformationController _transformationController =
      TransformationController();

  // Data untuk setiap pulau (Urutan dimodifikasi dari Barat ke Timur dengan posisi Absolute)
  final List<_IslandData> _islands = [
    _IslandData(
      name: 'Pulau Sumatera',
      description: 'Hutan sawit yang luas dan pegunungan megah.',
      startLevel: 1,
      endLevel: 15,
      themeColor: Colors.green.shade800,
      mapLeft: 100,
      mapTop: 120,
      mapWidth: 600,
      mapHeight: 700,
      nodePositions: const [
        // Node 16 - 23: Menyusuri pulau secara natural (liukan lembut)
        Offset(0.01, 0.01), // Level 1
        Offset(0.30, 0.10), // Level 2
        Offset(0.10, 0.18), // Level 3
        Offset(0.40, 0.25), // Level 4
        Offset(0.20, 0.30), // Level 5
        Offset(0.45, 0.35), // Level 6 (Banyumas)
        Offset(0.30, 0.50), // Level 7
        Offset(0.61, 0.38), // Level 8 (Naik - Pantura)
        Offset(0.50, 0.50), // Level 9 (Turun - Selatan)
        Offset(0.70, 0.65), // Level 10 (Naik - Jatim Utara)
        Offset(0.40, 0.60), // Level 11 (Turun - Jatim Selatan)
        Offset(0.50, 0.70), // Level 12 (Naik - Bromo/Probolinggo)
        Offset(0.95, 0.70), // Level 13 (Turun - Banyuwangi Selatan)
        Offset(0.60, 0.80), // Level 14 (Ujung Timur)
        Offset(0.80, 0.90), // Level 14 (Ujung Timur)
      ],
    ),
    _IslandData(
      name: 'Pulau Jawa',
      description: 'Area perkotaan modern dan pusat peradaban.',
      startLevel: 16,
      endLevel: 30,
      themeColor: Colors.grey.shade700,
      mapLeft: 550,
      mapTop: 800,
      mapWidth: 700,
      mapHeight: 250,
      // Posisi di-hardcode agar akurat menempel di daratan Pulau Jawa
      nodePositions: const [
        // Node 16 - 23: Menyusuri pulau secara natural (liukan lembut)
        Offset(0.01, 0.18), // Level 16 (Banten)
        Offset(0.12, 0.44), // Level 17 (Tangerang)
        Offset(0.19, 0.55), // Level 18 (Jakarta / Sekitarnya)
        Offset(0.26, 0.46), // Level 19 (Bandung)
        Offset(0.33, 0.40), // Level 20 (Priangan)
        Offset(0.40, 0.68), // Level 21 (Cirebon / Selatan)
        Offset(0.47, 0.42), // Level 22 (Banyumas)
        Offset(0.54, 0.50), // Level 23 (Semarang / Tengah)
        // Node 24 - 30: Gelombang zig-zag natural yang lebih kentara
        Offset(0.61, 0.38), // Level 24 (Naik - Pantura)
        Offset(0.67, 0.56), // Level 25 (Turun - Selatan)
        Offset(0.74, 0.40), // Level 26 (Naik - Jatim Utara)
        Offset(0.71, 0.98), // Level 27 (Turun - Jatim Selatan)
        Offset(0.88, 0.42), // Level 28 (Naik - Bromo/Probolinggo)
        Offset(0.90, 0.70), // Level 29 (Turun - Banyuwangi Selatan)
        Offset(0.98, 0.68), // Level 30 (Ujung Timur)
      ],
    ),
    _IslandData(
      name: 'Pulau Kalimantan',
      description: 'Sungai berkelok dan hutan hujan tropis.',
      startLevel: 31,
      endLevel: 45,
      themeColor: Colors.teal.shade800,
      mapLeft: 850,
      mapTop: 200,
      mapWidth: 600,
      mapHeight: 550,
      // Posisi di-hardcode agar membentuk spiral masuk ke pedalaman hutan/sungai
      nodePositions: const [
        Offset(0.15, 0.80), // Level 31 (Pesisir Barat)
        Offset(0.10, 0.65), // Level 32 (Barat Laut)
        Offset(0.12, 0.30), // Level 33 (Utara)
        Offset(0.20, 0.40), // Level 34 (Timur Laut)
        Offset(0.50, 0.30), // Level 35 (Pesisir Timur)
        Offset(0.70, 0.20), // Level 36 (Tenggara)
        Offset(0.90, 0.10), // Level 37 (Selatan)
        Offset(0.80, 0.30), // Level 38 (Barat Daya)
        Offset(0.63, 0.33), // Level 39 (Mulai masuk pedalaman sungai)
        Offset(0.49, 0.50), // Level 40 (Tengah Barat)
        Offset(0.38, 0.45), // Level 41 (Tengah Utara)
        Offset(0.30, 0.55), // Level 42 (Tengah Timur)
        Offset(0.40, 0.65), // Level 43 (Tengah Selatan)
        Offset(0.55, 0.70), // Level 44 (Pusat Hutan)
        Offset(0.70, 0.62), // Level 45 (Inti Pulau)
      ],
    ),
    _IslandData(
      name: 'Pulau Sulawesi',
      description: 'Kekayaan laut dan area pertambangan.',
      startLevel: 46,
      endLevel: 60,
      themeColor: Colors.blue.shade900,
      mapLeft: 1450,
      mapTop: 300,
      mapWidth: 450,
      mapHeight: 550,
      nodePositions: const [
        Offset(0.10, 0.90), // Level 46 (Pesisir Barat)
        Offset(0.18, 0.80), // Level 47 (Barat Laut)
        Offset(0.12, 0.60), // Level 48 (Utara)
        Offset(0.20, 0.40), // Level 49 (Timur Laut)
        Offset(0.30, 0.68), // Level 50 (Pesisir Timur)
        Offset(0.40, 0.10), // Level 51 (Tenggara)
        Offset(0.60, 0.20), // Level 52 (Selatan)
        Offset(0.90, 0.10), // Level 53 (Barat Daya)
        Offset(0.70, 0.35), // Level 54 (Mulai masuk pedalaman sungai)
        Offset(0.45, 0.28), // Level 55 (Tengah Barat)
        Offset(0.40, 0.40), // Level 56 (Tengah Utara)
        Offset(0.45, 0.55), // Level 57 (Tengah Timur)
        Offset(0.80, 0.82), // Level 58 (Tengah Selatan)
        Offset(0.50, 0.75), // Level 59 (Pusat Hutan)
        Offset(0.65, 0.90), // Level 60 (Inti Pulau)
      ],
    ),
    _IslandData(
      name: 'Kep. Nusa Tenggara',
      description: 'Keindahan seni, budaya, dan pantai eksotis.',
      startLevel: 61,
      endLevel: 75,
      themeColor: Colors.orange.shade800,
      mapLeft: 1300,
      mapTop: 900,
      mapWidth: 900,
      mapHeight: 300,
      // Posisi di-hardcode agar sejajar menyusuri dari Bali sampai NTT
      nodePositions: const [
        // Bali
        Offset(0.05, 0.49), // Level 61
        Offset(0.15, 0.52), // Level 62
        // NTB (Lombok, Sumbawa, Bima)
        Offset(0.20, 0.40), // Level 63
        Offset(0.28, 0.45), // Level 64
        Offset(0.25, 0.80), // Level 65
        Offset(0.35, 0.31), // Level 66
        Offset(0.40, 0.50), // Level 67
        Offset(0.50, 0.45), // Level 68
        // NTT (Flores, Komodo, Sumba, Timor)
        Offset(0.50, 0.90), // Level 69
        Offset(0.60, 0.80), // Level 70
        Offset(0.62, 0.60), // Level 71
        Offset(0.65, 0.30), // Level 72
        Offset(0.80, 0.30), // Level 73
        Offset(0.88, 0.35), // Level 74
        Offset(1.00, 0.42), // Level 75
      ],
    ),
    _IslandData(
      name: 'Pulau Papua',
      description: 'Rumah bagi biodiversitas dan satwa liar.',
      startLevel: 76,
      endLevel: 100,
      themeColor: Colors.red.shade900,
      mapLeft: 2270,
      mapTop: 410,
      mapWidth: 515,
      mapHeight: 800,
      nodePositions: const [
        // Papua
        Offset(0.12, 0.72), // Level 76
        Offset(0.25, 0.62), // Level 77
        Offset(0.05, 0.10), // Level 78
        Offset(0.20, 0.20), // Level 79
        Offset(0.38, 0.18), // Level 80
        Offset(0.35, 0.31), // Level 81
        Offset(0.23, 0.40), // Level 82
        Offset(0.35, 0.45), // Level 83
        Offset(0.60, 0.40), // Level 84
        Offset(0.50, 0.30), // Level 85
        Offset(0.55, 0.20), // Level 86
        Offset(0.80, 0.30), // Level 87
        Offset(0.60, 0.50), // Level 88
        Offset(0.55, 0.65), // Level 89
        Offset(0.60, 0.50), // Level 90
        Offset(0.90, 0.65), // Level 91
        Offset(0.80, 0.75), // Level 92
        Offset(0.75, 0.60), // Level 93
        Offset(0.55, 0.75), // Level 94
        Offset(0.70, 0.80), // Level 95
        Offset(0.90, 0.90), // Level 96
        Offset(0.75, 0.95), // Level 97
        Offset(0.50, 0.80), // Level 98
        Offset(0.44, 0.90), // Level 99
        Offset(0.38, 0.85), // Level 100
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    int progress = prefs.getInt('infinite_tower_progress') ?? 0;
    if (!mounted) return;
    setState(() => _highestLevel = progress);

    // Auto-focus kamera (pan) ke pulau yang sedang aktif
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int islandIndex = _islands.indexWhere(
        (i) => progress >= i.startLevel - 1 && progress < i.endLevel,
      );
      if (islandIndex == -1 && progress >= _islands.last.endLevel) {
        islandIndex = _islands.length - 1;
      }
      if (islandIndex >= 0) {
        final activeIsland = _islands[islandIndex];
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        final double targetX =
            activeIsland.mapLeft +
            (activeIsland.mapWidth / 2) -
            (screenWidth / 2);
        final double targetY =
            activeIsland.mapTop +
            (activeIsland.mapHeight / 2) -
            (screenHeight / 2);

        _transformationController.value = Matrix4.identity()
          ..translate(-targetX, -targetY);
      }
    });
  }

  Future<void> _saveProgress(int level) async {
    await SaveManager.saveTowerProgress(level);
    if (mounted) setState(() => _highestLevel = level);
  }

  Future<void> _startBattle(int level, _IslandData island) async {
    if (widget.party.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Party kamu kosong!')));
      return;
    }

    final trainerParty = await _generateTrainerParty(level, island.name);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JourneyBattleArena(
          playerParty: widget.party,
          trainerParty: trainerParty,
          towerLevel:
              level, // Tetap gunakan nama 'towerLevel' untuk reusabilitas
          onBattleEnd: (won) async {
            if (won) {
              if (level > _highestLevel) {
                await _saveProgress(level);
              }
            }
          },
        ),
      ),
    );
  }

  MonsterElement _getElementFromString(String elementStr) {
    if (elementStr == 'Api') return MonsterElement.Api;
    if (elementStr == 'Air') return MonsterElement.Air;
    if (elementStr == 'Listrik') return MonsterElement.Listrik;
    if (elementStr == 'Tanah') return MonsterElement.Tanah;
    if (elementStr == 'Terbang') return MonsterElement.Terbang;
    return MonsterElement.Tumbuhan;
  }

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
    String randomNormal =
        normalMoveNames[random.nextInt(normalMoveNames.length)];

    moves.add(
      const MonsterMove(
        name: 'Focus', // Beri jurus pemulih SP standar
        type: MoveType.recover,
        power: 0,
        cost: -15,
      ),
    );
    // Tambahkan kartu Heal dengan peluang tertentu
    if (random.nextInt(3) == 0) {
      // Peluang 33% untuk punya Heal, agar trainer sedikit lebih menantang
      moves.add(
        const MonsterMove(
          name: 'Heal',
          type: MoveType.recover,
          power: 15,
          cost: 0,
        ),
      );
    }
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

  Future<List<Monster>> _generateTrainerParty(
    int level,
    String islandName,
  ) async {
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

    int numberOfMonsters = 2 + (level ~/ 15);
    if (numberOfMonsters > 5) numberOfMonsters = 5; // Maksimal 5 monster

    for (int i = 0; i < numberOfMonsters; i++) {
      // TODO: Filter monsterData based on islandName for thematic enemies
      Map<String, String> selectedMonsterInfo;
      if (monsterData.isNotEmpty) {
        selectedMonsterInfo = monsterData[random.nextInt(monsterData.length)];
      } else {
        selectedMonsterInfo = {'name': 'Trainer Monster', 'element': 'Api'};
      }

      MonsterElement selectedElement = _getElementFromString(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Journey: Nusantara',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFF1E3A8A), // Warna biru samudra
        child: InteractiveViewer(
          constrained: false,
          transformationController: _transformationController,
          minScale: 0.4, // Sedikit diperbesar agar tidak terlalu kecil di layar
          maxScale: 2.0,
          boundaryMargin: EdgeInsets
              .zero, // Batas pas ke ukuran gambar map, tidak bisa geser ke luar
          child: SizedBox(
            width: 2800,
            height: 1400,
            child: Stack(
              children: [
                // 1. Gambar Peta Full Nusantara (Satu Kesatuan)
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/map_nusantara_full.png', // Ganti dengan nama aset map utuhmu
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.red.shade200,
                        alignment: Alignment.center,
                        child: const Text(
                          'Gambar tidak ditemukan!\nPastikan nama file dan foldernya persis:\nassets/images/map_nusantara_full.png',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Path / Garis Antar Pulau
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PathPainter(
                      islandCount: _islands.length,
                      progress: _highestLevel,
                      islands: _islands,
                    ),
                  ),
                ),
                // Area Virtual dan Overlay Node Levelnya
                ..._islands.map((island) => _buildIslandWidget(island)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIslandWidget(_IslandData island) {
    return Positioned(
      left: island.mapLeft,
      top: island.mapTop,
      width: island.mapWidth,
      height: island.mapHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // --- BANTUAN GRID DEBUG (Bisa Dihapus Nanti) ---
              // Positioned.fill(
              //   child: CustomPaint(painter: _IslandGridPainter()),
              // ),
              // -----------------------------------------------
              ...List.generate(island.endLevel - island.startLevel + 1, (
                index,
              ) {
                int level = island.startLevel + index;
                Offset position = island.nodePositions[index];
                return Positioned(
                  left:
                      constraints.maxWidth * position.dx -
                      20, // Offset ke tengah node
                  top: constraints.maxHeight * position.dy - 20,
                  child: _buildStageNode(level, island),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStageNode(int level, _IslandData island) {
    final isUnlocked = level <= _highestLevel + 1;
    final isCompleted = level <= _highestLevel;

    return GestureDetector(
      onTap: isUnlocked ? () => _startBattle(level, island) : null,
      child: Tooltip(
        message: isUnlocked
            ? "Tantang Stage $level"
            : "Selesaikan stage sebelumnya",
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.amber
                : isUnlocked
                ? Colors.redAccent
                : Colors.black54,
            border: Border.all(
              color: isUnlocked ? Colors.white : Colors.grey.shade700,
              width: 2,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.7),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: isUnlocked
                ? Text(
                    '$level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, color: Colors.white70, size: 12),
                      Text(
                        '$level',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final int islandCount;
  final int progress;
  final List<_IslandData> islands;

  _PathPainter({
    required this.islandCount,
    required this.progress,
    required this.islands,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final completedPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    // Gambar path DI DALAM tiap pulau
    for (int i = 0; i < islandCount; i++) {
      final island = islands[i];
      for (int j = 0; j < island.nodePositions.length - 1; j++) {
        final startX =
            island.mapLeft + (island.mapWidth * island.nodePositions[j].dx);
        final startY =
            island.mapTop + (island.mapHeight * island.nodePositions[j].dy);
        final endX =
            island.mapLeft + (island.mapWidth * island.nodePositions[j + 1].dx);
        final endY =
            island.mapTop + (island.mapHeight * island.nodePositions[j + 1].dy);

        int currentLevel = island.startLevel + j;
        if (progress >= currentLevel) {
          _drawDashedLine(
            canvas,
            Offset(startX, startY),
            Offset(endX, endY),
            completedPaint,
          );
        } else {
          _drawDashedLine(
            canvas,
            Offset(startX, startY),
            Offset(endX, endY),
            paint,
          );
        }
      }
    }

    // Gambar path ANTAR pulau (Dashed line / putus-putus)
    for (int i = 0; i < islandCount - 1; i++) {
      final island1 = islands[i];
      final island2 = islands[i + 1];

      final startX =
          island1.mapLeft + (island1.mapWidth * island1.nodePositions.last.dx);
      final startY =
          island1.mapTop + (island1.mapHeight * island1.nodePositions.last.dy);
      final endX =
          island2.mapLeft + (island2.mapWidth * island2.nodePositions.first.dx);
      final endY =
          island2.mapTop + (island2.mapHeight * island2.nodePositions.first.dy);

      if (progress >= island1.endLevel) {
        _drawDashedLine(
          canvas,
          Offset(startX, startY),
          Offset(endX, endY),
          completedPaint,
        );
      } else {
        _drawDashedLine(
          canvas,
          Offset(startX, startY),
          Offset(endX, endY),
          paint,
        );
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 10.0;
    const double dashSpace = 8.0;
    final double distance = (p2 - p1).distance;
    double currentDistance = 0.0;

    while (currentDistance < distance) {
      final double remain = distance - currentDistance;
      final double end =
          currentDistance + (dashWidth > remain ? remain : dashWidth);

      final Offset startPoint = Offset.lerp(
        p1,
        p2,
        currentDistance / distance,
      )!;
      final Offset endPoint = Offset.lerp(p1, p2, end / distance)!;

      canvas.drawLine(startPoint, endPoint, paint);
      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============================================================================
// DEBUG GRID PAINTER (BISA DIHAPUS NANTI JIKA SUDAH SELESAI)
// ============================================================================
class _IslandGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final borderPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Gambar kotak merah batas wilayah pulau
    canvas.drawRect(Offset.zero & size, borderPaint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Gambar grid 10x10 dengan jarak 0.1
    for (int i = 1; i < 10; i++) {
      double val = i / 10;
      double dx = size.width * val;
      double dy = size.height * val;

      // Garis Vertikal (Sumbu X) dan Garis Horizontal (Sumbu Y)
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), linePaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), linePaint);

      // Teks Angka X (Kuning)
      textPainter.text = TextSpan(
        text: 'x:${val.toStringAsFixed(1)}',
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black45,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(dx + 2, 4));

      // Teks Angka Y (Hijau)
      textPainter.text = TextSpan(
        text: 'y:${val.toStringAsFixed(1)}',
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black45,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, dy + 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// INFINITE TOWER BATTLE ARENA
// ============================================================================

class JourneyBattleArena extends StatefulWidget {
  final List<Monster> playerParty;
  final List<Monster> trainerParty;
  final int towerLevel;
  final Function(bool won) onBattleEnd;

  const JourneyBattleArena({
    super.key,
    required this.playerParty,
    required this.trainerParty,
    required this.towerLevel,
    required this.onBattleEnd,
  });

  @override
  State<JourneyBattleArena> createState() => _JourneyBattleArenaState();
}

class _JourneyBattleArenaState extends State<JourneyBattleArena>
    with TickerProviderStateMixin, BattleSharedMixin<JourneyBattleArena> {
  late Monster _activeMonster;
  late Monster _activeEnemyMonster; // Monster musuh yang sedang aktif

  final Map<Monster, int> _partyHp = {};
  final Map<Monster, int> _partyStamina = {};
  late List<Monster> _trainerParty; // Party monster trainer
  final Map<Monster, int> _trainerPartyHp = {};

  // Status HP & Stamina
  late int _playerHp, _enemyHp;
  late int _oldPlayerHp, _oldEnemyHp; // Untuk animasi bar HP
  late int _playerStamina, _enemyStamina;

  // Sistem Kartu (Deck)
  final List<MonsterMove> _currentCards = [];
  bool _isPlayerTurn = true;
  bool _isSwitchMode = false;
  String _battleLog = "";

  // Animasi
  late AnimationController _cardAnimationController;
  late Animation<double> _cardAnimation;
  late AnimationController _clashController;
  late AnimationController _playerShakeController;
  late AnimationController _enemyShakeController;

  int _playerDamageValue = 0;
  int _enemyDamageValue = 0;

  // Efek Spesial
  int _enemyBurnTurns = 0;
  int _enemyBindTurns = 0;
  int _playerBurnTurns = 0;
  int _playerBindTurns = 0;
  int _playerInvulnerableTurns = 0;
  int _enemyInvulnerableTurns = 0;
  int _playerParalysisTurns = 0;
  int _enemyParalysisTurns = 0;

  // Cooldown
  int _turnCount = 1;
  int _lastSpecialCardTurn = -14;
  int _enemyLastSpecialTurn = -14;
  int _playerConsecutiveAbsorb = 0;
  int _enemyConsecutiveAbsorb = 0;
  int _currentGold = 0; // Gold pemain

  void _syncPartyStats() {
    _partyHp[_activeMonster] = _playerHp;
    _partyStamina[_activeMonster] = _playerStamina;
  }

  @override
  void initState() {
    super.initState();
    _activeMonster = widget.playerParty.first;
    for (var m in widget.playerParty) {
      _partyHp[m] = m.hp;
      _partyStamina[m] = m.stamina;
    }

    _trainerParty = widget.trainerParty;
    for (var m in _trainerParty) {
      _trainerPartyHp[m] = m.hp;
    }

    _activeEnemyMonster = _trainerParty.first;
    _playerHp = _partyHp[_activeMonster]!;
    _enemyHp = _trainerPartyHp[_activeEnemyMonster]!;
    _oldPlayerHp = _playerHp;
    _oldEnemyHp = _enemyHp;
    _playerStamina = _partyStamina[_activeMonster]!;
    _enemyStamina = _activeEnemyMonster.stamina;
    _battleLog = "Pertarungan Stage ${widget.towerLevel} dimulai!";

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _clashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _playerShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _enemyShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOut,
    );
    _cardAnimationController.forward();
    _clashController.forward();
    _drawCards();
    _loadGold(); // Muat jumlah gold saat arena terbuka
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _clashController.dispose();
    _playerShakeController.dispose();
    _enemyShakeController.dispose();
    super.dispose();
  }

  // Fungsi untuk memuat jumlah gold dari memori internal
  Future<void> _loadGold() async {
    _currentGold = await SaveManager.loadGold();
  }

  // Fungsi untuk menyimpan sisa gold ke memori internal
  Future<void> _saveGold() async {
    await SaveManager.saveGold(_currentGold);
  }

  void _drawCards() {
    final random = Random();
    final moves = _activeMonster.moves;
    _currentCards.clear();

    final specialMoves = moves
        .where((m) => m.type == MoveType.special)
        .toList();

    if (specialMoves.isNotEmpty && (_turnCount - _lastSpecialCardTurn) >= 15) {
      _currentCards.add(specialMoves[random.nextInt(specialMoves.length)]);
      _lastSpecialCardTurn = _turnCount;
    }

    // Buat "dek" dari semua kartu non-spesial yang belum ada di tangan
    List<MonsterMove> deck = moves
        .where((m) => m.type != MoveType.special && !_currentCards.contains(m))
        .toList();
    deck.shuffle();

    // Isi sisa tangan dari "dek"
    while (_currentCards.length < 3 && deck.isNotEmpty) {
      _currentCards.add(deck.removeAt(0));
    }

    _currentCards.shuffle();
  }

  Map<String, dynamic> _calculateDamage(
    Monster attacker,
    Monster defender,
    MonsterMove move, {
    int defenderBindTurns = 0,
    int defenderBurnTurns = 0,
    int defenderInvulnerableTurns = 0,
  }) {
    if (defenderInvulnerableTurns > 0 && move.type != MoveType.recover) {
      return {'damage': 0, 'log': ' Serangan meleset (Invulnerable)!'};
    }

    final random = Random();

    if (defender.element == MonsterElement.Terbang &&
        random.nextInt(100) < 10 &&
        move.type != MoveType.recover) {
      return {
        'damage': 0,
        'log': ' Serangan berhasil dihindari (Evasiveness)!',
      };
    }

    MonsterElement? moveElement;
    if (move.type == MoveType.elemental || move.type == MoveType.special) {
      moveElement = attacker.element;
    }

    if (moveElement != null && _isNoEffect(moveElement, defender.element)) {
      return {'damage': 0, 'log': ' Tidak ada efek pada tipe ini!'};
    }

    double typeModifier = 1.0;
    String typeLog = "";
    if (moveElement != null) {
      if (_isSuperEffective(moveElement, defender.element)) {
        typeModifier = 2.0;
        typeLog = " Super Efektif!";
      } else if (_isNotVeryEffective(moveElement, defender.element)) {
        typeModifier = 1.25;
        typeLog = " Kurang Efektif...";
      } else if (moveElement == defender.element) {
        typeModifier = 1.5;
        typeLog = " Efektif.";
      }
    }

    double stabModifier = 1.0;
    if (moveElement != null && moveElement == attacker.element) {
      stabModifier = 1.5;
    }

    double critModifier = 1.0;
    bool isCritical = random.nextInt(100) < 10;
    if (isCritical) {
      critModifier = 1.5;
    }

    double randomModifier = 0.85 + random.nextDouble() * 0.15;

    double effectiveDefense = defender.defense;
    if (defenderBindTurns > 0) {
      effectiveDefense *= 0.9;
    }

    double baseDamage =
        (((2 * attacker.level / 5 + 2) *
                move.power *
                (attacker.attack / effectiveDefense)) /
            40) +
        2;

    double finalDamageDouble =
        baseDamage *
        typeModifier *
        stabModifier *
        critModifier *
        randomModifier;

    if (defenderBurnTurns > 0 && move.type == MoveType.elemental) {
      finalDamageDouble *= 1.1;
      typeLog += " (+10% DMG Burn!)";
      if (moveElement == MonsterElement.Api) {
        finalDamageDouble += 2;
        typeLog += " (+2 DMG Api)";
      }
    }

    String critLog = isCritical ? " Serangan Kritis!" : "";

    return {'damage': finalDamageDouble.floor(), 'log': typeLog + critLog};
  }

  void _checkPlayerFaint() {
    bool hasAliveMonster = widget.playerParty.any((m) => _partyHp[m]! > 0);
    if (hasAliveMonster) {
      setState(() {
        // Menggunakan setState untuk memastikan UI terupdate
        _battleLog =
            "${_activeMonster.name} kehabisan tenaga! Pilih monster pengganti.";
        _isSwitchMode = true;
        _isPlayerTurn = true;
      });
    } else {
      _showEndGameDialog(false);
    } // Jika tidak ada monster yang hidup, game berakhir
  }

  void _switchMonster(Monster newMonster) {
    if (!_isPlayerTurn) return;
    if (newMonster == _activeMonster) return;
    if (_partyHp[newMonster]! <= 0) return;

    bool isFaintSwitch = _playerHp <= 0;

    setState(() {
      _syncPartyStats();

      _activeMonster = newMonster;
      _playerHp = _partyHp[_activeMonster]!;
      _oldPlayerHp = _playerHp;
      _playerStamina = _partyStamina[_activeMonster]!;
      _oldEnemyHp = _enemyHp;

      _isSwitchMode = false;
      _battleLog = "Kamu mengeluarkan ${_activeMonster.name}!";

      _drawCards();
    });

    if (isFaintSwitch) {
      setState(() {
        _turnCount++;
      });
      _cardAnimationController.forward(from: 0.0);
    } else {
      setState(() {
        _isPlayerTurn = false;
      });
      _enemyTurn(); // Switch manual menghanguskan 1 giliran
    }
  }

  void _playTurn(MonsterMove move) {
    if (!_isPlayerTurn) return;

    if (_playerInvulnerableTurns > 0) {
      _playerInvulnerableTurns--;
    }

    if (_playerBindTurns > 0 || _playerParalysisTurns > 0) {
      setState(() {
        if (_playerBindTurns > 0) {
          _playerBindTurns--;
          _battleLog = "Kamu tak bisa gerak karena Terikat!";
        } else {
          _playerParalysisTurns--;
          _battleLog = "Kamu tak bisa gerak karena Paralysis!";
        }
        _isPlayerTurn = false;
      });
      _enemyTurn();
      return;
    }

    String statusLog = "";
    if (_playerBurnTurns > 0) {
      setState(() {
        _oldPlayerHp = _playerHp;
        _playerHp = max(0, _playerHp - 5);
        _syncPartyStats();
        _playerBurnTurns--;
        statusLog = "Kamu terkena 5 damage Burn! ";
      });
      if (_playerHp == 0) {
        _checkPlayerFaint();
        return;
      }
    }

    if (move.name == 'Absorb' || move.effect == 'Drain HP & Heal') {
      _playerConsecutiveAbsorb++;
    } else {
      _playerConsecutiveAbsorb = 0;
    }

    if (move.cost > _playerStamina) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stamina tidak cukup!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (move.type == MoveType.recover) {
      if (move.name == 'Heal') {
        setState(() {
          _oldPlayerHp = _playerHp;
          _playerHp = min(_activeMonster.hp, _playerHp + 15);
          _syncPartyStats();
          _battleLog = "${_activeMonster.name} memulihkan 15 HP!";
          _isPlayerTurn = false;
        });
      } else {
        setState(() {
          _playerStamina = min(
            _activeMonster.stamina,
            _playerStamina - move.cost,
          );
          _syncPartyStats();
          _battleLog = "Fokus & pulihkan ${-move.cost} SP!";
          _isPlayerTurn = false;
        });
      }
      _enemyTurn();
      return;
    }

    setState(() {
      _isPlayerTurn = false;
      _playerStamina = min(_activeMonster.stamina, _playerStamina - move.cost);
      _syncPartyStats();

      final damageResult = _calculateDamage(
        // Menggunakan _activeEnemyMonster
        _activeMonster,
        _activeEnemyMonster,
        move,
        defenderBindTurns: _enemyBindTurns,
        defenderBurnTurns: _enemyBurnTurns,
        defenderInvulnerableTurns: _enemyInvulnerableTurns,
      );
      int damage = damageResult['damage'];
      String elementalLog = damageResult['log'];

      String effectLog = "";
      if (move.name == 'Flame Spin' || move.effect == 'Burn 3 turn') {
        _enemyBurnTurns = 3;
        effectLog = " Musuh Burn!";
      } else if (move.name == 'Bind' || move.effect == 'Bind 1 turn') {
        _enemyBindTurns = 1;
        effectLog = " Musuh Terikat!";
      } else if (move.name == 'Paralysis' ||
          move.effect == 'Paralysis 1 turn') {
        _enemyParalysisTurns = 1;
        effectLog = " Musuh Paralysis!";
      } else if (move.name == 'Grounding' || move.effect == 'Miss 2 turn') {
        _playerInvulnerableTurns = 2;
        effectLog = " Sembunyi 2 Turn!";
      } else if (move.name == 'Fly Away' || move.effect == 'Miss 1 turn') {
        _playerInvulnerableTurns = 1;
        effectLog = " Terbang 1 Turn!";
      } else if (move.name == 'Absorb' || move.effect == 'Drain HP & Heal') {
        int combo = min(_playerConsecutiveAbsorb, 3);
        int bonus = (combo - 1) * 2;
        damage += bonus;
        int healAmount = damage;
        _playerHp = min(_activeMonster.hp, _playerHp + healAmount);
        _syncPartyStats();
        effectLog = " Serap $healAmount HP!";
      }
      if (move.cost < 0 && move.type != MoveType.recover) {
        effectLog += " Pulih ${-move.cost} SP!";
      }

      _enemyDamageValue = damage;
      _oldEnemyHp = _enemyHp; // Simpan HP lama untuk animasi
      _enemyHp = max(0, _enemyHp - damage);
      if (damage > 0) _enemyShakeController.forward(from: 0.0);

      _battleLog =
          "$statusLog${_activeMonster.name} pakai ${move.name}!$elementalLog$effectLog";
    });

    if (_enemyHp == 0) {
      // Cek apakah monster musuh yang aktif mati
      _showEndGameDialog(true);
      return;
    }
    _enemyTurn();
  }

  void _enemyTurn() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        String statusLog = "";
        // Handle status efek pada musuh yang aktif
        if (_enemyInvulnerableTurns > 0) _enemyInvulnerableTurns--;

        if (_enemyBurnTurns > 0) {
          _enemyHp = max(0, _enemyHp - 5); // Damage dari burn
          _enemyBurnTurns--;
          statusLog = "Trainer kena 5 DMG Burn! ";
        }
        if (_enemyHp == 0) {
          // Jika monster musuh yang aktif mati karena burn
          _battleLog = "${statusLog}Trainer kehabisan HP!";
          _showEndGameDialog(true);
          return;
        }
        if (_enemyBindTurns > 0 || _enemyParalysisTurns > 0) {
          if (_enemyBindTurns > 0) {
            _enemyBindTurns--;
            _battleLog = "${statusLog}Trainer Terikat!";
          } else {
            _enemyParalysisTurns--;
            _battleLog = "${statusLog}Trainer Paralysis!";
          }
          _nextPlayerTurn();
          return;
        }

        // Jika monster musuh yang aktif mati, coba ganti
        if (_enemyHp <= 0) {
          _trainerPartyHp[_activeEnemyMonster] =
              0; // Pastikan HP di party terupdate
          Monster? nextMonster = _trainerParty
              .where((m) => _trainerPartyHp[m]! > 0)
              .firstOrNull;

          if (nextMonster != null) {
            _activeEnemyMonster = nextMonster;
            _enemyHp = _trainerPartyHp[_activeEnemyMonster]!;
            _enemyStamina = _activeEnemyMonster.stamina;
            _battleLog = "Trainer mengeluarkan ${_activeEnemyMonster.name}!";
            _nextPlayerTurn(); // Langsung giliran pemain setelah switch
            return;
          }
        }

        MonsterMove? chosenMove;
        final random = Random();
        var affordableMoves = _activeEnemyMonster
            .moves // Menggunakan _activeEnemyMonster
            .where((m) => m.cost <= _enemyStamina)
            .toList();

        if ((_turnCount - _enemyLastSpecialTurn) < 15) {
          affordableMoves.removeWhere((m) => m.type == MoveType.special);
        }

        if (affordableMoves.isNotEmpty) {
          Map<MonsterMove, double> moveScores = {};
          bool isPlayerWeak = _isSuperEffective(
            _activeEnemyMonster.element, // Menggunakan _activeEnemyMonster
            _activeMonster.element,
          );

          for (var move in affordableMoves) {
            double score = 0;
            switch (move.type) {
              case MoveType.elemental:
                score = isPlayerWeak ? 3.0 : 1.0;
                break;
              case MoveType.special:
                score = 1.0;
                break;
              case MoveType.normal:
                score = 0.5;
                break;
              case MoveType.recover:
                if (move.name == 'Heal') {
                  // Heal is valuable when HP is low
                  if (_enemyHp < _activeEnemyMonster.hp * 0.5) {
                    score = 3.0; // Very high score to force healing
                  } else {
                    score = -1.0; // Avoid healing with high HP
                  }
                } else {
                  // Recover is only valuable when stamina is low
                  if (_enemyStamina < _activeEnemyMonster.stamina * 0.4) {
                    score = 2.5; // High score to force recovery
                  } else {
                    score = -1.0; // Avoid recovering with high stamina
                  }
                }
                break;
            }
            moveScores[move] = score + (random.nextDouble() * 0.5);
          }

          if (moveScores.isNotEmpty) {
            final bestMoveEntry = moveScores.entries.reduce(
              (a, b) => a.value > b.value ? a : b,
            );
            chosenMove = bestMoveEntry.key;
          }
        }

        if (chosenMove != null) {
          if (chosenMove.type == MoveType.special) {
            _enemyLastSpecialTurn = _turnCount;
          }
          if (chosenMove.name == 'Absorb' ||
              chosenMove.effect == 'Drain HP & Heal') {
            _enemyConsecutiveAbsorb++; // Lacak absorb musuh
          } else {
            _enemyConsecutiveAbsorb = 0;
          }

          _enemyStamina = min(
            // Update stamina musuh
            _activeEnemyMonster.stamina,
            _enemyStamina - chosenMove.cost,
          );

          if (chosenMove.type == MoveType.recover) {
            if (chosenMove.name == 'Heal') {
              _oldEnemyHp = _enemyHp;
              _enemyHp = min(_activeEnemyMonster.hp, _enemyHp + 15);
              _battleLog =
                  "$statusLog${_activeEnemyMonster.name} memulihkan 15 HP!";
            } else {
              _battleLog =
                  "${statusLog}Trainer pulihkan ${-chosenMove.cost} SP!";
            }
          } else {
            final damageResult = _calculateDamage(
              _activeEnemyMonster, // Menggunakan _activeEnemyMonster
              _activeMonster,
              chosenMove,
              defenderBindTurns: _playerBindTurns,
              defenderBurnTurns: _playerBurnTurns,
              defenderInvulnerableTurns: _playerInvulnerableTurns,
            );
            int enemyDamage = damageResult['damage'];
            String elementalLog = damageResult['log'];

            String effectLog = "";
            if (chosenMove.name == 'Flame Spin' ||
                chosenMove.effect == 'Burn 3 turn') {
              _playerBurnTurns = 3;
              effectLog = " Kamu Burn!";
            } else if (chosenMove.name == 'Bind' ||
                chosenMove.effect == 'Bind 1 turn') {
              _playerBindTurns = 1;
              effectLog = " Kamu Terikat!";
            } else if (chosenMove.name == 'Paralysis' ||
                chosenMove.effect == 'Paralysis 1 turn') {
              _playerParalysisTurns = 1;
              effectLog = " Kamu Paralysis!";
            } else if (chosenMove.name == 'Grounding' ||
                chosenMove.effect == 'Miss 2 turn') {
              _enemyInvulnerableTurns = 2;
              effectLog = " Musuh Sembunyi!";
            } else if (chosenMove.name == 'Fly Away' ||
                chosenMove.effect == 'Miss 1 turn') {
              _enemyInvulnerableTurns = 1;
              effectLog = " Musuh Terbang!";
            } else if (chosenMove.name == 'Absorb' ||
                chosenMove.effect == 'Drain HP & Heal') {
              int combo = min(_enemyConsecutiveAbsorb, 3);
              int bonus = (combo - 1) * 2;
              enemyDamage += bonus;
              int healAmount = enemyDamage; // Heal disesuaikan dengan damage
              _oldEnemyHp = _enemyHp; // Simpan HP lama untuk animasi
              _enemyHp = min(
                _activeEnemyMonster.hp,
                _enemyHp + healAmount,
              ); // Menggunakan _activeEnemyMonster
              effectLog = " Musuh serap $healAmount HP!";
            }
            if (chosenMove.cost < 0 && chosenMove.type != MoveType.recover) {
              effectLog += " Musuh pulih ${-chosenMove.cost} SP!";
            }

            _playerDamageValue = enemyDamage;
            _oldPlayerHp = _playerHp;
            _playerHp = max(0, _playerHp - enemyDamage);
            _syncPartyStats();
            if (enemyDamage > 0) _playerShakeController.forward(from: 0.0);

            _battleLog =
                "${statusLog}Trainer pakai ${chosenMove.name}!$elementalLog$effectLog";
          }
        } else {
          _enemyStamina = min(
            _activeEnemyMonster.stamina,
            _enemyStamina + 2,
          ); // Menggunakan _activeEnemyMonster
          _battleLog = "${statusLog}Trainer istirahat!";
        }
      });

      if (_playerHp == 0) {
        _checkPlayerFaint();
      } else {
        _nextPlayerTurn();
      }
    });
  }

  void _nextPlayerTurn() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _turnCount++;
        _isPlayerTurn = true;
        _battleLog = "Giliran kamu! Pilih kartu serangan.";
        _drawCards();
        _cardAnimationController.forward(from: 0.0);
      });
    });
  }

  void _showEndGameDialog(bool won) {
    widget.onBattleEnd(won);

    // Simpan semua monster yang dilawan ke Pokedex (Encountered) setelah battle selesai
    for (var m in widget.trainerParty) {
      SaveManager.saveEncounteredMonster(m.name.trim());
    }

    final random = Random();
    int baseExp = 20 + random.nextInt(30);
    int baseGold = 10 + random.nextInt(20);

    // Reward 2x lipat dari Wild Battle karena lebih sulit + bonus level tower
    int exp = won ? (baseExp * 2) + (widget.towerLevel * 2) : 5;
    int gold = won ? (baseGold * 2) + (widget.towerLevel * 2) : 0;

    _currentGold += gold;

    List<Map<String, num>> allLevelUps = [];
    int initialLevel = _activeMonster.level;

    // Logika penambahan EXP dan Level Up
    // Hanya monster yang aktif yang mendapatkan EXP
    if (won) {
      _activeMonster.currentExp += exp;
      while (_activeMonster.currentExp >= _activeMonster.expToNextLevel) {
        int remainingExp =
            _activeMonster.currentExp - _activeMonster.expToNextLevel;
        allLevelUps.add(_activeMonster.levelUp());
        _activeMonster.currentExp = remainingExp;
        _activeMonster.expToNextLevel = Monster.calculateExpForNextLevel(
          _activeMonster.level,
        );
      }
    }

    SaveManager.saveParty(widget.playerParty);
    _saveGold(); // Simpan gold terbaru

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(won ? 'Menang!' : 'Kalah...', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              won ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
              size: 60,
              color: won ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              won
                  ? 'Kamu berhasil mengalahkan Trainer Lv.${widget.towerLevel}!'
                  : 'Monster kamu kehabisan tenaga.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '+ $exp EXP',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (won)
              Text(
                '+ $gold Gold',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog hasil battle
                if (allLevelUps.isNotEmpty) {
                  _showLevelUpDialog(
                    allLevelUps,
                    _activeMonster,
                    initialLevel,
                  ).then((_) {
                    Navigator.pop(context); // Kembali ke menu Infinite Tower
                  });
                } else {
                  Navigator.pop(context); // Langsung kembali
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: won ? Colors.green : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Kembali',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ARENA PERTARUNGAN (Split Screen Style)
            Expanded(
              flex: 5,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 🌟 BACKGROUND ARENA SESUNGGUHNYA 🌟
                  Positioned.fill(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipPath(
                          clipper: AsymmetricDiagonalClipper(
                            isTop: true,
                            progress: 1.0,
                          ),
                          child: Image.asset(
                            'assets/images/battle_bg_journey.png', // Frame Atas
                            fit: BoxFit.cover,
                            alignment: const Alignment(
                              -1.0,
                              1.0,
                            ), // Bebas atur posisi
                          ),
                        ),
                        ClipPath(
                          clipper: AsymmetricDiagonalClipper(
                            isTop: false,
                            progress: 1.0,
                          ),
                          child: Image.asset(
                            'assets/images/battle_bg_journey.png', // Frame Bawah
                            fit: BoxFit.cover,
                            alignment:
                                Alignment.bottomCenter, // Bebas atur posisi
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Animasi Clash
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final boxSize = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        return AnimatedBuilder(
                          animation: _clashController,
                          builder: (context, child) {
                            final linearValue = _clashController.value;
                            final slideProgress = Curves.easeOut.transform(
                              (linearValue / 0.25).clamp(0.0, 1.0),
                            );
                            final lineProgress = Curves.easeOut.transform(
                              ((linearValue - 0.25) / 0.10).clamp(0.0, 1.0),
                            );
                            final morphProgress = Curves.easeOutBack.transform(
                              ((linearValue - 0.35) / 0.35).clamp(0.0, 1.0),
                            );
                            final fadeOutProgress = Curves.easeIn.transform(
                              ((linearValue - 0.70) / 0.30).clamp(0.0, 1.0),
                            );
                            final opacity = 1.0 - fadeOutProgress;

                            final currentAvgYOffset =
                                boxSize.height * 0.05 * morphProgress;
                            final currentDy =
                                boxSize.width * 0.53 * morphProgress;
                            final lineAngle = atan2(currentDy, boxSize.width);
                            final lineWidth =
                                sqrt(
                                  boxSize.width * boxSize.width +
                                      currentDy * currentDy,
                                ) *
                                1.5;

                            final slideYTop =
                                -(boxSize.height / 2) * (1 - slideProgress);
                            final slideYBottom =
                                (boxSize.height / 2) * (1 - slideProgress);

                            return Stack(
                              fit: StackFit.expand,
                              clipBehavior: Clip.none,
                              children: [
                                if (opacity > 0.0)
                                  Opacity(
                                    opacity: opacity,
                                    child: Transform.translate(
                                      offset: Offset(0, slideYTop),
                                      child: ClipPath(
                                        clipper: AsymmetricDiagonalClipper(
                                          isTop: true,
                                          progress: morphProgress,
                                        ),
                                        child: Container(
                                          color:
                                              _activeEnemyMonster.elementColor,
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                top: -40,
                                                right: -40,
                                                child: Icon(
                                                  _getElementIcon(
                                                    _activeEnemyMonster.element,
                                                  ),
                                                  size: 250,
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (opacity > 0.0)
                                  Opacity(
                                    opacity: opacity,
                                    child: Transform.translate(
                                      offset: Offset(0, slideYBottom),
                                      child: ClipPath(
                                        clipper: AsymmetricDiagonalClipper(
                                          isTop: false,
                                          progress: morphProgress,
                                        ),
                                        child: Container(
                                          color: _activeMonster.elementColor,
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                bottom: -40,
                                                left: -40,
                                                child: Icon(
                                                  _getElementIcon(
                                                    _activeMonster.element,
                                                  ),
                                                  size: 250,
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (lineProgress > 0)
                                  Center(
                                    child: Transform.translate(
                                      offset: Offset(0, currentAvgYOffset),
                                      child: OverflowBox(
                                        maxWidth: double.infinity,
                                        maxHeight: double.infinity,
                                        child: Transform.rotate(
                                          angle: lineAngle,
                                          child: Container(
                                            height: 12,
                                            width: lineWidth * lineProgress,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: Colors.black54,
                                                width: 2.0,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  blurRadius: 15,
                                                  spreadRadius: 4,
                                                ),
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Animasi Damage Musuh
                  if (_enemyDamageValue > 0)
                    Positioned(
                      top: size.height * 0.15,
                      right: size.width * 0.25,
                      child: _buildDamageText(_enemyDamageValue, isEnemy: true),
                    ),

                  // Animasi Damage Pemain
                  if (_playerDamageValue > 0)
                    Positioned(
                      bottom: size.height * 0.15,
                      left: size.width * 0.25,
                      child: _buildDamageText(
                        _playerDamageValue,
                        isEnemy: false,
                      ),
                    ),

                  // --- MONSTER MUSUH (TOP RIGHT) ---
                  Positioned(
                    top: -50,
                    right: 0,
                    child: _buildMonsterSpriteCore(
                      element: _activeEnemyMonster.element,
                      isEnemy: true,
                      shakeController: _enemyShakeController,
                    ),
                  ),
                  // --- MONSTER PEMAIN (BOTTOM LEFT) ---
                  Positioned(
                    bottom: 20,
                    left: 10,
                    child: _buildMonsterSpriteCore(
                      element: _activeMonster.element,
                      isEnemy: false,
                      shakeController: _playerShakeController,
                    ),
                  ),
                  // --- HUD MUSUH (TOP LEFT) ---
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFuturisticHUDCore(
                          name: _activeEnemyMonster.name,
                          level: _activeEnemyMonster.level,
                          element: _activeEnemyMonster.element,
                          currentHp: _enemyHp,
                          maxHp: _activeEnemyMonster.hp,
                          currentStamina: _enemyStamina,
                          maxStamina: _activeEnemyMonster.stamina,
                          isEnemy: true,
                          oldHp: _oldEnemyHp,
                          statusEffects: _buildStatusList(isEnemy: true),
                        ),
                      ],
                    ),
                  ),
                  // --- HUD PEMAIN (BOTTOM RIGHT) ---
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: _buildFuturisticHUDCore(
                      name: _activeMonster.name,
                      level: _activeMonster.level,
                      element: _activeMonster.element,
                      currentHp: _playerHp,
                      maxHp: _activeMonster.hp,
                      currentStamina: _playerStamina,
                      maxStamina: _activeMonster.stamina,
                      isEnemy: false,
                      oldHp: _oldPlayerHp,
                      statusEffects: _buildStatusList(isEnemy: false),
                    ),
                  ),
                ],
              ),
            ),

            // BATTLE LOG
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: TypewriterText(
                        text: _battleLog,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  if (_isPlayerTurn) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        if (_playerHp <= 0) return;
                        setState(() => _isSwitchMode = !_isSwitchMode);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isSwitchMode
                              ? Colors.blueAccent
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isSwitchMode ? Icons.close : Icons.swap_horiz,
                          color: _isSwitchMode
                              ? Colors.white
                              : Colors.blueAccent,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // AREA KARTU (HAND / SWITCH)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.grey.shade900,
                child: _isPlayerTurn
                    ? ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                final isIncoming =
                                    child.key ==
                                    (_isSwitchMode
                                        ? const ValueKey('switch_mode')
                                        : const ValueKey('moves_mode'));
                                if (isIncoming) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  );
                                } else {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(-1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  );
                                }
                              },
                          child: _isSwitchMode
                              ? SingleChildScrollView(
                                  key: const ValueKey('switch_mode'),
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      widget.playerParty.length,
                                      (index) => _buildMonsterSwitchCard(
                                        widget.playerParty[index],
                                        index,
                                      ),
                                    ),
                                  ),
                                )
                              : Row(
                                  key: const ValueKey('moves_mode'),
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                    _currentCards.length,
                                    (index) => _buildAnimatedCard(
                                      _currentCards[index],
                                      index,
                                    ),
                                  ),
                                ),
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(MonsterMove move, int index) {
    final intervalStart = (index * 0.2).clamp(0.0, 1.0);
    final intervalEnd = (intervalStart + 0.6).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        final cardProgress = CurveTween(
          curve: Interval(
            intervalStart,
            intervalEnd,
            curve: Curves.easeOutQuad,
          ),
        ).transform(_cardAnimation.value);
        final yOffset = (1 - cardProgress) * 150;
        final rotationY = (1 - cardProgress) * (pi / 2);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..translate(0.0, yOffset, 0.0)
            ..rotateY(rotationY),
          child: Opacity(opacity: cardProgress, child: _buildCard(move)),
        );
      },
    );
  }

  List<Widget> _buildStatusList({required bool isEnemy}) {
    List<Widget> list = [];
    if (isEnemy) {
      if (_enemyBurnTurns > 0)
        list.add(
          _buildStatusEffectIndicator(
            'Burn',
            _enemyBurnTurns,
            3,
            Icons.local_fire_department,
            Colors.orange,
          ),
        );
      if (_enemyBindTurns > 0)
        list.add(
          _buildStatusEffectIndicator(
            'Bind',
            _enemyBindTurns,
            1,
            Icons.link_off,
            Colors.blue,
          ),
        );
      if (_enemyInvulnerableTurns > 0)
        list.add(
          _buildStatusEffectIndicator(
            'Miss',
            _enemyInvulnerableTurns,
            2,
            Icons.visibility_off,
            Colors.grey,
          ),
        );
      if (_enemyParalysisTurns > 0)
        list.add(
          _buildStatusEffectIndicator(
            'Paralysis',
            _enemyParalysisTurns,
            1,
            Icons.bolt,
            Colors.amber,
          ),
        );
    } else {
      if (_playerBurnTurns > 0)
        list.add(
          _buildStatusEffectIndicator(
            'Burn',
            _playerBurnTurns,
            3,
            Icons.local_fire_department,
            Colors.orange,
          ),
        );
      if (_playerBindTurns > 0)
        list.add(
          _buildStatusEffectIndicator(
            'Bind',
            _playerBindTurns,
            1,
            Icons.link_off,
            Colors.blue,
          ),
        );
      if (_playerInvulnerableTurns > 0)
        list.add(
          _buildStatusEffectIndicator(
            'Miss',
            _playerInvulnerableTurns,
            2,
            Icons.visibility_off,
            Colors.grey,
          ),
        );
      if (_playerParalysisTurns > 0)
        list.add(
          _buildStatusEffectIndicator(
            'Paralysis',
            _playerParalysisTurns,
            1,
            Icons.bolt,
            Colors.amber,
          ),
        );
    }
    return list;
  }

  Widget _buildDamageText(int damage, {required bool isEnemy}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      onEnd: () => setState(
        () => isEnemy ? _enemyDamageValue = 0 : _playerDamageValue = 0,
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: 1.0 - value,
          child: Transform.translate(
            offset: Offset(0.0, -50.0 * value),
            child: Text(
              '-$damage',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 2.0,
                    color: Colors.black,
                    offset: Offset(1.0, 1.0),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(MonsterMove move) {
    Color bgColor = Colors.white;
    IconData icon = Icons.sports_mma;

    if (move.type == MoveType.elemental) {
      bgColor = _activeMonster.elementColor;
      icon = _getElementIcon(_activeMonster.element);
    } else if (move.type == MoveType.special) {
      bgColor = Colors.purple.shade400;
      icon = Icons.auto_awesome;
    } else if (move.type == MoveType.recover) {
      bgColor = Colors.teal.shade300;
      if (move.name == 'Heal') {
        icon = Icons.add;
      } else {
        icon = Icons.healing;
      }
    }

    String typeLabel = move.type == MoveType.elemental
        ? 'ELEMENT'
        : (move.type == MoveType.special ? 'SPECIAL' : 'NORMAL');
    if (move.type == MoveType.recover) typeLabel = 'RECOVER';
    Color textColor = move.type == MoveType.normal
        ? Colors.black87
        : Colors.white;

    return GestureDetector(
      onTap: () => _playTurn(move),
      child: Container(
        width: 110,
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'COST',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    move.name == 'Heal'
                        ? '+15'
                        : (move.cost > 0 ? '${move.cost}' : '+${-move.cost}'),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    move.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    typeLabel,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  Widget _buildMonsterSwitchCard(Monster monster, int index) {
    bool isDead = _partyHp[monster]! <= 0;
    bool isActive = monster == _activeMonster;
    bool disabled = isDead || isActive;
    Color bgColor = monster.elementColor;

    return GestureDetector(
      onTap: disabled ? null : () => _switchMonster(monster),
      child: Opacity(
        opacity: disabled ? 0.6 : 1.0,
        child: Container(
          width: 110,
          height: 160,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'LVL ${monster.level}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isActive ? 'ACTIVE' : (isDead ? 'FAINTED' : 'SWAP'),
                      style: TextStyle(
                        color: isActive
                            ? Colors.amber
                            : (isDead ? Colors.red : Colors.white),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getElementIcon(monster.element),
                        size: 40,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          monster.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 2,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'HP',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SmoothProgressBar(
                      value: _partyHp[monster]! / monster.hp,
                      backgroundColor: Colors.black26,
                      baseColor: Colors.greenAccent,
                      minHeight: 6,
                      isHealthBar: true,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_partyHp[monster]}/${monster.hp}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
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
}
