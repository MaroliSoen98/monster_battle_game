import 'package:flutter/material.dart';
import 'package:monster_battle_game/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math' as math;

class PartyScreen extends StatefulWidget {
  final List<Monster> party;

  const PartyScreen({super.key, required this.party});

  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Monster? _selectedMonster;

  @override
  void initState() {
    super.initState();
    // Secara otomatis pilih monster pertama saat layar dibuka
    if (widget.party.isNotEmpty) {
      _selectedMonster = widget.party.first;
    }
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
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F7FC), // Soft blue-grey background
      drawer: AppDrawer(
        party: widget.party,
        onPartyUpdated: () {
          setState(() {
            if (_selectedMonster != null &&
                !widget.party.contains(_selectedMonster)) {
              _selectedMonster = widget.party.isNotEmpty
                  ? widget.party.first
                  : null;
            }
          });
        },
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Tentukan breakpoint untuk layout mobile
            final bool isMobile = constraints.maxWidth < 800;

            if (isMobile) {
              // Tampilan Mobile: Hanya daftar party, detail dibuka di halaman baru
              return _buildPartyListPane(isMobile: true);
            } else {
              // Tampilan Desktop: Daftar di kiri, detail di kanan
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildPartyListPane(isMobile: false),
                  ),
                  Expanded(flex: 3, child: _buildDetailPane()),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  /// Membangun panel daftar party di sisi kiri.
  Widget _buildPartyListPane({required bool isMobile}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  if (!Navigator.canPop(context))
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black87),
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                      ),
                    ),
                  const SizedBox(width: 12),
                  const Text(
                    'My Party',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Indikator Gold
                  FutureBuilder<int>(
                    future: SaveManager.loadGold(),
                    builder: (context, snapshot) {
                      final gold = snapshot.data ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$gold',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      tooltip: 'Keluar (Logout)',
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Konfirmasi Logout'),
                            content: const Text(
                              'Apakah kamu yakin ingin keluar dari akun ini?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(dialogContext);
                                  await SaveManager.clearAllData();
                                  await FirebaseAuth.instance.signOut();
                                  await GoogleSignIn().signOut();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Keluar'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: widget.party.length,
              itemBuilder: (context, index) {
                final monster = widget.party[index];
                final isSelected = !isMobile && monster == _selectedMonster;

                return Card(
                  elevation: isSelected ? 8 : 2,
                  shadowColor: isSelected
                      ? Colors.white70
                      : monster.elementColor,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isSelected
                        ? const BorderSide(color: Colors.white, width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    onTap: () {
                      if (isMobile) {
                        // Di mobile, buka halaman detail baru
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MonsterDetailScreen(monster: monster),
                          ),
                        );
                      } else {
                        // Di desktop, perbarui state untuk menampilkan di samping
                        setState(() {
                          _selectedMonster = monster;
                        });
                      }
                    },
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  monster.elementColor.withOpacity(0.8),
                                  monster.elementColor.withOpacity(0.5),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -15,
                          bottom: -15,
                          child: Icon(
                            _getElementIcon(monster.element),
                            size: 90,
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getElementIcon(monster.element),
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        monster.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Lv. ${monster.level} - ${monster.element.name}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: <Widget>[
                                  Text(
                                    'HP',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: 1.0,
                                            backgroundColor: Colors.black
                                                .withOpacity(0.3),
                                            color: Colors.green.shade400,
                                            minHeight: 16,
                                          ),
                                        ),
                                        Text(
                                          '${monster.hp}/${monster.hp}',
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
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'EXP',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value:
                                            monster.currentExp /
                                            monster.expToNextLevel,
                                        backgroundColor: Colors.black
                                            .withOpacity(0.3),
                                        color: Colors.blue.shade300,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
    );
  }

  /// Membangun panel detail di sisi kanan (hanya untuk desktop).
  Widget _buildDetailPane() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40), // Matches Premium view
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: _selectedMonster == null
              ? const Center(child: Text('Pilih monster untuk melihat detail.'))
              : PremiumMonsterView(monster: _selectedMonster!),
        ),
      ),
    );
  }
}

/// Halaman yang didedikasikan untuk menampilkan detail monster di HP (mobile).
class MonsterDetailScreen extends StatelessWidget {
  final Monster monster;

