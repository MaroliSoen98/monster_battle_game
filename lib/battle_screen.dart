import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:monster_battle_game/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
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
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET UNTUK EFEK TEKS BERJALAN (TYPEWRITER)
// ============================================================================
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';

  @override
  void initState() {
    super.initState();
    _animateText();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _animateText();
    }
  }

  void _animateText() {
    // Tampilkan teks secara instan untuk kelancaran UI
    setState(() {
      _displayedText = widget.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}

// Custom Clipper Dinamis untuk setengah layar atas (Musuh)
class DynamicTopClipper extends CustomClipper<Path> {
  final double morphProgress;
  DynamicTopClipper(this.morphProgress);

  @override
  Path getClip(Size size) {
    final path = Path();
    final leftY = (size.height / 2) * (1 - morphProgress);
    final rightY = (size.height / 2) + (size.height / 2) * morphProgress;

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, rightY);
    path.lineTo(0, leftY);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(DynamicTopClipper oldClipper) =>
      morphProgress != oldClipper.morphProgress;
}

// Custom Clipper Dinamis untuk setengah layar bawah (Pemain)
class DynamicBottomClipper extends CustomClipper<Path> {
  final double morphProgress;
  DynamicBottomClipper(this.morphProgress);

  @override
  Path getClip(Size size) {
    final path = Path();
    final leftY = (size.height / 2) * (1 - morphProgress);
    final rightY = (size.height / 2) + (size.height / 2) * morphProgress;

    path.moveTo(0, leftY);
    path.lineTo(size.width, rightY);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(DynamicBottomClipper oldClipper) =>
      morphProgress != oldClipper.morphProgress;
}

// ============================================================================
// 2. WILD BATTLE ARENA
// ============================================================================
class WildBattleArena extends StatefulWidget {
  final Monster playerMonster;
  final Function(bool won) onBattleEnd;

  const WildBattleArena({
    super.key,
    required this.playerMonster,
    required this.onBattleEnd,
  });

  @override
  State<WildBattleArena> createState() => _WildBattleArenaState();
}

class _WildBattleArenaState extends State<WildBattleArena>
    with TickerProviderStateMixin {
  late Monster _enemyMonster;

  // Status HP
  late int _playerHp;
  late int _enemyHp;
  late int _oldPlayerHp; // Untuk animasi bar HP
  late int _oldEnemyHp; // Untuk animasi bar HP
  late int _playerStamina, _enemyStamina;

  // Sistem Kartu (Deck)
  List<MonsterMove> _currentCards = [];
  bool _isPlayerTurn = true;
  String _battleLog = "Pertarungan dimulai!";

  // Untuk animasi damage
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

  // Cooldown untuk kartu spesial
  int _turnCount = 1;
  int _lastSpecialCardTurn =
      -14; // Mulai di -14 agar bisa keluar di giliran pertama (1/15)
  int _enemyLastSpecialTurn = -14; // Cooldown untuk special move musuh (1/15)
  int _playerConsecutiveAbsorb =
      0; // Combo berulang untuk kartu Absorb (Player)
  int _enemyConsecutiveAbsorb = 0; // Combo berulang untuk kartu Absorb (Enemy)

  @override
  void initState() {
    super.initState();
    _enemyMonster = _generateRandomEnemy();
    _playerHp = widget.playerMonster.hp;
    _enemyHp = _enemyMonster.hp;
    _oldPlayerHp = widget.playerMonster.hp;
    _oldEnemyHp = _enemyMonster.hp;
    _playerStamina = widget.playerMonster.stamina;
    _enemyStamina = _enemyMonster.stamina;
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Perpanjang durasi total
    );
    _clashController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1400,
      ), // Diperlama untuk 2 fase animasi
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
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _clashController.dispose();
    _playerShakeController.dispose();
    _enemyShakeController.dispose();
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

  // Helper to check elemental advantage
  bool _isSuperEffective(MonsterElement attacker, MonsterElement defender) {
    return (attacker == MonsterElement.Api &&
            defender == MonsterElement.Tumbuhan) ||
        (attacker == MonsterElement.Tumbuhan &&
            defender == MonsterElement.Air) ||
        (attacker == MonsterElement.Air && defender == MonsterElement.Api) ||
        (attacker == MonsterElement.Listrik &&
            (defender == MonsterElement.Air ||
                defender == MonsterElement.Terbang)) ||
        (attacker == MonsterElement.Tanah &&
            (defender == MonsterElement.Api ||
                defender == MonsterElement.Listrik)) ||
        (attacker == MonsterElement.Terbang &&
            defender == MonsterElement.Tumbuhan);
  }

  bool _isNotVeryEffective(MonsterElement attacker, MonsterElement defender) {
    return (attacker == MonsterElement.Api && defender == MonsterElement.Air) ||
        (attacker == MonsterElement.Tumbuhan &&
            defender == MonsterElement.Api) ||
        (attacker == MonsterElement.Air &&
            defender == MonsterElement.Tumbuhan) ||
        (attacker == MonsterElement.Listrik &&
            defender == MonsterElement.Tanah) ||
        (attacker == MonsterElement.Tanah &&
            defender == MonsterElement.Tumbuhan) ||
        (attacker == MonsterElement.Terbang &&
            defender == MonsterElement.Listrik);
  }

  bool _isNoEffect(MonsterElement attacker, MonsterElement defender) {
    return (attacker == MonsterElement.Tanah &&
        defender == MonsterElement.Terbang);
  }

  // Menghitung damage berdasarkan formula baru
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

    // 10% evasion for Flying type
    if (defender.element == MonsterElement.Terbang &&
        random.nextInt(100) < 10 &&
        move.type != MoveType.recover) {
      return {'damage': 0, 'log': ' Serangan berhasil dihindari (Evasiness)!'};
    }

    // 1. Tentukan elemen serangan. Serangan normal tidak punya elemen.
    MonsterElement? moveElement;
    if (move.type == MoveType.elemental || move.type == MoveType.special) {
      moveElement = attacker.element;
    }

    if (moveElement != null && _isNoEffect(moveElement, defender.element)) {
      return {'damage': 0, 'log': ' Tidak ada efek pada tipe ini!'};
    }

    // 2. Modifier: Keunggulan Tipe
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
        // Aturan tambahan: serangan tipe yang sama jadi efektif
        typeModifier = 1.5;
        typeLog = " Efektif.";
      }
    }

    // 3. Modifier: STAB (Same Type Attack Bonus)
    double stabModifier = 1.0;
    if (moveElement != null && moveElement == attacker.element) {
      stabModifier = 1.5;
    }

    // 4. Modifier: Critical Hit (10% chance)
    double critModifier = 1.0;
    bool isCritical = random.nextInt(100) < 10;
    if (isCritical) {
      critModifier = 1.5;
    }

    // 5. Modifier: Faktor Acak (0.85 - 1.00) // Diringkas
    double randomModifier = 0.85 + random.nextDouble() * 0.15;

    // Defense berkurang 10% jika musuh sedang dalam status Bind
    double effectiveDefense = defender.defense;
    if (defenderBindTurns > 0) {
      effectiveDefense *= 0.9;
    }

    // Hitung Base Damage
    double baseDamage =
        (((2 * attacker.level / 5 + 2) *
                move.power *
                (attacker.attack / effectiveDefense)) /
            40) + // Pembagi dikurangi agar damage lebih besar
        2;

    // Hitung Final Damage
    double finalDamageDouble =
        baseDamage *
        typeModifier *
        stabModifier *
        critModifier *
        randomModifier;

    // Bonus damage 10% untuk serangan elemen jika musuh sedang terkena Burn
    if (defenderBurnTurns > 0 && move.type == MoveType.elemental) {
      finalDamageDouble *= 1.1;
      typeLog += " (Bonus Burn +10% DMG!)";
      if (moveElement == MonsterElement.Api) {
        finalDamageDouble += 2;
        typeLog += " (+2 DMG Api!)";
      }
    }

    String critLog = isCritical ? " Serangan Kritis!" : "";

    return {'damage': finalDamageDouble.floor(), 'log': typeLog + critLog};
  }

  // Mockup untuk menghasilkan musuh acak
  Monster _generateRandomEnemy() {
    final random = Random();
    final elements = [
      MonsterElement.Api,
      MonsterElement.Air,
      MonsterElement.Tumbuhan,
      MonsterElement.Listrik,
      MonsterElement.Tanah,
      MonsterElement.Terbang,
    ];
    final rIndex = random.nextInt(6);
    final selectedElement = elements[rIndex];
    final enemyLevel = max(
      1,
      widget.playerMonster.level + random.nextInt(3) - 1,
    );

    String monsterName = "";
    String imagePath = "";
    List<MonsterMove> generatedMoves = [];
    int baseHp;
    double baseAttack;
    double baseDefense;
    int baseSpeed;
    int baseStamina = 50; // Stamina konsisten

    // Kumpulan Nama Attack Umum
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

    switch (selectedElement) {
      case MonsterElement.Api:
        List<String> names = [
          'Ignis',
          'Pyre',
          'Blaze',
          'Inferno',
          'Cinder',
          'Flare',
        ];
        monsterName = 'Wild ${names[random.nextInt(names.length)]}';
        imagePath = 'assets/images/fire_monster.png';
        baseHp = 60;
        baseAttack = 75;
        baseDefense = 55;
        baseSpeed = 65;

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
        generatedMoves = [
          MonsterMove(
            name: randomRecover,
            type: MoveType.recover,
            power: 0,
            cost: -15,
          ),
          MonsterMove(
            name: randomNormal,
            type: MoveType.normal,
            power: 40,
            cost: -7,
          ),
          MonsterMove(
            name: elMoves[random.nextInt(elMoves.length)],
            type: MoveType.elemental,
            power: 50,
            cost: 10,
          ),
          MonsterMove(
            name: spMoves[random.nextInt(spMoves.length)],
            type: MoveType.special,
            power: 45,
            effect: 'Burn 3 turn',
            cost: 10,
          ),
        ];
        break;
      case MonsterElement.Air: // Represents Water/Air type
        List<String> names = [
          'Aqua',
          'Hydro',
          'Tide',
          'Splash',
          'Ripple',
          'Wave',
        ];
        monsterName = 'Wild ${names[random.nextInt(names.length)]}';
        imagePath = 'assets/images/water_monster.png';
        baseHp = 65;
        baseAttack = 60;
        baseDefense = 60;
        baseSpeed = 70;

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
        generatedMoves = [
          MonsterMove(
            name: randomRecover,
            type: MoveType.recover,
            power: 0,
            cost: -15,
          ),
          MonsterMove(
            name: randomNormal,
            type: MoveType.normal,
            power: 40,
            cost: -7,
          ),
          MonsterMove(
            name: elMoves[random.nextInt(elMoves.length)],
            type: MoveType.elemental,
            power: 45,
            cost: 10,
          ),
          MonsterMove(
            name: spMoves[random.nextInt(spMoves.length)],
            type: MoveType.special,
            power: 30,
            effect: 'Bind 1 turn',
            cost: 10,
          ),
        ];
        break;
      case MonsterElement.Tumbuhan:
        List<String> names = [
          'Flora',
          'Leaf',
          'Vine',
          'Thorn',
          'Root',
          'Petal',
        ];
        monsterName = 'Wild ${names[random.nextInt(names.length)]}';
        imagePath = 'assets/images/plant_monster.png';
        baseHp = 70;
        baseAttack = 55;
        baseDefense = 75;
        baseSpeed = 60;

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
        generatedMoves = [
          MonsterMove(
            name: randomRecover,
            type: MoveType.recover,
            power: 0,
            cost: -15,
          ),
          MonsterMove(
            name: randomNormal,
            type: MoveType.normal,
            power: 40,
            cost: -7,
          ),
          MonsterMove(
            name: elMoves[random.nextInt(elMoves.length)],
            type: MoveType.elemental,
            power: 40,
            cost: 10,
          ),
          MonsterMove(
            name: spMoves[random.nextInt(spMoves.length)],
            type: MoveType.special,
            power: 20,
            effect: 'Drain HP & Heal',
            cost: 10,
          ),
        ];
        break;
      case MonsterElement.Listrik:
        List<String> names = [
          'Volt',
          'Spark',
          'Zap',
          'Blitz',
          'Thunder',
          'Jolt',
        ];
        monsterName = 'Wild ${names[random.nextInt(names.length)]}';
        imagePath = 'assets/images/electric_monster.png';
        baseHp = 55;
        baseAttack = 70;
        baseDefense = 50;
        baseSpeed = 90;

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
        generatedMoves = [
          MonsterMove(
            name: randomRecover,
            type: MoveType.recover,
            power: 0,
            cost: -15,
          ),
          MonsterMove(
            name: randomNormal,
            type: MoveType.normal,
            power: 40,
            cost: -7,
          ),
          MonsterMove(
            name: elMoves[random.nextInt(elMoves.length)],
            type: MoveType.elemental,
            power: 50,
            cost: 10,
          ),
          MonsterMove(
            name: spMoves[random.nextInt(spMoves.length)],
            type: MoveType.special,
            power: 30,
            effect: 'Paralysis 1 turn',
            cost: 10,
          ),
        ];
        break;
      case MonsterElement.Tanah:
        List<String> names = ['Terra', 'Rock', 'Quake', 'Dust', 'Mud', 'Stone'];
        monsterName = 'Wild ${names[random.nextInt(names.length)]}';
        imagePath = 'assets/images/ground_monster.png';
        baseHp = 80;
        baseAttack = 60;
        baseDefense = 85;
        baseSpeed = 45;

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
        generatedMoves = [
          MonsterMove(
            name: randomRecover,
            type: MoveType.recover,
            power: 0,
            cost: -15,
          ),
          MonsterMove(
            name: randomNormal,
            type: MoveType.normal,
            power: 40,
            cost: -7,
          ),
          MonsterMove(
            name: elMoves[random.nextInt(elMoves.length)],
            type: MoveType.elemental,
            power: 50,
            cost: 10,
          ),
          MonsterMove(
            name: spMoves[random.nextInt(spMoves.length)],
            type: MoveType.special,
            power: 20,
            effect: 'Miss 2 turn',
            cost: 15,
          ),
        ];
        break;
      case MonsterElement.Terbang:
        List<String> names = [
          'Aero',
          'Zephyr',
          'Wind',
          'Gale',
          'Sky',
          'Breeze',
        ];
        monsterName = 'Wild ${names[random.nextInt(names.length)]}';
        imagePath = 'assets/images/flying_monster.png';
        baseHp = 60;
        baseAttack = 65;
        baseDefense = 60;
        baseSpeed = 80;

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
        generatedMoves = [
          MonsterMove(
            name: randomRecover,
            type: MoveType.recover,
            power: 0,
            cost: -15,
          ),
          MonsterMove(
            name: randomNormal,
            type: MoveType.normal,
            power: 40,
            cost: -7,
          ),
          MonsterMove(
            name: elMoves[random.nextInt(elMoves.length)],
            type: MoveType.elemental,
            power: 45,
            cost: 10,
          ),
          MonsterMove(
            name: spMoves[random.nextInt(spMoves.length)],
            type: MoveType.special,
            power: 40,
            effect: 'Miss 1 turn',
            cost: 15,
          ),
        ];
        break;
    }

    // Kalkulasi stat berdasarkan level untuk keseimbangan
    int hp = baseHp + ((enemyLevel - 1) * 4);
    double attack = baseAttack + ((enemyLevel - 1) * 2);
    double defense = baseDefense + ((enemyLevel - 1) * 2);
    int speed = baseSpeed + (enemyLevel - 1);
    int stamina = baseStamina + ((enemyLevel - 1) * 5);

    return Monster(
      name: monsterName,
      element: selectedElement,
      imagePath: imagePath,
      attack: attack,
      defense: defense,
      speed: speed,
      stamina: stamina,
      hp: hp,
      level: enemyLevel,
      moves: generatedMoves,
    );
  }

  // Menarik 3 kartu acak sesuai tipe serangan
  void _drawCards() {
    final random = Random();
    final moves = widget.playerMonster.moves;
    _currentCards.clear();

    final normalMoves = moves.where((m) => m.type == MoveType.normal).toList();
    final elementalMoves = moves
        .where((m) => m.type == MoveType.elemental)
        .toList();
    final specialMoves = moves
        .where((m) => m.type == MoveType.special)
        .toList();
    final recoverMoves = moves
        .where((m) => m.type == MoveType.recover)
        .toList();

    // Cek apakah kartu spesial bisa ditarik (cooldown 15 turn)
    if (specialMoves.isNotEmpty && (_turnCount - _lastSpecialCardTurn) >= 15) {
      _currentCards.add(specialMoves[random.nextInt(specialMoves.length)]);
      _lastSpecialCardTurn = _turnCount; // Reset cooldown
    }

    // Isi sisa tangan dengan kartu non-spesial
    List<MonsterMove> fillPool = [];
    if (normalMoves.isNotEmpty) fillPool.addAll(normalMoves);
    if (elementalMoves.isNotEmpty) fillPool.addAll(elementalMoves);
    if (recoverMoves.isNotEmpty) fillPool.addAll(recoverMoves);
    fillPool.shuffle();

    while (_currentCards.length < 3 && moves.isNotEmpty) {
      // Add a move that is not already in the hand
      var availableMoves = moves
          .where((m) => !_currentCards.contains(m))
          .toList();
      if (availableMoves.isEmpty) break; // No more unique moves to add
      _currentCards.add(availableMoves[random.nextInt(availableMoves.length)]);
    }

    // Acak posisi kartu di tangan
    _currentCards.shuffle();
  }

  void _playTurn(MonsterMove move) {
    if (!_isPlayerTurn) return;

    // --- Handle Player Status Effects ---
    if (_playerInvulnerableTurns > 0) {
      _playerInvulnerableTurns--;
    }

    if (_playerBindTurns > 0 || _playerParalysisTurns > 0) {
      setState(() {
        if (_playerBindTurns > 0) {
          _playerBindTurns--;
          _battleLog = "Kamu tidak bisa bergerak karena Terikat!";
        } else {
          _playerParalysisTurns--;
          _battleLog = "Kamu tidak bisa bergerak karena Paralysis!";
        }
        _isPlayerTurn = false;
      });
      _enemyTurn();
      return;
    }

    String statusLog = "";
    if (_playerBurnTurns > 0) {
      setState(() {
        _oldPlayerHp = _playerHp; // Simpan HP lama untuk animasi
        _playerHp = max(0, _playerHp - 5);
        _playerBurnTurns--;
        statusLog = "Kamu terkena 5 damage Burn! ";
      });
      if (_playerHp == 0) {
        _showEndGameDialog(false);
        return;
      }
    }

    // Lacak penggunaan Absorb berturut-turut
    if (move.name == 'Absorb' || move.effect == 'Drain HP & Heal') {
      _playerConsecutiveAbsorb++;
    } else {
      _playerConsecutiveAbsorb = 0;
    }

    // Cek Stamina
    if (move.cost > _playerStamina) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stamina tidak cukup!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Handle kartu recover
    if (move.type == MoveType.recover) {
      setState(() {
        _playerStamina = min(
          widget.playerMonster.stamina,
          _playerStamina - move.cost,
        );
        _battleLog = "Kamu fokus dan memulihkan ${-move.cost} stamina!";
        _isPlayerTurn = false;
      });
      _enemyTurn(); // Langsung ke giliran musuh
      return;
    }

    setState(() {
      _isPlayerTurn = false;

      // Update Stamina
      _playerStamina = min(
        widget.playerMonster.stamina,
        _playerStamina - move.cost,
      );
      final damageResult = _calculateDamage(
        widget.playerMonster,
        _enemyMonster,
        move,
        defenderBindTurns: _enemyBindTurns,
        defenderBurnTurns: _enemyBurnTurns,
        defenderInvulnerableTurns: _enemyInvulnerableTurns,
      );
      int damage = damageResult['damage'];
      String elementalLog = damageResult['log'];

      // Efek Spesial
      String effectLog = "";
      if (move.name == 'Flame Spin' || move.effect == 'Burn 3 turn') {
        _enemyBurnTurns = 3;
        effectLog = " Musuh terkena Burn!";
      } else if (move.name == 'Bind' || move.effect == 'Bind 1 turn') {
        _enemyBindTurns = 1;
        effectLog = " Musuh Terikat!";
      } else if (move.name == 'Paralysis' ||
          move.effect == 'Paralysis 1 turn') {
        _enemyParalysisTurns = 1;
        effectLog = " Musuh terkena Paralysis!";
      } else if (move.name == 'Grounding' || move.effect == 'Miss 2 turn') {
        _playerInvulnerableTurns = 2;
        effectLog = " Kamu bersembunyi (Invulnerable 2 Turn)!";
      } else if (move.name == 'Fly Away' || move.effect == 'Miss 1 turn') {
        _playerInvulnerableTurns = 1;
        effectLog = " Kamu terbang tinggi (Invulnerable 1 Turn)!";
      } else if (move.name == 'Absorb' || move.effect == 'Drain HP & Heal') {
        int combo = min(_playerConsecutiveAbsorb, 3);
        int bonus = (combo - 1) * 2;
        damage += bonus; // Tambahkan bonus ke total damage
        int healAmount = damage; // Heal disesuaikan dengan damage
        _playerHp = min(widget.playerMonster.hp, _playerHp + healAmount);
        effectLog = " Kamu menyerap $healAmount HP!";
      }
      if (move.cost < 0 && move.type != MoveType.recover) {
        effectLog += " Kamu memulihkan ${-move.cost} stamina!";
      }

      _enemyDamageValue = damage; // Set damage value setelah buff Absorb
      _oldEnemyHp = _enemyHp; // Simpan HP lama untuk animasi
      _enemyHp = max(0, _enemyHp - damage);
      if (damage > 0) {
        _enemyShakeController.forward(from: 0.0);
      }
      _battleLog =
          statusLog +
          "${widget.playerMonster.name} menggunakan ${move.name}!$elementalLog$effectLog";
    });

    if (_enemyHp == 0) {
      _showEndGameDialog(true);
      return;
    }

    _enemyTurn();
  }

  // Logika giliran musuh
  void _enemyTurn() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        String statusLog = "";
        int actualEnemyDamage = 0;

        if (_enemyInvulnerableTurns > 0) {
          _enemyInvulnerableTurns--;
        }

        // Cek efek Burn
        if (_enemyBurnTurns > 0) {
          _enemyHp = max(0, _enemyHp - 5);
          _enemyBurnTurns--;
          statusLog = "Musuh terkena 5 damage Burn! ";
        }

        if (_enemyHp == 0) {
          _battleLog = statusLog + "Musuh kehabisan HP!";
          _showEndGameDialog(true);
          return;
        }

        // Cek efek Bind
        if (_enemyBindTurns > 0 || _enemyParalysisTurns > 0) {
          if (_enemyBindTurns > 0) {
            _enemyBindTurns--;
            _battleLog =
                statusLog +
                "${_enemyMonster.name} terikat dan tidak bisa bergerak!";
          } else {
            _enemyParalysisTurns--;
            _battleLog =
                statusLog +
                "${_enemyMonster.name} terkena Paralysis dan tidak bisa bergerak!";
          }
          _nextPlayerTurn();
          return;
        }

        // AI Move Selection
        MonsterMove? chosenMove;
        final random = Random();

        var affordableMoves = _enemyMonster.moves
            .where((m) => m.cost <= _enemyStamina)
            .toList();

        // Batasi penggunaan serangan spesial musuh (1 per 15 giliran)
        if ((_turnCount - _enemyLastSpecialTurn) < 15) {
          affordableMoves.removeWhere((m) => m.type == MoveType.special);
        }

        if (affordableMoves.isNotEmpty) {
          // --- New Tactical AI ---
          Map<MonsterMove, double> moveScores = {};
          bool isPlayerWeak = _isSuperEffective(
            _enemyMonster.element,
            widget.playerMonster.element,
          );

          for (var move in affordableMoves) {
            double score = 0;
            switch (move.type) {
              case MoveType.elemental:
                score = isPlayerWeak
                    ? 3.0
                    : 1.0; // High score if super effective
                break;
              case MoveType.special:
                score = 1.0; // Dikurangi prioritasnya agar tidak terlalu sering
                break;
              case MoveType.normal:
                score = 0.5; // Base score for attacking
                break;
              case MoveType.recover:
                // Recover is only valuable when stamina is low
                if (_enemyStamina < _enemyMonster.stamina * 0.4) {
                  score = 2.5; // High score to force recovery
                } else {
                  score = -1.0; // Avoid recovering with high stamina
                }
                break;
            }
            // Add a bit of randomness to avoid deterministic behavior
            moveScores[move] = score + (random.nextDouble() * 0.5);
          }

          // Find the move with the highest score
          if (moveScores.isNotEmpty) {
            final bestMoveEntry = moveScores.entries.reduce(
              (a, b) => a.value > b.value ? a : b,
            );
            chosenMove = bestMoveEntry.key;
          }
        }

        // If a move was chosen, execute it
        if (chosenMove != null) {
          // Catat giliran jika serangan spesial digunakan
          if (chosenMove.type == MoveType.special) {
            _enemyLastSpecialTurn = _turnCount;
          }

          // Lacak penggunaan Absorb berturut-turut musuh
          if (chosenMove.name == 'Absorb' ||
              chosenMove.effect == 'Drain HP & Heal') {
            _enemyConsecutiveAbsorb++;
          } else {
            _enemyConsecutiveAbsorb = 0;
          }

          _enemyStamina = min(
            _enemyMonster.stamina,
            _enemyStamina - chosenMove.cost,
          );

          if (chosenMove.type == MoveType.recover) {
            _battleLog =
                statusLog +
                "${_enemyMonster.name} fokus dan memulihkan ${-chosenMove.cost} stamina!";
          } else {
            // Attack move
            final damageResult = _calculateDamage(
              _enemyMonster,
              widget.playerMonster,
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
              effectLog = " Kamu terkena Burn!";
            } else if (chosenMove.name == 'Bind' ||
                chosenMove.effect == 'Bind 1 turn') {
              _playerBindTurns = 1;
              effectLog = " Kamu Terikat!";
            } else if (chosenMove.name == 'Paralysis' ||
                chosenMove.effect == 'Paralysis 1 turn') {
              _playerParalysisTurns = 1;
              effectLog = " Kamu terkena Paralysis!";
            } else if (chosenMove.name == 'Grounding' ||
                chosenMove.effect == 'Miss 2 turn') {
              _enemyInvulnerableTurns = 2;
              effectLog = " Musuh bersembunyi (Invulnerable 2 Turn)!";
            } else if (chosenMove.name == 'Fly Away' ||
                chosenMove.effect == 'Miss 1 turn') {
              _enemyInvulnerableTurns = 1;
              effectLog = " Musuh terbang tinggi (Invulnerable 1 Turn)!";
            } else if (chosenMove.name == 'Absorb' ||
                chosenMove.effect == 'Drain HP & Heal') {
              int combo = min(_enemyConsecutiveAbsorb, 3);
              int bonus = (combo - 1) * 2;
              enemyDamage += bonus; // Tambahkan bonus ke total damage
              int healAmount = enemyDamage; // Heal disesuaikan dengan damage
              _oldEnemyHp = _enemyHp;
              _enemyHp = min(_enemyMonster.hp, _enemyHp + healAmount);
              effectLog = " Musuh menyerap $healAmount HP!";
            }
            if (chosenMove.cost < 0 && chosenMove.type != MoveType.recover) {
              effectLog += " Musuh memulihkan ${-chosenMove.cost} stamina!";
            }

            _playerDamageValue = enemyDamage;
            _oldPlayerHp = _playerHp;
            _playerHp = max(0, _playerHp - enemyDamage);
            if (enemyDamage > 0) {
              _playerShakeController.forward(from: 0.0);
            }

            _battleLog =
                statusLog +
                "${_enemyMonster.name} menggunakan ${chosenMove.name}!$elementalLog$effectLog";
          }
        } else {
          // No affordable moves, enemy struggles and recovers a bit of stamina
          _enemyStamina = min(_enemyMonster.stamina, _enemyStamina + 2);
          _battleLog =
              statusLog +
              "${_enemyMonster.name} kehabisan tenaga dan beristirahat!";
        }
      });

      if (_playerHp == 0) {
        _showEndGameDialog(false);
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

    final random = Random();
    int gold = won ? 10 + random.nextInt(20) : 0;
    int exp = won ? 20 + random.nextInt(30) : 5;

    List<Map<String, num>> allLevelUps = [];
    int initialLevel = widget.playerMonster.level;

    // Logika penambahan EXP dan Level Up
    if (won) {
      widget.playerMonster.currentExp += exp;
      while (widget.playerMonster.currentExp >=
          widget.playerMonster.expToNextLevel) {
        int remainingExp =
            widget.playerMonster.currentExp -
            widget.playerMonster.expToNextLevel;

        // Naik Level!
        final statIncreases = widget.playerMonster.levelUp();
        allLevelUps.add(statIncreases);

        widget.playerMonster.currentExp = remainingExp;
        widget.playerMonster.expToNextLevel = Monster.calculateExpForNextLevel(
          widget.playerMonster.level,
        );
      }
    }

    // Simpan progress terbaru pemain (EXP & Level) ke memori internal HP
    SaveManager.saveParty([widget.playerMonster]);

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
                  ? 'Kamu berhasil mengalahkan ${_enemyMonster.name}!'
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
                    widget.playerMonster,
                    initialLevel,
                  ).then((_) {
                    Navigator.pop(
                      context,
                    ); // Kembali ke menu setelah dialog level up
                  });
                } else {
                  Navigator.pop(context); // Langsung kembali ke menu
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

  // Dialog untuk menampilkan kenaikan level
  Future<void> _showLevelUpDialog(
    List<Map<String, num>> allLevelUps,
    Monster monster,
    int initialLevel,
  ) {
    Map<String, num> totalIncreases = {};
    for (var increases in allLevelUps) {
      increases.forEach((key, value) {
        totalIncreases[key] = (totalIncreases[key] ?? 0) + value;
      });
    }

    // Hitung status lama dari status akhir dan total peningkatan
    double oldAttack = monster.attack - (totalIncreases['Attack'] ?? 0);
    double oldDefense = monster.defense - (totalIncreases['Defense'] ?? 0.0);
    int oldHp = monster.hp - (totalIncreases['HP'] ?? 0).toInt();
    int oldSpeed = monster.speed - (totalIncreases['Speed'] ?? 0).toInt();
    int oldStamina = monster.stamina - (totalIncreases['Stamina'] ?? 0).toInt();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '✨ ${monster.name} Naik Level! ✨',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: initialLevel.toDouble(),
                  end: monster.level.toDouble(),
                ),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Text(
                    'Level ${value.toInt()}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 24),
            _buildStatIncreaseRow(
              'HP',
              oldHp,
              monster.hp,
              totalIncreases['HP']!,
            ),
            _buildStatIncreaseRow(
              'Attack',
              oldAttack,
              monster.attack,
              totalIncreases['Attack']!,
            ),
            _buildStatIncreaseRow(
              'Defense',
              oldDefense,
              monster.defense,
              totalIncreases['Defense']!,
            ),
            _buildStatIncreaseRow(
              'Speed',
              oldSpeed,
              monster.speed,
              totalIncreases['Speed']!,
            ),
            _buildStatIncreaseRow(
              'Stamina',
              oldStamina,
              monster.stamina,
              totalIncreases['Stamina']!,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Tambahkan jeda agar animasi stat dapat terlihat
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted) {
                    Navigator.pop(context);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Hebat!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Bantuan untuk baris peningkatan status di dialog
  Widget _buildStatIncreaseRow(
    String label,
    num oldValue,
    num newValue,
    num increase,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(
            width: 120, // Memberi lebar tetap untuk perataan
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: oldValue.toDouble(),
                end: newValue.toDouble(),
              ),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end, // Rata kanan
                  children: [
                    Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Animasi opacity untuk teks (+increase)
                    AnimatedOpacity(
                      opacity: value < newValue.toDouble()
                          ? 1.0
                          : 0.0, // Hilang saat nilai mencapai akhir
                      duration: const Duration(
                        milliseconds: 300,
                      ), // Durasi fade out
                      child: Text(
                        '(+${increase.toInt()})',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
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
      backgroundColor: const Color(0xFFE0F7FA), // Warna biru langit cerah
      body: SafeArea(
        child: Column(
          children: [
            // ARENA PERTARUNGAN (Split Screen Style)
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  // Animasi Clash Layar Diagonal
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _clashController,
                      builder: (context, child) {
                        final linearValue = _clashController.value;
                        // 40% Waktu pertama: Meluncur sebagai persegi dari Atas & Bawah
                        final slideProgress = Curves.easeOut.transform(
                          (linearValue / 0.4).clamp(0.0, 1.0),
                        );
                        // 60% Waktu sisanya: Membelah perlahan menjadi segitiga diagonal
                        final morphProgress = Curves.easeOutBack.transform(
                          ((linearValue - 0.4) / 0.6).clamp(0.0, 1.0),
                        );

                        final slideYTop =
                            -(size.height / 2) * (1 - slideProgress);
                        final slideYBottom =
                            (size.height / 2) * (1 - slideProgress);

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // Sisi Musuh (Top)
                            Transform.translate(
                              offset: Offset(0, slideYTop),
                              child: ClipPath(
                                clipper: DynamicTopClipper(morphProgress),
                                child: Container(
                                  color: _enemyMonster.elementColor,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: -40,
                                        right: -40,
                                        child: Icon(
                                          _getElementIcon(
                                            _enemyMonster.element,
                                          ),
                                          size: 250,
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Sisi Pemain (Bottom)
                            Transform.translate(
                              offset: Offset(0, slideYBottom),
                              child: ClipPath(
                                clipper: DynamicBottomClipper(morphProgress),
                                child: Container(
                                  color: widget.playerMonster.elementColor,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        bottom: -40,
                                        left: -40,
                                        child: Icon(
                                          _getElementIcon(
                                            widget.playerMonster.element,
                                          ),
                                          size: 250,
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Tombol Back
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Animasi Damage Musuh
                  if (_enemyDamageValue > 0)
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.3,
                      right: MediaQuery.of(context).size.width * 0.2,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        onEnd: () => setState(() => _enemyDamageValue = 0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: 1.0 - value, // Fade out
                            child: Transform.translate(
                              offset: Offset(0.0, -50.0 * value), // Move up
                              child: _buildDamageText(_enemyDamageValue),
                            ),
                          );
                        },
                      ),
                    ),

                  // Animasi Damage Pemain
                  if (_playerDamageValue > 0)
                    Positioned(
                      bottom: MediaQuery.of(context).size.height * 0.3,
                      left: MediaQuery.of(context).size.width * 0.2,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        onEnd: () => setState(() => _playerDamageValue = 0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: 1.0 - value, // Fade out
                            child: Transform.translate(
                              offset: Offset(0.0, -50.0 * value), // Move up
                              child: _buildDamageText(_playerDamageValue),
                            ),
                          );
                        },
                      ),
                    ),

                  // --- MUSUH (TOP RIGHT) ---
                  _buildArenaSide(
                    isEnemy: true,
                    monster: _enemyMonster,
                    currentHp: _enemyHp,
                    currentStamina: _enemyStamina,
                  ),

                  // --- PEMAIN (BOTTOM LEFT) ---
                  _buildArenaSide(
                    isEnemy: false,
                    monster: widget.playerMonster,
                    currentHp: _playerHp,
                    currentStamina: _playerStamina,
                  ),
                ],
              ),
            ),

            // BATTLE LOG
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              color: Colors.black87,
              child: TypewriterText(
                // Menggunakan widget teks berjalan
                text: _battleLog,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            // AREA KARTU (HAND)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.grey.shade900,
                child: _isPlayerTurn
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(_currentCards.length, (index) {
                          return _buildAnimatedCard(
                            _currentCards[index],
                            index,
                          );
                        }),
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

  // Widget Bantuan: Kartu dengan Animasi Pop-up dan Flip
  Widget _buildAnimatedCard(MonsterMove move, int index) {
    // Stagger animasi untuk setiap kartu
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

        // Animasi pop-up dari bawah
        final yOffset = (1 - cardProgress) * 150;

        // Animasi flip 3D
        final rotationY = (1 - cardProgress) * (pi / 2);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspektif
            ..translate(0.0, yOffset, 0.0)
            ..rotateY(rotationY),
          child: Opacity(opacity: cardProgress, child: _buildCard(move)),
        );
      },
    );
  }

  // Widget Bantuan: Animasi Goyang (Shake)
  Widget _buildShakeAnimator({
    required AnimationController controller,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final sineValue = sin(pi * 4 * controller.value); // 2 full shakes
        return Transform.translate(
          offset: Offset(sineValue * 8, 0), // Goyang 8 pixel kiri-kanan
          child: child,
        );
      },
    );
  }

  // Widget Bantuan: Membangun satu sisi arena (Pemain atau Musuh)
  Widget _buildArenaSide({
    required bool isEnemy,
    required Monster monster,
    required int currentHp,
    int? currentStamina,
  }) {
    final alignment = isEnemy ? Alignment.topRight : Alignment.bottomLeft;
    final crossAxisAlignment = isEnemy
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final padding = isEnemy
        ? const EdgeInsets.only(top: 32, right: 24)
        : const EdgeInsets.only(bottom: 32, left: 24);

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            // Platform Pijakan Monster
            Container(
              width: 200,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            const SizedBox(height: 16),
            // Health Bar
            _buildShakeAnimator(
              controller: isEnemy
                  ? _enemyShakeController
                  : _playerShakeController,
              child: _buildHealthBar(
                monster,
                currentHp,
                monster.hp,
                currentStamina ?? monster.stamina,
                isEnemy: isEnemy,
              ),
            ),
            // Indikator Status Efek
            if (isEnemy) ...[
              if (_enemyBurnTurns > 0)
                _buildStatusEffectIndicator(
                  'Burn',
                  _enemyBurnTurns,
                  3,
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              if (_enemyBindTurns > 0)
                _buildStatusEffectIndicator(
                  'Bind',
                  _enemyBindTurns,
                  1,
                  Icons.link_off,
                  Colors.blue,
                ), // Mengganti ikon bind
              if (_enemyInvulnerableTurns > 0)
                _buildStatusEffectIndicator(
                  'Miss',
                  _enemyInvulnerableTurns,
                  2,
                  Icons.visibility_off,
                  Colors.grey,
                ),
              if (_enemyParalysisTurns > 0)
                _buildStatusEffectIndicator(
                  'Paralysis',
                  _enemyParalysisTurns,
                  1,
                  Icons.bolt,
                  Colors.amber,
                ),
            ] else ...[
              // Indikator untuk Player
              if (_playerBurnTurns > 0)
                _buildStatusEffectIndicator(
                  'Burn',
                  _playerBurnTurns,
                  3,
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              if (_playerBindTurns > 0)
                _buildStatusEffectIndicator(
                  'Bind',
                  _playerBindTurns,
                  1,
                  Icons.link_off,
                  Colors.blue,
                ),
              if (_playerInvulnerableTurns > 0)
                _buildStatusEffectIndicator(
                  'Miss',
                  _playerInvulnerableTurns,
                  2,
                  Icons.visibility_off,
                  Colors.grey,
                ),
              if (_playerParalysisTurns > 0)
                _buildStatusEffectIndicator(
                  'Paralysis',
                  _playerParalysisTurns,
                  1,
                  Icons.bolt,
                  Colors.amber,
                ),
            ],
          ],
        ),
      ),
    );
  }

  // Widget Bantuan: Teks Damage Animasi
  Widget _buildDamageText(int damage) {
    return Text(
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
    );
  }

  // Widget Bantuan: Health Bar Box
  Widget _buildHealthBar(
    Monster monster,
    int currentHp,
    int maxHp,
    int currentStamina, {
    required bool isEnemy,
  }) {
    double hpPercent = currentHp / maxHp;

    // Ambil nilai HP lama untuk animasi
    int oldHp = isEnemy ? _oldEnemyHp : _oldPlayerHp;
    double oldHpPercent = max(0, oldHp / maxHp);
    double newHpPercent = max(0, currentHp / maxHp);

    return Container(
      padding: const EdgeInsets.all(12),
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _getElementIcon(monster.element),
                    size: 16,
                    color: monster.elementColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    monster.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'Lv${monster.level}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bar HP dengan animasi
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: oldHpPercent, end: newHpPercent),
            duration: const Duration(milliseconds: 800),
            builder: (context, animatedValue, child) {
              Color hpColor = animatedValue > 0.5
                  ? Colors.green
                  : (animatedValue > 0.2 ? Colors.orange : Colors.red);
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: animatedValue,
                  backgroundColor: Colors.grey.shade300,
                  color: hpColor,
                  minHeight: 8,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$currentHp / $maxHp HP',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 12),
          Row(
            children: [
              const Icon(
                Icons.battery_charging_full,
                size: 12,
                color: Colors.teal,
              ),
              const SizedBox(width: 4),
              Text(
                '$currentStamina / ${monster.stamina} SP',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Bantuan: Indikator Status Efek (Burn, Bind)
  Widget _buildStatusEffectIndicator(
    String name,
    int currentTurnsLeft,
    int maxTurns,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // Durasi 2 turn
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            '$currentTurnsLeft Turn(s) $name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Widget Bantuan: Kartu Serangan yang bisa diklik
  Widget _buildCard(MonsterMove move) {
    Color bgColor = Colors.white;
    IconData icon = Icons.sports_mma;

    if (move.type == MoveType.elemental) {
      bgColor = widget.playerMonster.elementColor;
      icon = _getElementIcon(widget.playerMonster.element);
    } else if (move.type == MoveType.special) {
      bgColor = Colors.purple.shade400;
      icon = Icons.auto_awesome;
    } else if (move.type == MoveType.recover) {
      bgColor = Colors.teal.shade300;
      icon = Icons.healing;
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
        width: 130,
        height: 190, // Aspect ratio menyerupai kartu
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16), // Sedikit lebih bulat
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
            // Bagian Atas: Cost Energi (Lebih Bold)
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
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    move.cost > 0 ? '${move.cost}' : '+${-move.cost}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 22, // Ukuran font lebih besar
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Bagian Tengah: Nama Serangan
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
                      fontSize: 18, // Sedikit lebih besar
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

            // Bagian Bawah: Tipe Serangan
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
                  Icon(icon, color: textColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    typeLabel,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
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
}

// ============================================================================
// 3. PVP BATTLE MENU
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
          title: const Text('Room Dibuat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Bagikan kode ini ke temanmu:'),
              const SizedBox(height: 16),
              SelectableText(
                roomCode,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Menunggu lawan bergabung...'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Hapus room dari database jika host membatalkan
                _firestore.collection('rooms').doc(roomCode).delete();
                Navigator.pop(dialogContext);
              },
              child: const Text('Batal', style: TextStyle(color: Colors.red)),
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
        title: const Text('Gabung Room'),
        content: TextField(
          controller: _codeController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Masukkan Kode Room',
            counterText: '',
          ),
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
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
            child: const Text('Gabung'),
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
        title: const Text('PvP Battle'),
        backgroundColor: Colors.purple.shade400,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add_box_rounded),
                label: const Text('Buat Room'),
                onPressed: _createRoom,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.sensor_door_rounded),
                label: const Text('Gabung Room'),
                onPressed: _joinRoom,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 4. PVP BATTLE ARENA (REAL-TIME)
// ============================================================================
class PvPBattleArena extends StatefulWidget {
  final String roomCode;
  final Monster playerMonster;
  final bool isHost;

  const PvPBattleArena({
    super.key,
    required this.roomCode,
    required this.playerMonster,
    required this.isHost,
  });

  @override
  State<PvPBattleArena> createState() => _PvPBattleArenaState();
}

class _PvPBattleArenaState extends State<PvPBattleArena>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Animasi & Deck
  late AnimationController _cardAnimationController;
  late Animation<double> _cardAnimation;
  List<MonsterMove> _currentCards = [];

  late AnimationController _clashController;
  late AnimationController _myShakeController;
  late AnimationController _enemyShakeController;
  // State Lokal Sinkronisasi
  int _myDamageValue = 0;
  int _enemyDamageValue = 0;
  int _oldMyHp = -1;
  int _oldEnemyHp = -1;
  int _localTurnCount = 0;
  int _lastSpecialCardTurn = -14;
  bool _isProcessingTurn = false;

  @override
  void initState() {
    super.initState();
    _oldMyHp = widget.playerMonster.hp;

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _clashController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1400,
      ), // Diperlama untuk 2 fase animasi
    );
    _myShakeController = AnimationController(
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

    // Jika sebagai host (giliran pertama), langsung draw kartu
    if (widget.isHost) {
      _localTurnCount = 1;
      _drawCards();
      _cardAnimationController.forward();
      _clashController.forward();
    }
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _clashController.dispose();
    _myShakeController.dispose();
    _enemyShakeController.dispose();
    super.dispose();
  }

  MonsterElement _getElement(String elementStr) {
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
        return Colors.brown.shade600;
      case MonsterElement.Terbang:
        return Colors.lightBlue.shade100;
    }
  }

  bool _isSuperEffective(MonsterElement attacker, MonsterElement defender) {
    return (attacker == MonsterElement.Api &&
            defender == MonsterElement.Tumbuhan) ||
        (attacker == MonsterElement.Tumbuhan &&
            defender == MonsterElement.Air) ||
        (attacker == MonsterElement.Air && defender == MonsterElement.Api) ||
        (attacker == MonsterElement.Listrik &&
            (defender == MonsterElement.Air ||
                defender == MonsterElement.Terbang)) ||
        (attacker == MonsterElement.Tanah &&
            (defender == MonsterElement.Api ||
                defender == MonsterElement.Listrik)) ||
        (attacker == MonsterElement.Terbang &&
            defender == MonsterElement.Tumbuhan);
  }

  bool _isNotVeryEffective(MonsterElement attacker, MonsterElement defender) {
    return (attacker == MonsterElement.Api && defender == MonsterElement.Air) ||
        (attacker == MonsterElement.Tumbuhan &&
            defender == MonsterElement.Api) ||
        (attacker == MonsterElement.Air &&
            defender == MonsterElement.Tumbuhan) ||
        (attacker == MonsterElement.Listrik &&
            defender == MonsterElement.Tanah) ||
        (attacker == MonsterElement.Tanah &&
            defender == MonsterElement.Tumbuhan) ||
        (attacker == MonsterElement.Terbang &&
            defender == MonsterElement.Listrik);
  }

  bool _isNoEffect(MonsterElement attacker, MonsterElement defender) {
    return (attacker == MonsterElement.Tanah &&
        defender == MonsterElement.Terbang);
  }

  // Menarik 3 kartu acak
  void _drawCards() {
    final random = Random();
    final moves = widget.playerMonster.moves;
    _currentCards.clear();

    final specialMoves = moves
        .where((m) => m.type == MoveType.special)
        .toList();

    if (specialMoves.isNotEmpty &&
        (_localTurnCount - _lastSpecialCardTurn) >= 15) {
      _currentCards.add(specialMoves[random.nextInt(specialMoves.length)]);
      _lastSpecialCardTurn = _localTurnCount;
    }

    List<MonsterMove> fillPool = moves
        .where((m) => m.type != MoveType.special)
        .toList();
    fillPool.shuffle();

    while (_currentCards.length < 3 && moves.isNotEmpty) {
      var availableMoves = moves
          .where((m) => !_currentCards.contains(m))
          .toList();
      if (availableMoves.isEmpty) break;
      _currentCards.add(availableMoves[random.nextInt(availableMoves.length)]);
    }
    _currentCards.shuffle();
  }

  // Formula Damage Persis dengan Wild Arena
  Map<String, dynamic> _calculateDamage(
    Map<String, dynamic> attacker,
    Map<String, dynamic> defender,
    MonsterMove move,
  ) {
    int invulnerableTurns = defender['invulnerableTurns'] ?? 0;
    if (invulnerableTurns > 0 && move.type != MoveType.recover) {
      return {'damage': 0, 'log': ' Serangan meleset (Invulnerable)!'};
    }

    final random = Random();
    MonsterElement attackerElement = _getElement(attacker['element']);
    MonsterElement defenderElement = _getElement(defender['element']);

    if (defenderElement == MonsterElement.Terbang &&
        random.nextInt(100) < 10 &&
        move.type != MoveType.recover) {
      return {'damage': 0, 'log': ' Serangan berhasil dihindari (Evasiness)!'};
    }

    MonsterElement? moveElement;
    if (move.type == MoveType.elemental || move.type == MoveType.special) {
      moveElement = attackerElement;
    }

    if (moveElement != null && _isNoEffect(moveElement, defenderElement)) {
      return {'damage': 0, 'log': ' Tidak ada efek pada tipe ini!'};
    }

    double typeModifier = 1.0;
    String typeLog = "";
    if (moveElement != null) {
      if (_isSuperEffective(moveElement, defenderElement)) {
        typeModifier = 2.0;
        typeLog = " Super Efektif!";
      } else if (_isNotVeryEffective(moveElement, defenderElement)) {
        typeModifier = 1.25;
        typeLog = " Kurang Efektif...";
      } else if (moveElement == defenderElement) {
        typeModifier = 1.5;
        typeLog = " Efektif.";
      }
    }

    double stabModifier = 1.0;
    if (moveElement != null && moveElement == attackerElement)
      stabModifier = 1.5;

    double critModifier = 1.0;
    bool isCritical = random.nextInt(100) < 10;
    if (isCritical) critModifier = 1.5;

    double randomModifier = 0.85 + random.nextDouble() * 0.15;

    double effectiveDefense = (defender['defense'] as num).toDouble();
    if ((defender['bindTurns'] ?? 0) > 0) {
      effectiveDefense *= 0.9;
    }

    double baseDamage =
        (((2 * (attacker['level'] as num) / 5 + 2) *
                move.power *
                ((attacker['attack'] as num) / effectiveDefense)) /
            40) +
        2;

    double finalDamageDouble =
        baseDamage *
        typeModifier *
        stabModifier *
        critModifier *
        randomModifier;

    // Bonus damage 10% untuk serangan elemen jika musuh sedang terkena Burn
    if ((defender['burnTurns'] ?? 0) > 0 && move.type == MoveType.elemental) {
      finalDamageDouble *= 1.1;
      typeLog += " (Bonus Burn +10% DMG!)";
      if (moveElement == MonsterElement.Api) {
        finalDamageDouble += 2;
        typeLog += " (+2 DMG Api!)";
      }
    }

    String critLog = isCritical ? " Serangan Kritis!" : "";

    return {'damage': finalDamageDouble.floor(), 'log': typeLog + critLog};
  }

  void _playTurn(
    MonsterMove move,
    Map<String, dynamic> myData,
    Map<String, dynamic> enemyData,
  ) async {
    if (_isProcessingTurn) return;
    _isProcessingTurn = true;

    int myHp = myData['hp'];
    int myStamina = myData['stamina'];
    int myBurn = myData['burnTurns'] ?? 0;
    int myBind = myData['bindTurns'] ?? 0;
    int myParalysis = myData['paralysisTurns'] ?? 0;
    int myInvulnerable = myData['invulnerableTurns'] ?? 0;
    int myAbsorb = myData['consecutiveAbsorb'] ?? 0;

    int enemyHp = enemyData['hp'];
    int enemyBurn = enemyData['burnTurns'] ?? 0;
    int enemyBind = enemyData['bindTurns'] ?? 0;
    int enemyParalysis = enemyData['paralysisTurns'] ?? 0;
    int enemyInvulnerable = enemyData['invulnerableTurns'] ?? 0;

    String myRole = widget.isHost ? 'host' : 'guest';
    String enemyRole = widget.isHost ? 'guest' : 'host';
    String statusLog = "";

    if (myInvulnerable > 0) myInvulnerable--;

    // 1. Cek Skip Turn (Bind & Paralysis)
    bool isSkippingTurn = false;
    if (myBind > 0 || myParalysis > 0) {
      if (myBind > 0) {
        myBind--;
        statusLog = "${myData['name']} terikat dan tidak bisa bergerak! ";
      } else {
        myParalysis--;
        statusLog =
            "${myData['name']} terkena Paralysis dan tidak bisa bergerak! ";
      }
      isSkippingTurn = true;
    }

    if (isSkippingTurn) {
      if (myBurn > 0) {
        myHp = max(0, myHp - 5);
        myBurn--;
        statusLog += "Terkena 5 damage Burn. ";
      }

      await _firestore.collection('rooms').doc(widget.roomCode).update({
        '$myRole.hp': myHp,
        '$myRole.burnTurns': myBurn,
        '$myRole.bindTurns': myBind,
        '$myRole.paralysisTurns': myParalysis,
        '$myRole.invulnerableTurns': myInvulnerable,
        'currentTurn': myHp <= 0 ? 'finished' : enemyRole,
        'turnCount': FieldValue.increment(1),
        'log': statusLog.trim(),
        'status': myHp <= 0 ? 'finished' : 'playing',
      });
      _isProcessingTurn = false;
      return;
    }

    // 2. Cek Burn
    if (myBurn > 0) {
      myHp = max(0, myHp - 5);
      myBurn--;
      statusLog = "Kamu terkena 5 damage Burn! ";
      if (myHp <= 0) {
        await _firestore.collection('rooms').doc(widget.roomCode).update({
          '$myRole.hp': 0,
          '$myRole.burnTurns': myBurn,
          '$myRole.invulnerableTurns': myInvulnerable,
          '$myRole.paralysisTurns': myParalysis,
          'status': 'finished',
          'log': statusLog + "${myData['name']} kehabisan HP karena Burn!",
        });
        _isProcessingTurn = false;
        return;
      }
    }

    if (move.name == 'Absorb' || move.effect == 'Drain HP & Heal') {
      myAbsorb++;
    } else {
      myAbsorb = 0;
    }

    if (move.cost > myStamina) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stamina tidak cukup!')));
      _isProcessingTurn = false;
      return;
    }

    myStamina = min(
      (myData['maxStamina'] as num).toInt(),
      myStamina - move.cost,
    );

    if (move.type == MoveType.recover) {
      await _firestore.collection('rooms').doc(widget.roomCode).update({
        '$myRole.hp': myHp,
        '$myRole.stamina': myStamina,
        '$myRole.burnTurns': myBurn,
        '$myRole.paralysisTurns': myParalysis,
        '$myRole.invulnerableTurns': myInvulnerable,
        'currentTurn': enemyRole,
        'turnCount': FieldValue.increment(1),
        'log':
            statusLog +
            "${myData['name']} fokus dan memulihkan ${-move.cost} stamina!",
      });
      _isProcessingTurn = false;
      return;
    }

    final damageResult = _calculateDamage(myData, enemyData, move);
    int damage = damageResult['damage'];
    String elementalLog = damageResult['log'];

    String effectLog = "";
    if (move.name == 'Flame Spin' || move.effect == 'Burn 3 turn') {
      enemyBurn = 3;
      effectLog = " Musuh terkena Burn!";
    } else if (move.name == 'Bind' || move.effect == 'Bind 1 turn') {
      enemyBind = 1;
      effectLog = " Musuh Terikat!";
    } else if (move.name == 'Paralysis' || move.effect == 'Paralysis 1 turn') {
      enemyParalysis = 1;
      effectLog = " Musuh terkena Paralysis!";
    } else if (move.name == 'Grounding' || move.effect == 'Miss 2 turn') {
      myInvulnerable = 2;
      effectLog = " Kamu bersembunyi (Invulnerable 2 Turn)!";
    } else if (move.name == 'Fly Away' || move.effect == 'Miss 1 turn') {
      myInvulnerable = 1;
      effectLog = " Kamu terbang tinggi (Invulnerable 1 Turn)!";
    } else if (move.name == 'Absorb' || move.effect == 'Drain HP & Heal') {
      int combo = min(myAbsorb, 3);
      int bonus = (combo - 1) * 2;
      damage += bonus; // Tambahkan bonus combo
      int healAmount = damage; // Heal disesuaikan dengan damage
      myHp = min((myData['maxHp'] as num).toInt(), myHp + healAmount);
      effectLog = " Kamu menyerap $healAmount HP!";
    }
    if (move.cost < 0 && move.type != MoveType.recover) {
      effectLog += " Kamu memulihkan ${-move.cost} stamina!";
    }

    enemyHp = max(0, enemyHp - damage);

    await _firestore.collection('rooms').doc(widget.roomCode).update({
      '$myRole.hp': myHp,
      '$myRole.stamina': myStamina,
      '$myRole.burnTurns': myBurn,
      '$myRole.bindTurns': myBind,
      '$myRole.paralysisTurns': myParalysis,
      '$myRole.invulnerableTurns': myInvulnerable,
      '$myRole.consecutiveAbsorb': myAbsorb,
      '$enemyRole.hp': enemyHp,
      '$enemyRole.burnTurns': enemyBurn,
      '$enemyRole.bindTurns': enemyBind,
      '$enemyRole.paralysisTurns': enemyParalysis,
      '$enemyRole.invulnerableTurns': enemyInvulnerable,
      'currentTurn': enemyHp <= 0 ? 'finished' : enemyRole,
      'turnCount': FieldValue.increment(1),
      'log':
          statusLog +
          "${myData['name']} menggunakan ${move.name}!$elementalLog$effectLog",
      'status': enemyHp <= 0 ? 'finished' : 'playing',
    });
    _isProcessingTurn = false;
  }

  void _showEndGameDialog(bool won) {
    // Simulasi hadiah kecil untuk PvP agar ada rasa penghargaan
    int exp = won ? 15 : 5;
    List<Map<String, num>> allLevelUps = [];
    int initialLevel = widget.playerMonster.level;

    if (won) {
      widget.playerMonster.currentExp += exp;
      while (widget.playerMonster.currentExp >=
          widget.playerMonster.expToNextLevel) {
        int remainingExp =
            widget.playerMonster.currentExp -
            widget.playerMonster.expToNextLevel;
        allLevelUps.add(widget.playerMonster.levelUp());
        widget.playerMonster.currentExp = remainingExp;
        widget.playerMonster.expToNextLevel = Monster.calculateExpForNextLevel(
          widget.playerMonster.level,
        );
      }
    }

    // Simpan progress PvP ke memori internal HP
    SaveManager.saveParty([widget.playerMonster]);

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
                  ? 'Kamu memenangkan pertarungan PvP!'
                  : 'Kamu dikalahkan lawan.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '+ $exp EXP',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                if (allLevelUps.isNotEmpty) {
                  _showLevelUpDialog(
                    allLevelUps,
                    widget.playerMonster,
                    initialLevel,
                  ).then((_) {
                    Navigator.pop(context); // Kembali ke menu
                  });
                } else {
                  Navigator.pop(context); // Langsung ke menu
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: won ? Colors.green : Colors.grey,
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

  // Dialog untuk menampilkan kenaikan level (Diadaptasi dari WildBattle)
  Future<void> _showLevelUpDialog(
    List<Map<String, num>> allLevelUps,
    Monster monster,
    int initialLevel,
  ) {
    Map<String, num> totalIncreases = {};
    for (var increases in allLevelUps) {
      increases.forEach((key, value) {
        totalIncreases[key] = (totalIncreases[key] ?? 0) + value;
      });
    }

    // Hitung status lama dari status akhir dan total peningkatan
    double oldAttack = monster.attack - (totalIncreases['Attack'] ?? 0);
    double oldDefense = monster.defense - (totalIncreases['Defense'] ?? 0.0);
    int oldHp = monster.hp - (totalIncreases['HP'] ?? 0).toInt();
    int oldSpeed = monster.speed - (totalIncreases['Speed'] ?? 0).toInt();
    int oldStamina = monster.stamina - (totalIncreases['Stamina'] ?? 0).toInt();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '✨ ${monster.name} Naik Level! ✨',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: initialLevel.toDouble(),
                  end: monster.level.toDouble(),
                ),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Text(
                    'Level ${value.toInt()}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 24),
            _buildStatIncreaseRow(
              'HP',
              oldHp,
              monster.hp,
              totalIncreases['HP']!,
            ),
            _buildStatIncreaseRow(
              'Attack',
              oldAttack,
              monster.attack,
              totalIncreases['Attack']!,
            ),
            _buildStatIncreaseRow(
              'Defense',
              oldDefense,
              monster.defense,
              totalIncreases['Defense']!,
            ),
            _buildStatIncreaseRow(
              'Speed',
              oldSpeed,
              monster.speed,
              totalIncreases['Speed']!,
            ),
            _buildStatIncreaseRow(
              'Stamina',
              oldStamina,
              monster.stamina,
              totalIncreases['Stamina']!,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Tambahkan jeda agar animasi stat dapat terlihat
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted) {
                    Navigator.pop(context);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Hebat!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Bantuan untuk baris peningkatan status di dialog
  Widget _buildStatIncreaseRow(
    String label,
    num oldValue,
    num newValue,
    num increase,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(
            width: 120, // Memberi lebar tetap untuk perataan
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: oldValue.toDouble(),
                end: newValue.toDouble(),
              ),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end, // Rata kanan
                  children: [
                    Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Animasi opacity untuk teks (+increase)
                    AnimatedOpacity(
                      opacity: value < newValue.toDouble()
                          ? 1.0
                          : 0.0, // Hilang saat nilai mencapai akhir
                      duration: const Duration(
                        milliseconds: 300,
                      ), // Durasi fade out
                      child: Text(
                        '(+${increase.toInt()})',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget Bantuan: Animasi Goyang (Shake)
  Widget _buildShakeAnimator({
    required AnimationController controller,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final sineValue = sin(pi * 4 * controller.value); // 2 full shakes
        return Transform.translate(
          offset: Offset(sineValue * 8, 0), // Goyang 8 pixel kiri-kanan
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('rooms')
              .doc(widget.roomCode)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data == null)
              return const Center(
                child: Text('Room telah ditutup atau tidak ditemukan'),
              );

            final hostData = data['host'];
            final guestData = data['guest'];

            if (guestData == null)
              return const Center(child: Text('Menunggu sinkronisasi...'));

            final myData = widget.isHost ? hostData : guestData;
            final enemyData = widget.isHost ? guestData : hostData;

            // Setup inisiasi HP untuk deteksi damage
            if (_oldEnemyHp == -1) _oldEnemyHp = enemyData['hp'];

            // Cek Trigger Damage Animasi
            int currentMyHp = myData['hp'];
            int currentEnemyHp = enemyData['hp'];

            if (_oldMyHp != -1 && currentMyHp < _oldMyHp) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _myDamageValue = _oldMyHp - currentMyHp);
                  _myShakeController.forward(from: 0.0);
                }
              });
            }
            if (_oldEnemyHp != -1 && currentEnemyHp < _oldEnemyHp) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(
                    () => _enemyDamageValue = _oldEnemyHp - currentEnemyHp,
                  );
                  _enemyShakeController.forward(from: 0.0);
                }
              });
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _oldMyHp = currentMyHp;
              _oldEnemyHp = currentEnemyHp;
            });

            final bool isMyTurn =
                data['currentTurn'] == (widget.isHost ? 'host' : 'guest');
            final String battleLog = data['log'] ?? "Pertarungan dimulai!";
            final bool isFinished = data['status'] == 'finished';
            int serverTurnCount = data['turnCount'] ?? 1;

            // Cek Pergantian Turn untuk Draw Card
            if (isMyTurn && serverTurnCount > _localTurnCount && !isFinished) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted)
                  setState(() {
                    _localTurnCount = serverTurnCount;
                    _drawCards();
                    _cardAnimationController.forward(from: 0.0);
                  });
              });
            }

            return Column(
              children: [
                // ARENA (Atas: Musuh, Bawah: Kita)
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      // Animasi Clash Layar Diagonal
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _clashController,
                          builder: (context, child) {
                            final linearValue = _clashController.value;
                            // 40% Waktu pertama: Meluncur sebagai persegi
                            final slideProgress = Curves.easeOut.transform(
                              (linearValue / 0.4).clamp(0.0, 1.0),
                            );
                            // 60% Waktu sisanya: Membelah (morph) menjadi segitiga
                            final morphProgress = Curves.easeOutBack.transform(
                              ((linearValue - 0.4) / 0.6).clamp(0.0, 1.0),
                            );

                            final slideYTop =
                                -(size.height / 2) * (1 - slideProgress);
                            final slideYBottom =
                                (size.height / 2) * (1 - slideProgress);

                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                // Musuh (Top)
                                Transform.translate(
                                  offset: Offset(0, slideYTop),
                                  child: ClipPath(
                                    clipper: DynamicTopClipper(morphProgress),
                                    child: Container(
                                      color: _getElementColor(
                                        _getElement(enemyData['element']),
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            top: -40,
                                            right: -40,
                                            child: Icon(
                                              _getElementIcon(
                                                _getElement(
                                                  enemyData['element'],
                                                ),
                                              ),
                                              size: 250,
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Pemain (Bottom)
                                Transform.translate(
                                  offset: Offset(0, slideYBottom),
                                  child: ClipPath(
                                    clipper: DynamicBottomClipper(
                                      morphProgress,
                                    ),
                                    child: Container(
                                      color: _getElementColor(
                                        _getElement(myData['element']),
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            bottom: -40,
                                            left: -40,
                                            child: Icon(
                                              _getElementIcon(
                                                _getElement(myData['element']),
                                              ),
                                              size: 250,
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // Tombol Keluar (Hanya untuk kabur)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: IconButton(
                          icon: const Icon(
                            Icons.exit_to_app,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            if (widget.isHost) {
                              _firestore
                                  .collection('rooms')
                                  .doc(widget.roomCode)
                                  .delete();
                            }
                            Navigator.pop(context);
                          },
                        ),
                      ),

                      // Animasi Damage Musuh
                      if (_enemyDamageValue > 0)
                        Positioned(
                          top: size.height * 0.3,
                          right: size.width * 0.2,
                          child: _buildDamageTextAnimation(
                            _enemyDamageValue,
                            isEnemy: true,
                          ),
                        ),

                      // Animasi Damage Pemain
                      if (_myDamageValue > 0)
                        Positioned(
                          bottom: size.height * 0.3,
                          left: size.width * 0.2,
                          child: _buildDamageTextAnimation(
                            _myDamageValue,
                            isEnemy: false,
                          ),
                        ),

                      // --- MUSUH (TOP RIGHT) ---
                      _buildArenaSide(isEnemy: true, data: enemyData),

                      // --- PEMAIN (BOTTOM LEFT) ---
                      _buildArenaSide(isEnemy: false, data: myData),
                    ],
                  ),
                ),

                // BATTLE LOG
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.black87,
                  child: TypewriterText(
                    text: battleLog,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                // AREA KARTU / KONTROL
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade900,
                    child: isFinished
                        ? Center(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Pertarungan Selesai - Kembali',
                              ),
                            ),
                          )
                        : isMyTurn
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(_currentCards.length, (
                              index,
                            ) {
                              return _buildAnimatedCard(
                                _currentCards[index],
                                myData,
                                enemyData,
                                index,
                              );
                            }),
                          )
                        : const Center(
                            child: Text(
                              'Menunggu giliran lawan...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDamageTextAnimation(int damage, {required bool isEnemy}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      onEnd: () {
        if (mounted) {
          setState(() {
            if (isEnemy) {
              _enemyDamageValue = 0;
            } else {
              _myDamageValue = 0;
            }
          });
        }
      },
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

  Widget _buildAnimatedCard(
    MonsterMove move,
    Map<String, dynamic> myData,
    Map<String, dynamic> enemyData,
    int index,
  ) {
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
          child: Opacity(
            opacity: cardProgress,
            child: GestureDetector(
              onTap: () => _playTurn(move, myData, enemyData),
              child: _buildCard(move),
            ),
          ),
        );
      },
    );
  }

  Widget _buildArenaSide({
    required bool isEnemy,
    required Map<String, dynamic> data,
  }) {
    final alignment = isEnemy ? Alignment.topRight : Alignment.bottomLeft;
    final crossAxisAlignment = isEnemy
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final padding = isEnemy
        ? const EdgeInsets.only(top: 32, right: 24)
        : const EdgeInsets.only(bottom: 32, left: 24);
    int burnTurns = data['burnTurns'] ?? 0;
    int bindTurns = data['bindTurns'] ?? 0;
    int paralysisTurns = data['paralysisTurns'] ?? 0;
    int invulnerableTurns = data['invulnerableTurns'] ?? 0;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            Container(
              width: 200,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            const SizedBox(height: 16),
            _buildShakeAnimator(
              controller: isEnemy ? _enemyShakeController : _myShakeController,
              child: _buildHealthBarBox(data, isEnemy),
            ),
            if (burnTurns > 0)
              _buildStatusEffectIndicator(
                'Burn',
                burnTurns,
                3,
                Icons.local_fire_department,
                Colors.orange,
              ),
            if (bindTurns > 0)
              _buildStatusEffectIndicator(
                'Bind',
                bindTurns,
                3,
                Icons.link_off,
                Colors.blue,
              ),
            if (paralysisTurns > 0)
              _buildStatusEffectIndicator(
                'Paralysis',
                paralysisTurns,
                1,
                Icons.bolt,
                Colors.amber,
              ),
            if (invulnerableTurns > 0)
              _buildStatusEffectIndicator(
                'Miss',
                invulnerableTurns,
                2,
                Icons.visibility_off,
                Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthBarBox(Map<String, dynamic> data, bool isEnemy) {
    MonsterElement element = _getElement(data['element']);
    int currentHp = data['hp'];
    int maxHp = data['maxHp'];
    double newHpPercent = max(0, currentHp / maxHp);
    int oldHpTracker = isEnemy ? _oldEnemyHp : _oldMyHp;
    double oldHpPercent = oldHpTracker != -1
        ? max(0, oldHpTracker / maxHp)
        : newHpPercent;

    return Container(
      padding: const EdgeInsets.all(12),
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _getElementIcon(element),
                    size: 16,
                    color: _getElementColor(element),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    data['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'Lv${data['level']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: oldHpPercent, end: newHpPercent),
            duration: const Duration(milliseconds: 800),
            builder: (context, animatedValue, child) {
              Color hpColor = animatedValue > 0.5
                  ? Colors.green
                  : (animatedValue > 0.2 ? Colors.orange : Colors.red);
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: animatedValue,
                  backgroundColor: Colors.grey.shade300,
                  color: hpColor,
                  minHeight: 8,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$currentHp / $maxHp HP',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 12),
          Row(
            children: [
              const Icon(
                Icons.battery_charging_full,
                size: 12,
                color: Colors.teal,
              ),
              const SizedBox(width: 4),
              Text(
                '${data['stamina']} / ${data['maxStamina']} SP',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusEffectIndicator(
    String name,
    int currentTurnsLeft,
    int maxTurns,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            '$currentTurnsLeft Turn(s) $name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(MonsterMove move) {
    Color bgColor = Colors.white;
    IconData icon = Icons.sports_mma;

    if (move.type == MoveType.elemental) {
      bgColor = widget.playerMonster.elementColor;
      icon = _getElementIcon(widget.playerMonster.element);
    } else if (move.type == MoveType.special) {
      bgColor = Colors.purple.shade400;
      icon = Icons.auto_awesome;
    } else if (move.type == MoveType.recover) {
      bgColor = Colors.teal.shade300;
      icon = Icons.healing;
    }

    String typeLabel = move.type == MoveType.elemental
        ? 'ELEMENT'
        : (move.type == MoveType.special ? 'SPECIAL' : 'NORMAL');
    if (move.type == MoveType.recover) typeLabel = 'RECOVER';
    Color textColor = move.type == MoveType.normal
        ? Colors.black87
        : Colors.white;

    return Container(
      width: 130,
      height: 190,
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
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  move.cost > 0 ? '${move.cost}' : '+${-move.cost}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
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
                    fontSize: 18,
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
                Icon(icon, color: textColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  typeLabel,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
