part of 'battle_arena.dart';

class AsymmetricDiagonalClipper extends CustomClipper<Path> {
  final bool isTop;
  final double progress; // 0.0 to 1.0 (morph progress)

  AsymmetricDiagonalClipper({required this.isTop, required this.progress});

  @override
  Path getClip(Size size) {
    final path = Path();
    // Menggeser center sedikit ke bawah (5% offset) untuk memberikan porsi 55% area atas
    double currentAvgY = size.height * 0.5 + (size.height * 0.05 * progress);
    double currentDy =
        size.width *
        0.53 *
        progress; // Miring lebih landai (sekitar 28 derajat)

    double yLeft = currentAvgY - (currentDy / 2);
    double yRight = currentAvgY + (currentDy / 2);

    if (isTop) {
      path.lineTo(size.width, 0);
      path.lineTo(size.width, yRight);
      path.lineTo(0, yLeft);
      path.close();
    } else {
      path.moveTo(0, yLeft);
      path.lineTo(size.width, yRight);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(AsymmetricDiagonalClipper oldClipper) =>
      oldClipper.progress != progress || oldClipper.isTop != isTop;
}

// WIDGET KUSTOM: Progress Bar yang dijamin 100% mulus anti loncat
// Secara otomatis melanjutkan animasi dari sisa persen sebelumnya
class SmoothProgressBar extends ImplicitlyAnimatedWidget {
  final double value;
  final Color backgroundColor;
  final Color baseColor;
  final double minHeight;
  final bool isHealthBar;

  const SmoothProgressBar({
    super.key,
    required this.value,
    required this.backgroundColor,
    required this.baseColor,
    required this.minHeight,
    this.isHealthBar = false,
    super.duration = const Duration(milliseconds: 800),
    super.curve = Curves.easeOutCubic,
  });

  @override
  ImplicitlyAnimatedWidgetState<SmoothProgressBar> createState() =>
      _SmoothProgressBarState();
}

class _SmoothProgressBarState
    extends AnimatedWidgetBaseState<SmoothProgressBar> {
  Tween<double>? _valueTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _valueTween =
        visitor(
              _valueTween,
              widget.value,
              (dynamic value) => Tween<double>(begin: value as double),
            )
            as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    double animatedValue = _valueTween?.evaluate(animation) ?? widget.value;

    Color progressColor = widget.baseColor;
    if (widget.isHealthBar) {
      progressColor = animatedValue > 0.5
          ? Colors.greenAccent
          : (animatedValue > 0.2 ? Colors.orangeAccent : Colors.redAccent);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.minHeight / 2),
      child: LinearProgressIndicator(
        value: animatedValue,
        backgroundColor: widget.backgroundColor,
        color: progressColor,
        minHeight: widget.minHeight,
      ),
    );
  }
}