  const MonsterDetailScreen({super.key, required this.monster});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: Stack(
        children: [
          PremiumMonsterView(monster: monster),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET: PREMIUM MONSTER VIEW (Soft Neumorphism Style)
// ============================================================================
class PremiumMonsterView extends StatefulWidget {
  final Monster monster;
  const PremiumMonsterView({super.key, required this.monster});

  @override
  State<PremiumMonsterView> createState() => _PremiumMonsterViewState();
}

class _PremiumMonsterViewState extends State<PremiumMonsterView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Gunakan tinggi dari parent (constraints) bukan layar keseluruhan
        // Agar widget ini fleksibel saat digunakan di Desktop Split Screen
        final viewHeight = constraints.maxHeight;

        return Stack(
          children: [
            // 1. Organic Background Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: viewHeight * 0.42,
              child: ClipPath(
                clipper: OrganicHeaderClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.monster.elementColor.withOpacity(0.9),
                        widget.monster.elementColor.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Mockup Background App Screens / Shapes
                      Positioned(
                        top: -50,
                        right: -30,
                        child: Transform.rotate(
                          angle: math.pi / 6,
                          child: Container(
                            width: 150,
                            height: 250,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        left: -40,
                        child: Transform.rotate(
                          angle: -math.pi / 5,
                          child: Container(
                            width: 200,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. White Content Card (Overlapping)
            Positioned(
              top: viewHeight * 0.38,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50), // Spacing for floating image
                      // Monster Name & Element Badge
                      Text(
                        widget.monster.name,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D3142),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: widget.monster.elementColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getElementIcon(widget.monster.element),
                              color: widget.monster.elementColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.monster.element.name.toUpperCase(),
                              style: TextStyle(
                                color: widget.monster.elementColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Level & EXP Minimalist Bar
                      Row(
                        children: [
                          Text(
                            'Lv. ${widget.monster.level}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value:
                                        widget.monster.currentExp /
                                        widget.monster.expToNextLevel,
                                    backgroundColor: const Color(0xFFF0F4F8),
                                    color: Colors.blueAccent.shade100,
                                    minHeight: 12,
                                  ),
                                ),
                                Text(
                                  '${widget.monster.currentExp} / ${widget.monster.expToNextLevel} EXP',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Tabs (Stats / Moves)
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF4F7FC,
                          ), // Soft Neumorphic Inset
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          labelColor: widget.monster.elementColor,
                          unselectedLabelColor: Colors.grey.shade500,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          tabs: const [
                            Tab(text: 'Stats'),
                            Tab(text: 'Moves'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Tab Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [_buildStatsTab(), _buildMovesTab()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Floating Monster Illustration
            Positioned(
              top: viewHeight * 0.16,
              left: 0,
              right: 0,
              height: viewHeight * 0.28,
              child: Hero(
                tag: widget.monster.name,
                child: Image.asset(
                  widget.monster.imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
      children: [
        PremiumStatBar(
          label: 'HP',
          value: widget.monster.hp,
          maxValue: 300,
          color: Colors.green,
        ),
        PremiumStatBar(
          label: 'Attack',
          value: widget.monster.attack,
          maxValue: 200,
          color: Colors.redAccent,
        ),
        PremiumStatBar(
          label: 'Defense',
          value: widget.monster.defense,
          maxValue: 200,
          color: Colors.orange,
        ),
        PremiumStatBar(
          label: 'Speed',
          value: widget.monster.speed,
          maxValue: 200,
          color: Colors.lightBlue,
        ),
        PremiumStatBar(
          label: 'Stamina',
          value: widget.monster.stamina,
          maxValue: 200,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildMovesTab() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
      itemCount: widget.monster.moves.length,
      itemBuilder: (context, index) {
        final move = widget.monster.moves[index];
        Color iconColor;
        IconData icon;

        switch (move.type) {
          case MoveType.normal:
            iconColor = Colors.grey.shade600;
            icon = Icons.sports_mma;
            break;
          case MoveType.elemental:
            iconColor = widget.monster.elementColor;
            icon = _getElementIcon(widget.monster.element);
            break;
          case MoveType.special:
            iconColor = Colors.purple.shade400;
            icon = Icons.auto_awesome;
            break;
          case MoveType.recover:
            iconColor = Colors.teal.shade400;
            icon = Icons.healing;
            break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE2E8F0).withOpacity(0.6),
                blurRadius: 15,
                offset: const Offset(5, 5),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 15,
                offset: Offset(-5, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      move.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      move.effect ?? move.type.name.toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PWR ${move.power}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  Text(
                    move.cost > 0 ? 'CST ${move.cost}' : 'CST +${-move.cost}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: move.cost > 0
                          ? Colors.orangeAccent
                          : Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
}

// ============================================================================
// WIDGET: PREMIUM STAT BAR
// ============================================================================
class PremiumStatBar extends StatelessWidget {
  final String label;
  final num value;
  final num maxValue;
  final Color color;

  const PremiumStatBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              value.toInt().toString(),
              style: const TextStyle(
                color: Color(0xFF2D3142),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: (value / maxValue).toDouble(),
              ),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) {
                return Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8), // Soft groove
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: val.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.6), color],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
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

// ============================================================================
// CLIPPER: ORGANIC HEADER CLIPPER
// ============================================================================
class OrganicHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(
      size.width - (size.width / 4),
      size.height - 80,
    );
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
