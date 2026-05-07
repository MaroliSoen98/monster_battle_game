import 'package:flutter/material.dart';
import 'package:monster_battle_game/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class PartyScreen extends StatefulWidget {
  final List<Monster> party;

  const PartyScreen({super.key, required this.party});

  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
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
                  // Tombol kembali hanya muncul di tampilan mobile jika ini adalah root
                  // Jika tidak, AppBar di MonsterDetailScreen yang akan menanganinya.
                  if (Navigator.canPop(context))
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  const Text(
                    'My Party',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.amber.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.monetization_on,
                              color: Colors.amber.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$gold',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    tooltip: 'Keluar (Logout)',
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      await GoogleSignIn().signOut();
                    },
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
                    borderRadius: BorderRadius.circular(12),
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
                                        'Lvl ${monster.level} - ${monster.element.name}',
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
                              // Bar EXP
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _selectedMonster == null ? Colors.black12 : Colors.white30,
            width: 2,
          ),
          color: _selectedMonster == null ? Colors.white : null,
          gradient: _selectedMonster == null
              ? null
              : LinearGradient(
                  colors: [
                    _selectedMonster!.elementColor.withOpacity(0.9),
                    _selectedMonster!.elementColor.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _selectedMonster == null
            ? const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(
                  child: Text('Pilih monster untuk melihat detail.'),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: MonsterDetailView(monster: _selectedMonster!),
              ),
      ),
    );
  }
}

/// Halaman baru yang didedikasikan untuk menampilkan detail monster di mobile.
class MonsterDetailScreen extends StatelessWidget {
  final Monster monster;

  const MonsterDetailScreen({super.key, required this.monster});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Monster'),
        backgroundColor: monster.elementColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              monster.elementColor.withOpacity(0.9),
              monster.elementColor.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: MonsterDetailView(monster: monster),
        ),
      ),
    );
  }
}

/// Widget yang dapat digunakan kembali untuk menampilkan detail monster.
class MonsterDetailView extends StatelessWidget {
  final Monster monster;

  const MonsterDetailView({super.key, required this.monster});

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

  MonsterElement _getStrongAgainst(MonsterElement element) {
    switch (element) {
      case MonsterElement.Api:
        return MonsterElement.Tumbuhan;
      case MonsterElement.Air:
        return MonsterElement.Api;
      case MonsterElement.Tumbuhan:
        return MonsterElement.Air;
      case MonsterElement.Listrik:
        return MonsterElement.Air;
      case MonsterElement.Tanah:
        return MonsterElement.Listrik;
      case MonsterElement.Terbang:
        return MonsterElement.Tumbuhan;
    }
  }

  MonsterElement _getWeakAgainst(MonsterElement element) {
    switch (element) {
      case MonsterElement.Api:
        return MonsterElement.Air;
      case MonsterElement.Air:
        return MonsterElement.Tumbuhan;
      case MonsterElement.Tumbuhan:
        return MonsterElement.Api;
      case MonsterElement.Listrik:
        return MonsterElement.Tanah;
      case MonsterElement.Tanah:
        return MonsterElement.Tumbuhan;
      case MonsterElement.Terbang:
        return MonsterElement.Listrik;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Box: Icon, Nama & Level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  _getElementIcon(monster.element),
                  color: monster.elementColor,
                  size: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    monster.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Text(
                  'Lvl ${monster.level}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Bagian tengah: Gambar dan Info Elemen
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Placeholder Gambar
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Gbr.\n${monster.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Kolom Info Elemen
              Expanded(child: _buildMinimalMatchupInfo(monster)),
            ],
          ),
          const SizedBox(height: 32),
          // Row untuk Statistik (Kiri) dan Info Elemen (Kanan)
          // Layout responsif untuk Statistik dan Moveset
          LayoutBuilder(
            builder: (context, constraints) {
              // Ganti ke mode vertikal jika layar sangat sempit
              bool isNarrow = constraints.maxWidth < 550;

              if (isNarrow) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatsColumn(monster),
                    const SizedBox(height: 32),
                    _buildMovesetColumn(monster),
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildStatsColumn(monster)),
                    const SizedBox(width: 32),
                    Expanded(child: _buildMovesetColumn(monster)),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 48), // Padding tambahan di bagian bawah
        ],
      ),
    );
  }

  // Widget helper untuk kolom statistik
  Widget _buildStatsColumn(Monster monster) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        _buildStatBox(
          Icons.favorite,
          'HP',
          monster.hp.toString(),
          Colors.green,
        ),
        _buildStatBox(
          Icons.flash_on,
          'Attack',
          monster.attack.toStringAsFixed(1),
          Colors.orange,
        ),
        _buildStatBox(
          Icons.shield,
          'Defense',
          monster.defense.toStringAsFixed(1),
          Colors.blueGrey,
        ),
        _buildStatBox(
          Icons.battery_charging_full,
          'Stamina',
          monster.stamina.toString(),
          Colors.teal,
        ),
        _buildStatBox(
          Icons.speed,
          'Speed',
          monster.speed.toString(),
          Colors.blue,
        ),
      ],
    );
  }

  // Widget helper untuk kolom moveset
  Widget _buildMovesetColumn(Monster monster) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Moveset',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        _buildMovesetBox(monster),
      ],
    );
  }

  // Widget kontainer untuk setiap poin statistik
  Widget _buildStatBox(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Widget minimalis untuk info keunggulan/kelemahan elemen
  Widget _buildMinimalMatchupInfo(Monster monster) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Info Elemen',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Strong against
            const Icon(
              Icons.keyboard_double_arrow_up,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Icon(
              _getElementIcon(_getStrongAgainst(monster.element)),
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 24),
            // Weak against
            const Icon(
              Icons.keyboard_double_arrow_down,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Icon(
              _getElementIcon(_getWeakAgainst(monster.element)),
              color: Colors.white,
              size: 32,
            ),
          ],
        ),
      ],
    );
  }

  // Widget daftar Moveset dengan kotak-kotak 3D
  Widget _buildMovesetBox(Monster monster) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - 16) / 2; // Mengatur 2 kolom grid
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: monster.moves.map((move) {
            Color bgColor;
            Color textColor;
            IconData icon;

            // Menentukan styling berdasarkan tipe move
            switch (move.type) {
              case MoveType.normal:
                bgColor = Colors.grey.shade200;
                textColor = Colors.black87;
                icon = Icons.sports_mma; // Ikon punch
                break;
              case MoveType.elemental:
                bgColor = monster.elementColor;
                textColor = Colors.white;
                icon = _getElementIcon(monster.element); // Ikon elemen monster
                break;
              case MoveType.special:
                bgColor = Colors.purple.shade400;
                textColor = Colors.white;
                icon = Icons.auto_awesome; // Ikon bintang/special
                break;
              case MoveType.recover:
                bgColor = Colors.teal.shade300;
                textColor = Colors.white;
                icon = Icons.healing;
                break;
            }

            return Container(
              width: itemWidth,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  // Shadow lembut untuk kedalaman (Blur)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  // Efek solid 3D timbul (Tanpa Blur)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 0,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      move.name,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