/// Mixin berisi semua fungsi bantuan UI dan logika elemen dasar yang di-share
/// ke WildBattleArena, PvPBattleArena, dan InfiniteTowerBattleArena
mixin BattleSharedMixin<T extends StatefulWidget> on State<T> {
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
            (defender == MonsterElement.Air ||
                defender == MonsterElement.Tanah)) ||
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
        (attacker == MonsterElement.Tanah &&
            defender == MonsterElement.Tumbuhan) ||
        (attacker == MonsterElement.Terbang &&
            defender == MonsterElement.Listrik);
  }

  bool _isNoEffect(MonsterElement attacker, MonsterElement defender) {
    return (attacker == MonsterElement.Tanah &&
            defender == MonsterElement.Terbang) ||
        (attacker == MonsterElement.Listrik &&
            defender == MonsterElement.Tanah);
  }

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
              increase: totalIncreases['HP']!,
            ),
            _buildStatIncreaseRow(
              'Attack',
              oldAttack,
              monster.attack,
              increase: totalIncreases['Attack']!,
            ),
            _buildStatIncreaseRow(
              'Defense',
              oldDefense,
              monster.defense,
              increase: totalIncreases['Defense']!,
            ),
            _buildStatIncreaseRow(
              'Speed',
              oldSpeed,
              monster.speed,
              increase: totalIncreases['Speed']!,
            ),
            _buildStatIncreaseRow(
              'Stamina',
              oldStamina,
              monster.stamina,
              increase: totalIncreases['Stamina']!,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
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

  Widget _buildStatIncreaseRow(
    String label,
    num oldValue,
    num newValue, {
    num? increase,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(
            width: 120,
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: oldValue.toDouble(),
                end: newValue.toDouble(),
              ),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
                    if (increase != null)
                      AnimatedOpacity(
                        opacity: value < newValue.toDouble() ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
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

  Widget _buildShakeAnimator({
    required AnimationController controller,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final sineValue = sin(pi * 4 * controller.value);
        return Transform.translate(
          offset: Offset(sineValue * 8, 0),
          child: child,
        );
      },
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
            // Simplified text
            '$name: $currentTurnsLeft turn${currentTurnsLeft > 1 ? 's' : ''}',
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

  String _getImagePath(MonsterElement element, bool isEnemy) {
    final suffix = isEnemy ? '_front.png' : '_back.png';
    switch (element) {
      case MonsterElement.Api:
        return 'assets/images/fire_monster$suffix';
      case MonsterElement.Air:
        return 'assets/images/water_monster$suffix';
      case MonsterElement.Tumbuhan:
        return 'assets/images/plant_monster$suffix';
      case MonsterElement.Listrik:
        return 'assets/images/electric_monster$suffix';
      case MonsterElement.Tanah:
        return 'assets/images/ground_monster$suffix';
      case MonsterElement.Terbang:
        return 'assets/images/flying_monster$suffix';
    }
  }

  Widget _buildMonsterSpriteCore({
    required MonsterElement element,
    required bool isEnemy,
    required AnimationController shakeController,
  }) {
    return _buildShakeAnimator(
      controller: shakeController,
      // Menggunakan SizedBox berukuran tetap agar gambar yang di-crop
      // tidak mengubah ukuran layout keseluruhan dan bayangan tidak lari ke tengah!
      child: SizedBox(
        width: 220,
        height: 280,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Platform / Bayangan
            Positioned(
              bottom: 0,
              child: Container(
                width: 200,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: const BorderRadius.all(
                    Radius.elliptical(200, 28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            // Monster Image
            Positioned(
              bottom:
                  14, // Angkat 14px agar telapak kaki persis menapak di tengah bayangan oval (28 / 2 = 14)
              child: SizedBox(
                width: 300, // Ruang horizontal lega
                height: 280,
                child: Image.asset(
                  _getImagePath(element, isEnemy),
                  fit: BoxFit.contain,
                  alignment: Alignment
                      .bottomCenter, // Memaksa gambar selalu nempel ke batas bawah Positioned
                  errorBuilder: (context, error, stackTrace) => Icon(
                    _getElementIcon(element),
                    size: 150,
                    color: _getElementColor(element),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticHUDCore({
    required String name,
    required int level,
    required MonsterElement element,
    required int currentHp,
    required int maxHp,
    required int currentStamina,
    required int maxStamina,
    required bool isEnemy,
    required int oldHp,
    required List<Widget> statusEffects,
  }) {
    Color elementColor = _getElementColor(element);
    double newHpPercent = max(0, currentHp / maxHp);
    double newStaminaPercent = maxStamina > 0
        ? currentStamina / maxStamina
        : 0.0;

    return Column(
      key: ValueKey('${name}_$maxHp'),
      crossAxisAlignment: isEnemy
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          width: 180,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24).withOpacity(0.85),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isEnemy ? 16 : 4),
              bottomRight: Radius.circular(isEnemy ? 4 : 16),
            ),
            border: Border.all(color: elementColor.withOpacity(0.7), width: 2),
            boxShadow: [
              BoxShadow(
                color: elementColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          _getElementIcon(element),
                          size: 14,
                          color: elementColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Lv$level',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 👇 INI ADALAH BAGIAN YANG MENGATUR ANIMASI HEALTH BAR 👇
              SmoothProgressBar(
                value: newHpPercent,
                backgroundColor: Colors.grey.shade800,
                baseColor: Colors.greenAccent,
                minHeight: 8,
                isHealthBar: true,
              ),
              // 👆 =================================================== 👆
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$currentHp / $maxHp HP',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 10, color: Colors.white24),
              Row(
                children: [
                  const Icon(
                    Icons.battery_charging_full,
                    size: 12,
                    color: Colors.cyanAccent,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    // Bar SP/Stamina dengan logika animasi serupa
                    child: SmoothProgressBar(
                      value: newStaminaPercent,
                      backgroundColor: Colors.grey.shade800,
                      baseColor: Colors.cyan,
                      minHeight: 4,
                      isHealthBar: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$currentStamina SP',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (statusEffects.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(spacing: 6, runSpacing: 6, children: statusEffects),
          ),
      ],
    );
  }
}

class WildBattleArena extends StatefulWidget {
  final Monster playerMonster;
  final List<Monster> party;
  final Function(bool won) onBattleEnd;

  const WildBattleArena({
    super.key,
    required this.playerMonster,
    required this.party,
    required this.onBattleEnd,
  });

  @override
  State<WildBattleArena> createState() => _WildBattleArenaState();
}

class _WildBattleArenaState extends State<WildBattleArena>
    with TickerProviderStateMixin, BattleSharedMixin<WildBattleArena> {
  late Monster _activeMonster;
  late Monster _enemyMonster;

  final Map<Monster, int> _partyHp = {};
  final Map<Monster, int> _partyStamina = {};

  // Status HP
  late int _playerHp;
  late int _enemyHp;
  late int _oldPlayerHp; // Untuk animasi bar HP
  late int _oldEnemyHp; // Untuk animasi bar HP
  late int _playerStamina, _enemyStamina;

  // Sistem Kartu (Deck)
  final List<MonsterMove> _currentCards = [];
  bool _isPlayerTurn = true;
  bool _isCaptureMode = false;
  bool _isSwitchMode = false;
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

  bool _isLoading = true; // Menyimpan status loading file

  // Daftar Bola
  final List<Map<String, dynamic>> _captureBalls = [
    {'name': 'Basic Ball', 'bonus': 1.0, 'color': Colors.red, 'quantity': 10},
    {'name': 'Power Ball', 'bonus': 1.5, 'color': Colors.blue, 'quantity': 5},
    {'name': 'Locked Ball', 'bonus': 2.0, 'color': Colors.amber, 'quantity': 3},
  ];

  // Fungsi untuk memuat jumlah bola dari memori internal
  Future<void> _loadBalls() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _captureBalls[0]['quantity'] = prefs.getInt('basic_ball_qty') ?? 10;
      _captureBalls[1]['quantity'] = prefs.getInt('power_ball_qty') ?? 5;
      _captureBalls[2]['quantity'] = prefs.getInt('locked_ball_qty') ?? 3;
    });
  }

  // Fungsi untuk menyimpan sisa bola ke memori internal
  Future<void> _saveBalls() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('basic_ball_qty', _captureBalls[0]['quantity']);
    await prefs.setInt('power_ball_qty', _captureBalls[1]['quantity']);
    await prefs.setInt('locked_ball_qty', _captureBalls[2]['quantity']);
  }

  void _syncPartyStats() {
    _partyHp[_activeMonster] = _playerHp;
    _partyStamina[_activeMonster] = _playerStamina;
  }

  @override
  void initState() {
    super.initState();
    _activeMonster = widget.party.first;
    for (var m in widget.party) {
      _partyHp[m] = m.hp;
      _partyStamina[m] = m.stamina;
    }

    _playerHp = _partyHp[_activeMonster]!;
    _oldPlayerHp = _playerHp;
    _playerStamina = _partyStamina[_activeMonster]!;
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Perpanjang durasi total
    );
    _clashController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1800,
      ), // Diperlama untuk animasi garis clash
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

    _loadBattleData();
  }

  Future<void> _loadBattleData() async {
    _enemyMonster = await _generateRandomEnemy();
    _enemyHp = _enemyMonster.hp;
    _oldEnemyHp = _enemyHp;
    _enemyStamina = _enemyMonster.stamina;

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _cardAnimationController.forward();
      _clashController.forward();
      _drawCards();
      _loadBalls(); // Muat jumlah bola saat arena terbuka
    }
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _clashController.dispose();
    _playerShakeController.dispose();
    _enemyShakeController.dispose();
    super.dispose();
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
      typeLog += " (+10% DMG Burn!)";
      if (moveElement == MonsterElement.Api) {
        finalDamageDouble += 2;
        typeLog += " (+2 DMG Api)";
      }
    }

    String critLog = isCritical ? " Serangan Kritis!" : "";

    return {'damage': finalDamageDouble.floor(), 'log': typeLog + critLog};
  }

  // Menghasilkan musuh dengan membaca dari file monsters.csv
  Future<Monster> _generateRandomEnemy() async {
    final random = Random();
    MonsterElement selectedElement = MonsterElement.Api;
    String monsterName = "";

    try {
      final String fileData = await rootBundle.loadString(
        'assets/monsters.csv',
      );
      List<String> lines = fileData.split('\n');

      // Hapus header jika ada tulisan 'Nama' atau 'Name' di baris pertama
      if (lines.isNotEmpty && lines.first.toLowerCase().contains('nama')) {
        lines.removeAt(0);
      }

      lines.removeWhere((line) => line.trim().isEmpty);

      if (lines.isNotEmpty) {
        String randomLine = lines[random.nextInt(lines.length)];
        // Gunakan Regex agar mendukung pemisah koma (,) maupun titik koma (;) bawaan Excel
        List<String> columns = randomLine.split(RegExp(r'[,;]'));
        if (columns.length >= 3) {
          monsterName =
              ' ${columns[1].replaceAll('"', '').trim()}'; // Ambil Kolom B, bersihkan tanda kutip
          selectedElement = _getElement(
            columns[2].replaceAll('"', '').trim(),
          ); // Ambil Kolom C (Elemen)
        }
      }
    } catch (e) {
      print('Gagal membaca assets/monsters.csv: $e');
      final elements = [
        MonsterElement.Api,
        MonsterElement.Air,
        MonsterElement.Tumbuhan,
        MonsterElement.Listrik,
        MonsterElement.Tanah,
        MonsterElement.Terbang,
      ];
      selectedElement = elements[random.nextInt(elements.length)];
    }

    final enemyLevel = max(1, _activeMonster.level + random.nextInt(3) - 1);

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
        if (monsterName.isEmpty) {
          List<String> names = [
            'Ignis',
            'Pyre',
            'Blaze',
            'Inferno',
            'Cinder',
            'Flare',
          ];
          monsterName = 'Wild ${names[random.nextInt(names.length)]}';
        }
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
          const MonsterMove(
            name: 'Focus',
            type: MoveType.recover,
            power: 0,
            cost: -15,
          ),
          if (random.nextInt(3) == 0) // Peluang 33% untuk punya Heal
            const MonsterMove(
              name: 'Heal',
              type: MoveType.recover,
              power: 15,
              cost: 0,
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
        if (monsterName.isEmpty) {
          List<String> names = [
            'Aqua',
            'Hydro',
            'Tide',
            'Splash',
            'Ripple',
            'Wave',
          ];
          monsterName = 'Wild ${names[random.nextInt(names.length)]}';
        }
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
          const MonsterMove(
            name: 'Focus',
            type: MoveType.recover,
            power: 0,
            cost: -15,
          ),
          if (random.nextInt(3) == 0) // Peluang 33% untuk punya Heal
            const MonsterMove(
              name: 'Heal',
              type: MoveType.recover,
              power: 15,
              cost: 0,
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
        if (monsterName.isEmpty) {
          List<String> names = [
            'Flora',
            'Leaf',
            'Vine',
            'Thorn',
            'Root',
            'Petal',
          ];
          monsterName = 'Wild ${names[random.nextInt(names.length)]}';
        }
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
          const MonsterMove(
            name: 'Focus',
            type: MoveType.recover,
            power: 0,
            cost: -15,
          ),
          if (random.nextInt(3) == 0) // Peluang 33% untuk punya Heal
            const MonsterMove(
              name: 'Heal',
              type: MoveType.recover,
              power: 15,
              cost: 0,
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
        if (monsterName.isEmpty) {
          List<String> names = [
            'Volt',
            'Spark',
            'Zap',
            'Blitz',
            'Thunder',
            'Jolt',
          ];
          monsterName = 'Wild ${names[random.nextInt(names.length)]}';
        }
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
          const MonsterMove(
            name: 'Focus',
            type: MoveType.recover,
            power: 0,
            cost: -15,
          ),
          if (random.nextInt(3) == 0) // Peluang 33% untuk punya Heal
            const MonsterMove(
              name: 'Heal',
              type: MoveType.recover,
              power: 15,
              cost: 0,
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
        if (monsterName.isEmpty) {
          List<String> names = [
            'Terra',
            'Rock',
            'Quake',
            'Dust',
            'Mud',
            'Stone',
          ];
          monsterName = 'Wild ${names[random.nextInt(names.length)]}';
        }
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
          const MonsterMove(
            name: 'Focus',
            type: MoveType.recover,
            power: 0,
            cost: -15,
          ),
          if (random.nextInt(3) == 0) // Peluang 33% untuk punya Heal
            const MonsterMove(
              name: 'Heal',
              type: MoveType.recover,
              power: 15,
              cost: 0,
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
        if (monsterName.isEmpty) {
          List<String> names = [
            'Aero',
            'Zephyr',
            'Wind',
            'Gale',
            'Sky',
            'Breeze',
          ];
          monsterName = 'Wild ${names[random.nextInt(names.length)]}';
        }
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
          const MonsterMove(
            name: 'Focus',
            type: MoveType.recover,
            power: 0,
            cost: -15,
          ),
          if (random.nextInt(3) == 0) // Peluang 33% untuk punya Heal
            const MonsterMove(
              name: 'Heal',
              type: MoveType.recover,
              power: 15,
              cost: 0,
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
    final moves = _activeMonster.moves;
    _currentCards.clear();

    final specialMoves = moves
        .where((m) => m.type == MoveType.special)
        .toList();

    // Cek apakah kartu spesial bisa ditarik (cooldown 15 turn)
    if (specialMoves.isNotEmpty && (_turnCount - _lastSpecialCardTurn) >= 15) {
      _currentCards.add(specialMoves[random.nextInt(specialMoves.length)]);
      _lastSpecialCardTurn = _turnCount; // Reset cooldown
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

    // Acak posisi kartu di tangan
    _currentCards.shuffle();
  }

  void _attemptCapture(int ballIndex) {
    if (!_isPlayerTurn) return;
    if (_captureBalls[ballIndex]['quantity'] <= 0) return;

    double ballBonus = _captureBalls[ballIndex]['bonus'];
    String ballName = _captureBalls[ballIndex]['name'];

    setState(() {
      _captureBalls[ballIndex]['quantity']--;
      _isCaptureMode = false;
      _isPlayerTurn = false;
      _battleLog = "Kamu melempar $ballName...";
    });

    _saveBalls(); // Simpan pengurangan bola secara permanen

    // 1. Hitung Status Bonus
    double statusBonus = 1.0;
    if (_enemyBurnTurns > 0 ||
        _enemyParalysisTurns > 0 ||
        _enemyBindTurns > 0) {
      statusBonus = 1.5;
    }

    int hpMax = _enemyMonster.hp;
    int hpCurrent = _enemyHp;

    // Menggunakan Base Catch Rate 255.
    // Secara matematis, pada HP Penuh (100%), peluangnya adalah ~33%.
    // Pada HP setengah (50%), peluangnya ~66%.
    // Pada HP sekarat (<10%), peluangnya mencapai 100%. (Rata-rata kesuksesan seimbang di 50%)
    double catchRate = 255.0;

    // Rumus Probabilitas Penangkapan
    double a =
        ((3 * hpMax - 2 * hpCurrent) * catchRate * ballBonus * statusBonus) /
        (3 * hpMax);

    bool isCaught = false;
    if (a >= 255) {
      isCaught = true;
    } else {
      double probability = a / 255.0;
      double roll = Random().nextDouble();
      if (roll <= probability) {
        isCaught = true;
      }
    }

    // Simulasi jeda animasi bola bergetar (shake)
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      if (isCaught) {
        setState(() {
          _battleLog = "Berhasil! ${_enemyMonster.name} tertangkap!";
        });

        // Simpan monster baru ke memori device
        _enemyMonster.hp = hpMax;
        widget.party.add(_enemyMonster); // Tambahkan ke in-memory party
        _partyHp[_enemyMonster] = _enemyMonster.hp;
        _partyStamina[_enemyMonster] = _enemyMonster.stamina;
        await SaveManager.saveParty(widget.party); // Update penyimpanan

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _showEndGameDialog(true, isCaptured: true);
        });
      } else {
        setState(() {
          _battleLog = "Yah! ${_enemyMonster.name} berhasil membebaskan diri!";
        });
        _enemyTurn(); // Lanjut ke giliran musuh jika gagal
      }
    });
  }

  void _checkPlayerFaint() {
    bool hasAliveMonster = widget.party.any((m) => _partyHp[m]! > 0);
    if (hasAliveMonster) {
      setState(() {
        _battleLog =
            "${_activeMonster.name} kehabisan tenaga! Pilih monster pengganti.";
        _isSwitchMode = true;
        _isCaptureMode = false;
        _isPlayerTurn = true;
      });
    } else {
      _showEndGameDialog(false);
    }
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

    // Jika switch terjadi karena monster mati, jangan hanguskan giliran
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

    // --- Handle Player Status Effects ---
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
        _oldPlayerHp = _playerHp; // Simpan HP lama untuk animasi
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
      _enemyTurn(); // Langsung ke giliran musuh
      return;
    }

    setState(() {
      _isPlayerTurn = false;

      // Update Stamina
      _playerStamina = min(_activeMonster.stamina, _playerStamina - move.cost);
      _syncPartyStats();
      final damageResult = _calculateDamage(
        _activeMonster,
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
        damage += bonus; // Tambahkan bonus ke total damage
        int healAmount = damage; // Heal disesuaikan dengan damage
        _playerHp = min(_activeMonster.hp, _playerHp + healAmount);
        _syncPartyStats();
        effectLog = " Serap $healAmount HP!";
      }
      if (move.cost < 0 && move.type != MoveType.recover) {
        effectLog += " Pulih ${-move.cost} SP!";
      }

      _enemyDamageValue = damage; // Set damage value setelah buff Absorb
      _oldEnemyHp = _enemyHp; // Simpan HP lama untuk animasi
      _enemyHp = max(0, _enemyHp - damage);
      if (damage > 0) {
        _enemyShakeController.forward(from: 0.0);
      }
      _battleLog =
          "$statusLog${_activeMonster.name} pakai ${move.name}!$elementalLog$effectLog";
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
          statusLog = "Musuh kena 5 DMG Burn! ";
        }

        if (_enemyHp == 0) {
          _battleLog = "${statusLog}Musuh kehabisan HP!";
          _showEndGameDialog(true);
          return;
        }

        // Cek efek Bind
        if (_enemyBindTurns > 0 || _enemyParalysisTurns > 0) {
          if (_enemyBindTurns > 0) {
            _enemyBindTurns--;
            _battleLog = "$statusLog${_enemyMonster.name} Terikat!";
          } else {
            _enemyParalysisTurns--;
            _battleLog = "$statusLog${_enemyMonster.name} Paralysis!";
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
            _activeMonster.element,
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
                if (move.name == 'Heal') {
                  // Heal is valuable when HP is low
                  if (_enemyHp < _enemyMonster.hp * 0.5) {
                    score = 3.0; // Very high score to force healing
                  } else {
                    score = -1.0; // Avoid healing with high HP
                  }
                } else {
                  // Recover is only valuable when stamina is low
                  if (_enemyStamina < _enemyMonster.stamina * 0.4) {
                    score = 2.5; // High score to force recovery
                  } else {
                    score = -1.0; // Avoid recovering with high stamina
                  }
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
            if (chosenMove.name == 'Heal') {
              _oldEnemyHp = _enemyHp;
              _enemyHp = min(_enemyMonster.hp, _enemyHp + 15);
              _battleLog = "$statusLog${_enemyMonster.name} memulihkan 15 HP!";
            } else {
              _battleLog =
                  "$statusLog${_enemyMonster.name} pulihkan ${-chosenMove.cost} SP!";
            }
          } else {
            // Attack move
            final damageResult = _calculateDamage(
              _enemyMonster,
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
              enemyDamage += bonus; // Tambahkan bonus ke total damage
              int healAmount = enemyDamage; // Heal disesuaikan dengan damage
              _oldEnemyHp = _enemyHp;
              _enemyHp = min(_enemyMonster.hp, _enemyHp + healAmount);
              effectLog = " Musuh serap $healAmount HP!";
            }
            if (chosenMove.cost < 0 && chosenMove.type != MoveType.recover) {
              effectLog += " Musuh pulih ${-chosenMove.cost} SP!";
            }

            _playerDamageValue = enemyDamage;
            _oldPlayerHp = _playerHp;
            _playerHp = max(0, _playerHp - enemyDamage);
            _syncPartyStats();
            if (enemyDamage > 0) {
              _playerShakeController.forward(from: 0.0);
            }

            _battleLog =
                "$statusLog${_enemyMonster.name} pakai ${chosenMove.name}!$elementalLog$effectLog";
          }
        } else {
          // No affordable moves, enemy struggles and recovers a bit of stamina
          _enemyStamina = min(_enemyMonster.stamina, _enemyStamina + 2);
          _battleLog = "$statusLog${_enemyMonster.name} istirahat!";
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

  void _showEndGameDialog(bool won, {bool isCaptured = false}) {
    widget.onBattleEnd(won);

    // Simpan monster liar ini ke Pokedex (Encountered) setelah battle selesai
    SaveManager.saveEncounteredMonster(_enemyMonster.name.trim());

    final random = Random();
    int gold = won ? 10 + random.nextInt(20) : 0;
    int exp = won ? 20 + random.nextInt(30) : 5;

    List<Map<String, num>> allLevelUps = [];
    int initialLevel = _activeMonster.level;

    // Logika penambahan EXP dan Level Up
    if (won) {
      _activeMonster.currentExp += exp;
      while (_activeMonster.currentExp >= _activeMonster.expToNextLevel) {
        int remainingExp =
            _activeMonster.currentExp - _activeMonster.expToNextLevel;

        // Naik Level!
        final statIncreases = _activeMonster.levelUp();
        allLevelUps.add(statIncreases);

        _activeMonster.currentExp = remainingExp;
        _activeMonster.expToNextLevel = Monster.calculateExpForNextLevel(
          _activeMonster.level,
        );
      }
    }

    // Simpan perolehan Gold ke memori (Wild Battle)
    if (won && gold > 0) {
      SaveManager.loadGold().then((currentGold) {
        SaveManager.saveGold(currentGold + gold);
      });
    }

    // Simpan seluruh party
    SaveManager.saveParty(widget.party);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          won ? (isCaptured ? 'Tertangkap!' : 'Menang!') : 'Kalah...',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              won
                  ? (isCaptured ? Icons.catching_pokemon : Icons.emoji_events)
                  : Icons.sentiment_very_dissatisfied,
              size: 60,
              color: won
                  ? (isCaptured ? Colors.redAccent : Colors.amber)
                  : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              won
                  ? (isCaptured
                        ? 'Kamu berhasil menangkap ${_enemyMonster.name}!'
                        : 'Kamu berhasil mengalahkan ${_enemyMonster.name}!')
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
            // POP-UP STATISTIK CAPTURE
            if (isCaptured) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _enemyMonster.elementColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _enemyMonster.elementColor.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getElementIcon(_enemyMonster.element),
                          color: _enemyMonster.elementColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_enemyMonster.name} (Lv ${_enemyMonster.level})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat('HP', _enemyMonster.hp),
                        _buildMiniStat('ATK', _enemyMonster.attack.toInt()),
                        _buildMiniStat('DEF', _enemyMonster.defense.toInt()),
                        _buildMiniStat('SPD', _enemyMonster.speed),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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

  // Widget Bantuan: Status Singkat Pop-Up
  Widget _buildMiniStat(String label, int value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFE0F7FA),
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

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
                clipBehavior:
                    Clip.none, // Cegah garis putih terpotong batas luar
                children: [
                  // Animasi Clash Layar Diagonal
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
                            // 35% Waktu pertama: Meluncur sebagai persegi dari Atas & Bawah
                            final slideProgress = Curves.easeOut.transform(
                              (linearValue / 0.35).clamp(0.0, 1.0),
                            );

                            // 15% Waktu (0.35 - 0.50): Garis putih memanjang dari tengah
                            final lineProgress = Curves.easeOut.transform(
                              ((linearValue - 0.35) / 0.15).clamp(0.0, 1.0),
                            );

                            // 50% Waktu sisanya (0.50 - 1.0): Membelah perlahan menjadi segitiga diagonal
                            final morphProgress = Curves.easeOutBack.transform(
                              ((linearValue - 0.50) / 0.50).clamp(0.0, 1.0),
                            );

                            final currentAvgYOffset =
                                boxSize.height * 0.05 * morphProgress;
                            final currentDy =
                                boxSize.width *
                                0.53 *
                                morphProgress; // Miring lebih landai
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
                              clipBehavior: Clip.none, // Izinkan Overflow
                              children: [
                                // Sisi Musuh (Top)
                                Transform.translate(
                                  offset: Offset(0, slideYTop),
                                  child: ClipPath(
                                    clipper: AsymmetricDiagonalClipper(
                                      isTop: true,
                                      progress: morphProgress,
                                    ),
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
                                // Sisi Pemain (Bottom)
                                Transform.translate(
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
                                // Garis Putih (Clash Line)
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

                  // --- MONSTER MUSUH (TOP RIGHT) ---
                  Positioned(
                    top: -50,
                    right: 0,
                    child: _buildMonsterSpriteCore(
                      element: _enemyMonster.element,
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
                          name: _enemyMonster.name,
                          level: _enemyMonster.level,
                          element: _enemyMonster.element,
                          currentHp: _enemyHp,
                          maxHp: _enemyMonster.hp,
                          currentStamina: _enemyStamina,
                          maxStamina: _enemyMonster.stamina,
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
                  // Animasi Damage Musuh
                  if (_enemyDamageValue > 0)
                    Positioned(
                      top: size.height * 0.15,
                      right: size.width * 0.25,
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
                      bottom: size.height * 0.15,
                      left: size.width * 0.25,
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
                        if (_playerHp <= 0) {
                          return; // Pemain dipaksa harus memilih monster jika mati
                        }
                        setState(() {
                          _isSwitchMode = !_isSwitchMode;
                          if (_isSwitchMode) _isCaptureMode = false;
                        });
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
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (_playerHp <= 0) {
                          return; // Pemain dipaksa harus memilih monster jika mati
                        }
                        setState(() {
                          _isCaptureMode = !_isCaptureMode;
                          if (_isCaptureMode) _isSwitchMode = false;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isCaptureMode
                              ? Colors.redAccent
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
                          _isCaptureMode ? Icons.close : Icons.catching_pokemon,
                          color: _isCaptureMode
                              ? Colors.white
                              : Colors.redAccent,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // AREA KARTU (HAND)
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
                                    (_isCaptureMode
                                        ? const ValueKey('capture_mode')
                                        : _isSwitchMode
                                        ? const ValueKey('switch_mode')
                                        : const ValueKey('moves_mode'));

                                // Animasi slider murni tanpa efek bayang-bayang (Fade)
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
                          child: _isCaptureMode
                              ? Row(
                                  key: const ValueKey('capture_mode'),
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                    _captureBalls.length,
                                    (index) {
                                      return _buildBallCard(
                                        _captureBalls[index],
                                        index,
                                      );
                                    },
                                  ),
                                )
                              : _isSwitchMode
                              ? SingleChildScrollView(
                                  key: const ValueKey('switch_mode'),
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      widget.party.length,
                                      (index) {
                                        return _buildMonsterSwitchCard(
                                          widget.party[index],
                                          index,
                                        );
                                      },
                                    ),
                                  ),
                                )
                              : Row(
                                  key: const ValueKey('moves_mode'),
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                    _currentCards.length,
                                    (index) {
                                      return _buildAnimatedCard(
                                        _currentCards[index],
                                        index,
                                      );
                                    },
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
    double newHpPercent = max(0, currentHp / maxHp);

    return Container(
      key: ValueKey('${monster.name}_$maxHp'),
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
            tween: Tween<double>(begin: 0.0, end: newHpPercent),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
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
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: monster.stamina > 0
                        ? currentStamina / monster.stamina
                        : 0.0,
                  ),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: animatedValue,
                        backgroundColor: Colors.grey.shade300,
                        color: Colors.teal,
                        minHeight: 6,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
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

  // Widget Bantuan: Kartu Serangan yang bisa diklik
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
                    move.name == 'Heal'
                        ? '+15'
                        : (move.cost > 0 ? '${move.cost}' : '+${-move.cost}'),
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

  // Widget Bantuan: Kartu Ball Capture
  Widget _buildBallCard(Map<String, dynamic> ball, int index) {
    int quantity = ball['quantity'];
    bool outOfStock = quantity <= 0;
    Color bgColor = ball['color'];

    return GestureDetector(
      onTap: outOfStock ? null : () => _attemptCapture(index),
      child: Opacity(
        opacity: outOfStock ? 0.5 : 1.0,
        child: Container(
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
                    const Text(
                      'QTY',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'X $quantity',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
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
                        Icons.catching_pokemon,
                        size: 48,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          ball['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                  children: const [
                    Icon(Icons.business_center, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'ITEM',
                      style: TextStyle(
                        color: Colors.white,
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
      ),
    );
  }

  // Widget Bantuan: Kartu Switch Monster
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
          width: 130,
          height: 190,
          margin: const EdgeInsets.symmetric(horizontal: 6),
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isActive ? 'ACTIVE' : (isDead ? 'FAINTED' : 'SWAP'),
                      style: TextStyle(
                        color: isActive
                            ? Colors.amber
                            : (isDead ? Colors.red : Colors.white),
                        fontSize: 16,
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
                        size: 48,
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
                    Text(
                      'HP',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    LinearProgressIndicator(
                      value: _partyHp[monster]! / monster.hp,
                      backgroundColor: Colors.black26,
                      color: isDead ? Colors.red : Colors.green,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_partyHp[monster]}/${monster.hp}',
                      style: const TextStyle(
                        color: Colors.white,
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
      ),
    );
  }
}

// ============================================================================
// 3. PVP BATTLE MENU
// ============================================================================

class PvPBattleArena extends StatefulWidget {
  final String roomCode;
  final Monster playerMonster;
  final List<Monster> party;
  final bool isHost;

  const PvPBattleArena({
    super.key,
    required this.roomCode,
    required this.playerMonster,
    required this.party,
    required this.isHost,
  });

  @override
  State<PvPBattleArena> createState() => _PvPBattleArenaState();
}

class _PvPBattleArenaState extends State<PvPBattleArena>
    with TickerProviderStateMixin, BattleSharedMixin<PvPBattleArena> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Animasi & Deck
  late AnimationController _cardAnimationController;
  late Animation<double> _cardAnimation;
  final List<MonsterMove> _currentCards = [];

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
  bool _dialogShown = false;

  // State Party Switch
  late Monster _activeMonster;
  final Map<Monster, int> _partyHp = {};
  final Map<Monster, int> _partyStamina = {};
  bool _isSwitchMode = false;

  @override
  void initState() {
    super.initState();
    _activeMonster = widget.playerMonster;
    _oldMyHp = _activeMonster.hp;

    for (var m in widget.party) {
      _partyHp[m] = m.hp;
      _partyStamina[m] = m.stamina;
    }

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _clashController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1800,
      ), // Diperlama untuk animasi garis clash
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

    // Animasi membelah layar (Clash) harus dijalanakan untuk Host maupun Join User (Guest)
    _clashController.forward();

    // Jika sebagai host (giliran pertama), langsung draw kartu
    if (widget.isHost) {
      _localTurnCount = 1;
      _drawCards();
      _cardAnimationController.forward();
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

  // Menarik 3 kartu acak
  void _drawCards() {
    final random = Random();
    final moves = _activeMonster.moves;
    _currentCards.clear();

    final specialMoves = moves
        .where((m) => m.type == MoveType.special)
        .toList();

    if (specialMoves.isNotEmpty &&
        (_localTurnCount - _lastSpecialCardTurn) >= 15) {
      _currentCards.add(specialMoves[random.nextInt(specialMoves.length)]);
      _lastSpecialCardTurn = _localTurnCount;
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
    if (moveElement != null && moveElement == attackerElement) {
      stabModifier = 1.5;
    }

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
      typeLog += " (+10% DMG Burn!)";
      if (moveElement == MonsterElement.Api) {
        finalDamageDouble += 2;
        typeLog += " (+2 DMG Api)";
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
        statusLog = "${myData['name']} Terikat! ";
      } else {
        myParalysis--;
        statusLog = "${myData['name']} Paralysis! ";
      }
      isSkippingTurn = true;
    }

    if (isSkippingTurn) {
      if (myBurn > 0) {
        myHp = max(0, myHp - 5);
        myBurn--;
        statusLog += "Kena 5 DMG Burn. ";
      }

      await _firestore.collection('rooms').doc(widget.roomCode).update({
        '$myRole.hp': myHp,
        '$myRole.burnTurns': myBurn,
        '$myRole.bindTurns': myBind,
        '$myRole.paralysisTurns': myParalysis,
        '$myRole.invulnerableTurns': myInvulnerable,
        'currentTurn': myHp <= 0
            ? myRole
            : enemyRole, // Jika mati terkena status, beri kesempatan switch
        'turnCount': FieldValue.increment(1),
        'log': statusLog.trim(),
      });
      _isProcessingTurn = false;
      return;
    }

    // 2. Cek Burn
    if (myBurn > 0) {
      myHp = max(0, myHp - 5);
      myBurn--;
      statusLog = "Kena 5 DMG Burn! ";
      if (myHp <= 0) {
        await _firestore.collection('rooms').doc(widget.roomCode).update({
          '$myRole.hp': 0,
          '$myRole.burnTurns': myBurn,
          '$myRole.invulnerableTurns': myInvulnerable,
          '$myRole.paralysisTurns': myParalysis,
          'log': "$statusLog${myData['name']} kehabisan HP karena Burn!",
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
      String logMessage;
      if (move.name == 'Heal') {
        myHp = min((myData['maxHp'] as num).toInt(), myHp + 15);
        logMessage = "$statusLog${myData['name']} memulihkan 15 HP!";
      } else {
        logMessage = "$statusLog${myData['name']} pulihkan ${-move.cost} SP!";
      }

      await _firestore.collection('rooms').doc(widget.roomCode).update({
        '$myRole.hp': myHp,
        '$myRole.stamina': myStamina,
        '$myRole.burnTurns': myBurn,
        '$myRole.paralysisTurns': myParalysis,
        '$myRole.invulnerableTurns': myInvulnerable,
        'currentTurn': enemyRole,
        'turnCount': FieldValue.increment(1),
        'log': logMessage,
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
      effectLog = " Musuh Burn!";
    } else if (move.name == 'Bind' || move.effect == 'Bind 1 turn') {
      enemyBind = 1;
      effectLog = " Musuh Terikat!";
    } else if (move.name == 'Paralysis' || move.effect == 'Paralysis 1 turn') {
      enemyParalysis = 1;
      effectLog = " Musuh Paralysis!";
    } else if (move.name == 'Grounding' || move.effect == 'Miss 2 turn') {
      myInvulnerable = 2;
      effectLog = " Sembunyi 2 Turn!";
    } else if (move.name == 'Fly Away' || move.effect == 'Miss 1 turn') {
      myInvulnerable = 1;
      effectLog = " Terbang 1 Turn!";
    } else if (move.name == 'Absorb' || move.effect == 'Drain HP & Heal') {
      int combo = min(myAbsorb, 3);
      int bonus = (combo - 1) * 2;
      damage += bonus; // Tambahkan bonus combo
      int healAmount = damage; // Heal disesuaikan dengan damage
      myHp = min((myData['maxHp'] as num).toInt(), myHp + healAmount);
      effectLog = " Serap $healAmount HP!";
    }
    if (move.cost < 0 && move.type != MoveType.recover) {
      effectLog += " Pulih ${-move.cost} SP!";
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
      'currentTurn':
          enemyRole, // Alihkan turn ke musuh agar dia bisa membalas/switch
      'turnCount': FieldValue.increment(1),
      'log':
          "$statusLog${myData['name']} pakai ${move.name}!$elementalLog$effectLog",
    });
    _isProcessingTurn = false;
  }

  void _checkPlayerFaint() {
    bool hasAliveMonster = widget.party.any((m) => _partyHp[m]! > 0);
    if (hasAliveMonster) {
      if (!_isSwitchMode) {
        setState(() {
          _isSwitchMode = true;
        });
      }
    } else {
      if (!_isProcessingTurn) {
        _isProcessingTurn = true;
        _firestore
            .collection('rooms')
            .doc(widget.roomCode)
            .update({
              'status': 'finished',
              'log': 'Semua monster kehabisan tenaga!',
            })
            .then((_) => _isProcessingTurn = false);
      }
    }
  }

  void _switchMonster(Monster newMonster, Map<String, dynamic> myData) async {
    if (_isProcessingTurn) return;
    if (newMonster == _activeMonster) return;
    if (_partyHp[newMonster]! <= 0) return;

    _isProcessingTurn = true;
    bool isFaintSwitch = myData['hp'] <= 0;

    setState(() {
      _activeMonster = newMonster;
      _isSwitchMode = false;
      _drawCards(); // Draw kartu baru untuk monster terpilih
    });

    String myRole = widget.isHost ? 'host' : 'guest';
    String enemyRole = widget.isHost ? 'guest' : 'host';

    // Apabila switch karena dipaksa (monster mati), kita tidak membuang giliran
    String nextTurn = isFaintSwitch ? myRole : enemyRole;

    await _firestore.collection('rooms').doc(widget.roomCode).update({
      '$myRole.name': newMonster.name,
      '$myRole.hp': _partyHp[newMonster],
      '$myRole.maxHp': newMonster.hp,
      '$myRole.stamina': _partyStamina[newMonster],
      '$myRole.maxStamina': newMonster.stamina,
      '$myRole.level': newMonster.level,
      '$myRole.element': newMonster.element.name,
      '$myRole.attack': newMonster.attack,
      '$myRole.defense': newMonster.defense,
      '$myRole.burnTurns': 0, // Reset status effects on switch
      '$myRole.bindTurns': 0,
      '$myRole.paralysisTurns': 0,
      '$myRole.invulnerableTurns': 0,
      '$myRole.consecutiveAbsorb': 0,
      'currentTurn': nextTurn,
      'turnCount': isFaintSwitch
          ? FieldValue.increment(0)
          : FieldValue.increment(1),
      'log': "Kamu mengeluarkan ${newMonster.name}!",
    });

    _isProcessingTurn = false;
  }

  void _showEndGameDialog(bool won) {
    // Simulasi hadiah kecil untuk PvP agar ada rasa penghargaan
    int exp = won ? 15 : 5;
    List<Map<String, num>> allLevelUps = [];
    int initialLevel = _activeMonster.level;

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

    SaveManager.saveParty(widget.party);

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
                    _activeMonster,
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

  List<Widget> _buildStatusListPvP(Map<String, dynamic> data) {
    List<Widget> list = [];
    int burnTurns = data['burnTurns'] ?? 0;
    int bindTurns = data['bindTurns'] ?? 0;
    int paralysisTurns = data['paralysisTurns'] ?? 0;
    int invulnerableTurns = data['invulnerableTurns'] ?? 0;
    if (burnTurns > 0)
      list.add(
        _buildStatusEffectIndicator(
          'Burn',
          burnTurns,
          3,
          Icons.local_fire_department,
          Colors.orange,
        ),
      );
    if (bindTurns > 0)
      list.add(
        _buildStatusEffectIndicator(
          'Bind',
          bindTurns,
          1,
          Icons.link_off,
          Colors.blue,
        ),
      );
    if (invulnerableTurns > 0)
      list.add(
        _buildStatusEffectIndicator(
          'Miss',
          invulnerableTurns,
          2,
          Icons.visibility_off,
          Colors.grey,
        ),
      );
    if (paralysisTurns > 0)
      list.add(
        _buildStatusEffectIndicator(
          'Paralysis',
          paralysisTurns,
          1,
          Icons.bolt,
          Colors.amber,
        ),
      );
    return list;
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
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data == null) {
              return const Center(
                child: Text('Room telah ditutup atau tidak ditemukan'),
              );
            }

            final hostData = data['host'];
            final guestData = data['guest'];

            if (guestData == null) {
              return const Center(child: Text('Menunggu sinkronisasi...'));
            }

            final myData = widget.isHost ? hostData : guestData;
            final enemyData = widget.isHost ? guestData : hostData;

            // Setup inisiasi HP untuk deteksi damage
            if (_oldEnemyHp == -1) _oldEnemyHp = enemyData['hp'];

            // Cek Trigger Damage Animasi
            int currentMyHp = myData['hp'];
            int currentEnemyHp = enemyData['hp'];

            _partyHp[_activeMonster] = currentMyHp;
            _partyStamina[_activeMonster] = myData['stamina'];

            final bool isFinished = data['status'] == 'finished';
            final bool isMyTurn =
                data['currentTurn'] == (widget.isHost ? 'host' : 'guest');

            // Paksa buka switch panel kalau mati
            if (isMyTurn && currentMyHp <= 0 && !isFinished) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _checkPlayerFaint();
              });
            }

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

            // Cek kondisi akhir pertandingan dan luncurkan dialog End Game PvP
            if (isFinished && !_dialogShown) {
              _dialogShown = true;
              bool won = currentMyHp > 0;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showEndGameDialog(won);
              });
            }

            final String battleLog = data['log'] ?? "Pertarungan dimulai!";
            int serverTurnCount = data['turnCount'] ?? 1;

            // Cek Pergantian Turn untuk Draw Card
            if (isMyTurn && serverTurnCount > _localTurnCount && !isFinished) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _localTurnCount = serverTurnCount;
                    _drawCards();
                    _cardAnimationController.forward(from: 0.0);
                  });
                }
              });
            }

            return Column(
              children: [
                // ARENA (Atas: Musuh, Bawah: Kita)
                Expanded(
                  flex: 5,
                  child: Stack(
                    clipBehavior:
                        Clip.none, // Cegah garis putih terpotong batas luar
                    children: [
                      // Animasi Clash Layar Diagonal
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
                                // 35% Waktu pertama: Meluncur sebagai persegi dari Atas & Bawah
                                final slideProgress = Curves.easeOut.transform(
                                  (linearValue / 0.35).clamp(0.0, 1.0),
                                );

                                // 15% Waktu (0.35 - 0.50): Garis putih memanjang dari tengah
                                final lineProgress = Curves.easeOut.transform(
                                  ((linearValue - 0.35) / 0.15).clamp(0.0, 1.0),
                                );

                                // 50% Waktu sisanya (0.50 - 1.0): Membelah (morph) menjadi segitiga
                                final morphProgress = Curves.easeOutBack
                                    .transform(
                                      ((linearValue - 0.50) / 0.50).clamp(
                                        0.0,
                                        1.0,
                                      ),
                                    );

                                final currentAvgYOffset =
                                    boxSize.height * 0.05 * morphProgress;
                                final currentDy =
                                    boxSize.width * 0.53 * morphProgress;
                                final lineAngle = atan2(
                                  currentDy,
                                  boxSize.width,
                                );
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
                                  clipBehavior: Clip.none, // Izinkan Overflow
                                  children: [
                                    // Musuh (Top)
                                    Transform.translate(
                                      offset: Offset(0, slideYTop),
                                      child: ClipPath(
                                        clipper: AsymmetricDiagonalClipper(
                                          isTop: true,
                                          progress: morphProgress,
                                        ),
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
                                                  color: Colors.white
                                                      .withOpacity(0.1),
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
                                        clipper: AsymmetricDiagonalClipper(
                                          isTop: false,
                                          progress: morphProgress,
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
                                                    _getElement(
                                                      myData['element'],
                                                    ),
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
                                    // Garis Putih (Clash Line)
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
                                                      offset: const Offset(
                                                        0,
                                                        5,
                                                      ),
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

                      // --- MONSTER MUSUH (TOP RIGHT) ---
                      Positioned(
                        top: -50,
                        right: 0,
                        child: _buildMonsterSpriteCore(
                          element: _getElement(enemyData['element']),
                          isEnemy: true,
                          shakeController: _enemyShakeController,
                        ),
                      ),
                      // --- MONSTER PEMAIN (BOTTOM LEFT) ---
                      Positioned(
                        bottom: 20,
                        left: 10,
                        child: _buildMonsterSpriteCore(
                          element: _getElement(myData['element']),
                          isEnemy: false,
                          shakeController: _myShakeController,
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
                              name: enemyData['name'],
                              level: enemyData['level'],
                              element: _getElement(enemyData['element']),
                              currentHp: enemyData['hp'],
                              maxHp: enemyData['maxHp'],
                              currentStamina: enemyData['stamina'],
                              maxStamina: enemyData['maxStamina'],
                              isEnemy: true,
                              oldHp: _oldEnemyHp,
                              statusEffects: _buildStatusListPvP(enemyData),
                            ),
                          ],
                        ),
                      ),
                      // --- HUD PEMAIN (BOTTOM RIGHT) ---
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: _buildFuturisticHUDCore(
                          name: myData['name'],
                          level: myData['level'],
                          element: _getElement(myData['element']),
                          currentHp: myData['hp'],
                          maxHp: myData['maxHp'],
                          currentStamina: myData['stamina'],
                          maxStamina: myData['maxStamina'],
                          isEnemy: false,
                          oldHp: _oldMyHp,
                          statusEffects: _buildStatusListPvP(myData),
                        ),
                      ),
                      // Animasi Damage Musuh
                      if (_enemyDamageValue > 0)
                        Positioned(
                          top: size.height * 0.15,
                          right: size.width * 0.25,
                          child: _buildDamageTextAnimation(
                            _enemyDamageValue,
                            isEnemy: true,
                          ),
                        ),
                      // Animasi Damage Pemain
                      if (_myDamageValue > 0)
                        Positioned(
                          bottom: size.height * 0.15,
                          left: size.width * 0.25,
                          child: _buildDamageTextAnimation(
                            _myDamageValue,
                            isEnemy: false,
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
                            text: battleLog,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                      if (isMyTurn) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            if (currentMyHp <= 0) {
                              return; // Pemain dipaksa harus memilih monster jika mati
                            }
                            setState(() {
                              _isSwitchMode = !_isSwitchMode;
                            });
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

                // AREA KARTU / KONTROL
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade900,
                    child: isFinished
                        ? const Center(
                            child: Text(
                              'Pertarungan Selesai',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          )
                        : isMyTurn
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                          widget.party.length,
                                          (index) {
                                            return _buildMonsterSwitchCard(
                                              widget.party[index],
                                              index,
                                              myData,
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                  : Row(
                                      key: const ValueKey('moves_mode'),
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: List.generate(
                                        _currentCards.length,
                                        (index) {
                                          return _buildAnimatedCard(
                                            _currentCards[index],
                                            myData,
                                            enemyData,
                                            index,
                                          );
                                        },
                                      ),
                                    ),
                            ),
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

  Widget _buildMonsterSwitchCard(
    Monster monster,
    int index,
    Map<String, dynamic> myData,
  ) {
    bool isDead = _partyHp[monster]! <= 0;
    bool isActive = monster == _activeMonster;
    bool disabled = isDead || isActive;
    Color bgColor = monster.elementColor;

    return GestureDetector(
      onTap: disabled ? null : () => _switchMonster(monster, myData),
      child: Opacity(
        opacity: disabled ? 0.6 : 1.0,
        child: Container(
          width: 130,
          height: 190,
          margin: const EdgeInsets.symmetric(horizontal: 6),
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isActive ? 'ACTIVE' : (isDead ? 'FAINTED' : 'SWAP'),
                      style: TextStyle(
                        color: isActive
                            ? Colors.amber
                            : (isDead ? Colors.red : Colors.white),
                        fontSize: 16,
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
                        size: 48,
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    LinearProgressIndicator(
                      value: _partyHp[monster]! / monster.hp,
                      backgroundColor: Colors.black26,
                      color: isDead ? Colors.red : Colors.green,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_partyHp[monster]}/${monster.hp}',
                      style: const TextStyle(
                        color: Colors.white,
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
      ),
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
                  move.name == 'Heal'
                      ? '+15'
                      : (move.cost > 0 ? '${move.cost}' : '+${-move.cost}'),
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

// ============================================================================
// INFINITE TOWER SCREEN
// ============================================================================

class InfiniteTowerBattleArena extends StatefulWidget {
  final List<Monster> playerParty;
  final List<Monster> trainerParty; // Mengubah dari satu monster menjadi party
  final int towerLevel;
  final Function(bool won) onBattleEnd;

  const InfiniteTowerBattleArena({
    super.key,
    required this.playerParty,
    required this.trainerParty, // Mengubah dari satu monster menjadi party
    required this.towerLevel,
    required this.onBattleEnd,
  });

  @override
  State<InfiniteTowerBattleArena> createState() =>
      _InfiniteTowerBattleArenaState();
}

class _InfiniteTowerBattleArenaState extends State<InfiniteTowerBattleArena>
    with TickerProviderStateMixin, BattleSharedMixin<InfiniteTowerBattleArena> {
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
    _battleLog = "Pertarungan Tower Level ${widget.towerLevel} dimulai!";

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _clashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
                              (linearValue / 0.35).clamp(0.0, 1.0),
                            );
                            final lineProgress = Curves.easeOut.transform(
                              ((linearValue - 0.35) / 0.15).clamp(0.0, 1.0),
                            );
                            final morphProgress = Curves.easeOutBack.transform(
                              ((linearValue - 0.50) / 0.50).clamp(0.0, 1.0),
                            );

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
                                Transform.translate(
                                  offset: Offset(0, slideYTop),
                                  child: ClipPath(
                                    clipper: AsymmetricDiagonalClipper(
                                      isTop: true,
                                      progress: morphProgress,
                                    ),
                                    child: Container(
                                      color: _activeEnemyMonster.elementColor,
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
                                Transform.translate(
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
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: isIncoming
                                        ? const Offset(1.0, 0.0)
                                        : const Offset(-1.0, 0.0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                );
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
                    move.name == 'Heal'
                        ? '+15'
                        : (move.cost > 0 ? '${move.cost}' : '+${-move.cost}'),
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
          width: 130,
          height: 190,
          margin: const EdgeInsets.symmetric(horizontal: 6),
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isActive ? 'ACTIVE' : (isDead ? 'FAINTED' : 'SWAP'),
                      style: TextStyle(
                        color: isActive
                            ? Colors.amber
                            : (isDead ? Colors.red : Colors.white),
                        fontSize: 16,
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
                        size: 48,
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    LinearProgressIndicator(
                      value: _partyHp[monster]! / monster.hp,
                      backgroundColor: Colors.black26,
                      color: isDead ? Colors.red : Colors.green,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_partyHp[monster]}/${monster.hp}',
                      style: const TextStyle(
                        color: Colors.white,
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
      ),
    );
  }
}
