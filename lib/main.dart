import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeightGainGameApp());
}

class WeightGainGameApp extends StatelessWidget {
  const WeightGainGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weight Gain Clicker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF111827),
      ),
      home: const WeightGainGameScreen(),
    );
  }
}

class WeightGainGameScreen extends StatefulWidget {
  const WeightGainGameScreen({super.key});

  @override
  State<WeightGainGameScreen> createState() => _WeightGainGameScreenState();
}

class _WeightGainGameScreenState extends State<WeightGainGameScreen> {
  static const String _storageKey = 'weight_gain_save';

  int _weight = 150;
  int _cash = 0;
  int _tapPower = 1;
  int _autoGain = 0;
  int _level = 1;
  bool _isLoading = true;

  String _currentSkin = 'Alt Skin skin';
  final List<String> _availableSkins = [
    'Alt Skin skin',
    'Beach Skin',
    'Camila skin',
    'Cat girl skin',
    'Chrismas skin',
    'Eating Skin',
    'Endurance skin',
    'Extreme Weight Gain',
    'Few pounds skin',
    'Gym skin',
    'Kitagawa skin',
    'Komi skin',
    'Main Skin',
    'Mercy skin',
    'Ramen skin',
    'Runner Blobfication skin',
    'Resort A skin',
    'Resort C skin',
  ];

  int _rebirths = 0;
  int _totalLifetimeWeight = 0;
  int _totalTaps = 0;
  int _maxWeightReached = 150;

  Map<String, int> _specialUpgrades = {
    'mega_shake': 0,
    'food_empire': 0,
    'metabolism_boost': 0,
    'glutton_blessing': 0,
  };

  Map<String, bool> _achievements = {
    'first_upgrade': false,
    'reach_500': false,
    'reach_1000': false,
    'first_rebirth': false,
    'mega_gainer': false,
  };

  late Timer _gameTimer;

  final List<Upgrade> _upgrades = [
    Upgrade(name: 'Protein Shake', cost: 25, tapBoost: 1, passiveBoost: 0, description: '+1 per tap'),
    Upgrade(name: 'Fast Food Run', cost: 80, tapBoost: 4, passiveBoost: 0, description: '+4 per tap'),
    Upgrade(name: 'Mass Gainer', cost: 220, tapBoost: 0, passiveBoost: 2, description: '+2 per second'),
    Upgrade(name: 'Gym Plan', cost: 500, tapBoost: 8, passiveBoost: 3, description: '+8 tap and +3/sec'),
    Upgrade(name: 'Cheat Meal Bonanza', cost: 1600, tapBoost: 20, passiveBoost: 10, description: '+20 tap and +10/sec'),
  ];

  final List<SpecialUpgrade> _specialUpgradesList = [
    SpecialUpgrade(
      id: 'mega_shake',
      name: 'Mega Protein Shake',
      cost: 500,
      description: 'Each tap gains 2x more weight',
      icon: Icons.local_drink,
      color: Colors.blue,
    ),
    SpecialUpgrade(
      id: 'food_empire',
      name: 'Food Empire',
      cost: 1200,
      description: '+1 passive gain per second',
      icon: Icons.restaurant,
      color: Colors.orange,
    ),
    SpecialUpgrade(
      id: 'metabolism_boost',
      name: 'Metabolism Override',
      cost: 2000,
      description: 'Auto-gain +50%',
      icon: Icons.flash_on,
      color: Colors.yellow,
    ),
    SpecialUpgrade(
      id: 'glutton_blessing',
      name: 'Glutton\'s Blessing',
      cost: 3500,
      description: 'All gains +3x multiplier',
      icon: Icons.star,
      color: Colors.pinkAccent,
    ),
  ];

  late Map<String, SkinSettings> _skinSettings;

  @override
  void initState() {
    super.initState();
    _initializeSkinSettings();
    
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_autoGain > 0 && mounted) {
        setState(() {
          int gain = _autoGain;
          if (_specialUpgrades['metabolism_boost']! > 0) {
            gain = (gain * 1.5).toInt();
          }
          if (_specialUpgrades['glutton_blessing']! > 0) {
            gain = gain * 3;
          }
          _weight += gain;
          _cash += gain;
          _totalLifetimeWeight += gain;
          _updateLevel();
          _checkAchievements();
        });
        _saveProgress();
      }
    });
    _loadProgress();
  }

  void _initializeSkinSettings() {
    _skinSettings = {
      'Alt Skin skin': SkinSettings(
        displayName: 'Alt Skin skin',
        stageCount: 5,
        finalWeight: 900,
        stageWeights: _generateStageWeights(150, 900, 5),
      ),
      'Beach Skin': SkinSettings(
        displayName: 'Beach Skin',
        stageCount: 9,
        finalWeight: 740,
        stageWeights: _generateStageWeights(150, 740, 9),
      ),
      'Camila skin': SkinSettings(
        displayName: 'Camila skin',
        stageCount: 3,
        finalWeight: 1000,
        stageWeights: _generateStageWeights(150, 1000, 3),
      ),
      'Cat girl skin': SkinSettings(
        displayName: 'Cat girl skin',
        stageCount: 3,
        finalWeight: 500,
        stageWeights: _generateStageWeights(150, 500, 3),
      ),
      'Chrismas skin': SkinSettings(
        displayName: 'Chrismas skin',
        stageCount: 13,
        finalWeight: 290,
        stageWeights: _generateStageWeights(150, 290, 13),
      ),
      'Eating Skin': SkinSettings(
        displayName: 'Eating Skin',
        stageCount: 10,
        finalWeight: 550,
        stageWeights: _generateStageWeights(150, 550, 10),
      ),
      'Endurance skin': SkinSettings(
        displayName: 'Endurance skin',
        stageCount: 6,
        finalWeight: 1000,
        stageWeights: _generateStageWeights(150, 1000, 6),
      ),
      'Extreme Weight Gain': SkinSettings(
        displayName: 'Extreme Weight Gain',
        stageCount: 15,
        finalWeight: 1600,
        stageWeights: _generateStageWeights(150, 1600, 15),
      ),
      'Few pounds skin': SkinSettings(
        displayName: 'Few pounds skin',
        stageCount: 5,
        finalWeight: 1300,
        stageWeights: _generateStageWeights(150, 1300, 5),
      ),
      'Gym skin': SkinSettings(
        displayName: 'Gym skin',
        stageCount: 10,
        finalWeight: 750,
        stageWeights: _generateStageWeights(150, 750, 10),
      ),
      'Kitagawa skin': SkinSettings(
        displayName: 'Kitagawa skin',
        stageCount: 9,
        finalWeight: 1400,
        stageWeights: _generateStageWeights(150, 1400, 9),
      ),
      'Komi skin': SkinSettings(
        displayName: 'Komi skin',
        stageCount: 3,
        finalWeight: 375,
        stageWeights: _generateStageWeights(150, 375, 3),
      ),
      'Main Skin': SkinSettings(
        displayName: 'Main Skin',
        stageCount: 20,
        finalWeight: 1550,
        stageWeights: _generateStageWeights(150, 1550, 20),
      ),
      'Mercy skin': SkinSettings(
        displayName: 'Mercy skin',
        stageCount: 3,
        finalWeight: 450,
        stageWeights: _generateStageWeights(150, 450, 3),
      ),
      'Ramen skin': SkinSettings(
        displayName: 'Ramen skin',
        stageCount: 3,
        finalWeight: 525,
        stageWeights: _generateStageWeights(150, 525, 3),
      ),
      'Runner Blobfication skin': SkinSettings(
        displayName: 'Runner Blobfication skin',
        stageCount: 13,
        finalWeight: 3500,
        stageWeights: _generateStageWeights(150, 3500, 13),
      ),
      'Resort A skin': SkinSettings(
        displayName: 'Resort A skin',
        stageCount: 22,
        finalWeight: 3000,
        stageWeights: _generateStageWeights(150, 3000, 22),
      ),
      'Resort C skin': SkinSettings(
        displayName: 'Resort C skin',
        stageCount: 23,
        finalWeight: 4250,
        stageWeights: _generateStageWeights(150, 4250, 23),
      ),
    };
  }

  List<int> _generateStageWeights(int start, int end, int stages) {
    List<int> weights = [];
    for (int i = 0; i < stages; i++) {
      int weight = start + ((end - start) * i ~/ (stages - 1)).toInt();
      weights.add(weight);
    }
    return weights;
  }

  void _checkAchievements() {
    if (_weight >= 500 && !_achievements['reach_500']!) {
      _achievements['reach_500'] = true;
      _showAchievementUnlocked('Reach 500 lbs!');
    }
    if (_weight >= 1000 && !_achievements['reach_1000']!) {
      _achievements['reach_1000'] = true;
      _showAchievementUnlocked('Reach 1000 lbs!');
    }
    if (_weight > _maxWeightReached) {
      _maxWeightReached = _weight;
    }
  }

  void _showAchievementUnlocked(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🏆 Achievement Unlocked: $text'),
        backgroundColor: Colors.amber,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _updateLevel() {
    final settings = _skinSettings[_currentSkin];
    if (settings == null) return;

    int newLevel = 1;
    for (int i = 0; i < settings.stageWeights.length; i++) {
      if (_weight >= settings.stageWeights[i]) {
        newLevel = i + 1;
      } else {
        break;
      }
    }
    _level = newLevel;
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);

    if (stored == null || stored.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final parts = stored.split('|');
      if (parts.length >= 13) {
        setState(() {
          _weight = int.tryParse(parts[0]) ?? 150;
          _cash = int.tryParse(parts[1]) ?? 0;
          _tapPower = int.tryParse(parts[2]) ?? 1;
          _autoGain = int.tryParse(parts[3]) ?? 0;
          _currentSkin = parts[4];
          _level = int.tryParse(parts[5]) ?? 1;
          _rebirths = int.tryParse(parts[6]) ?? 0;
          _totalLifetimeWeight = int.tryParse(parts[7]) ?? 0;
          _specialUpgrades['mega_shake'] = int.tryParse(parts[8]) ?? 0;
          _specialUpgrades['food_empire'] = int.tryParse(parts[9]) ?? 0;
          _specialUpgrades['metabolism_boost'] = int.tryParse(parts[10]) ?? 0;
          _specialUpgrades['glutton_blessing'] = int.tryParse(parts[11]) ?? 0;
          _totalTaps = int.tryParse(parts[12]) ?? 0;
          _isLoading = false;
        });
        _updateLevel();
        return;
      }
    } catch (_) {
      // Ignore invalid saved data
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      '$_weight|$_cash|$_tapPower|$_autoGain|$_currentSkin|$_level|$_rebirths|$_totalLifetimeWeight|${_specialUpgrades['mega_shake']}|${_specialUpgrades['food_empire']}|${_specialUpgrades['metabolism_boost']}|${_specialUpgrades['glutton_blessing']}|$_totalTaps',
    );
  }

  void _gainWeight() {
    setState(() {
      _totalTaps++;
      int gain = _tapPower;
      if (_specialUpgrades['mega_shake']! > 0) {
        gain *= 2;
      }
      if (_specialUpgrades['glutton_blessing']! > 0) {
        gain *= 3;
      }
      _weight += gain;
      _cash += gain;
      _totalLifetimeWeight += gain;
      if (_weight > _maxWeightReached) {
        _maxWeightReached = _weight;
      }
      _updateLevel();
      _checkAchievements();
    });
    _saveProgress();
  }

  void _buyUpgrade(Upgrade upgrade) {
    if (_cash < upgrade.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough gain points yet!'), duration: Duration(seconds: 1)),
      );
      return;
    }

    setState(() {
      _cash -= upgrade.cost;
      _tapPower += upgrade.tapBoost;
      _autoGain += upgrade.passiveBoost;
      _updateLevel();
      if (!_achievements['first_upgrade']!) {
        _achievements['first_upgrade'] = true;
        _showAchievementUnlocked('Buy your first upgrade!');
      }
    });
    _saveProgress();
  }

  void _buySpecialUpgrade(SpecialUpgrade upgrade) {
    if (_cash < upgrade.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough gain points!'), duration: Duration(seconds: 1)),
      );
      return;
    }

    setState(() {
      _cash -= upgrade.cost;
      _specialUpgrades[upgrade.id] = (_specialUpgrades[upgrade.id] ?? 0) + 1;
      if (upgrade.id == 'food_empire') {
        _autoGain += 1;
      }
      if (_specialUpgrades['mega_shake']! > 0 &&
          _specialUpgrades['food_empire']! > 0 &&
          _specialUpgrades['metabolism_boost']! > 0 &&
          !_achievements['mega_gainer']!) {
        _achievements['mega_gainer'] = true;
        _showAchievementUnlocked('Become a Mega Gainer!');
      }
    });
    _saveProgress();
  }

  void _performRebirth() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rebirth'),
        content: Text(
          'Reset your progress and gain a stacking multiplier.\n\nCurrent lifetime weight: $_totalLifetimeWeight\nRebirths: $_rebirths\nNext multiplier: ${(_rebirths + 1) * 20}% bonus',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _rebirths++;
                _weight = 150;
                _cash = 0;
                _tapPower = 1;
                _autoGain = 0;
                _level = 1;
                if (!_achievements['first_rebirth']!) {
                  _achievements['first_rebirth'] = true;
                }
                _updateLevel();
              });
              _saveProgress();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Rebirth #$_rebirths! Multiplier: ${_getMultiplier().toStringAsFixed(1)}x'),
                  backgroundColor: Colors.purple,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text('Rebirth Now'),
          ),
        ],
      ),
    );
  }

  double _getMultiplier() => 1.0 + (_rebirths * 0.2);

  void _selectSkin(String skin) {
    setState(() {
      _currentSkin = skin;
      _level = 1;
      _weight = _skinSettings[skin]?.stageWeights.first ?? 150;
      _updateLevel();
    });
    _saveProgress();
  }

  String _getCurrentSkinImage() {
    final settings = _skinSettings[_currentSkin];
    if (settings == null) return '';
    
    final stageNum = _level.clamp(1, settings.stageCount);
    return 'assets/skins/$_currentSkin/$stageNum.webp';
  }

  int _getWeightForNextLevel() {
    final settings = _skinSettings[_currentSkin];
    if (settings == null || _level >= settings.stageCount) return _weight;
    return settings.stageWeights[_level];
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Weight Gain Clicker'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Game'),
              Tab(icon: Icon(Icons.person), text: 'Skins'),
              Tab(icon: Icon(Icons.bolt), text: 'Special'),
              Tab(icon: Icon(Icons.trending_up), text: 'Stats'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGameTab(),
            _buildSkinTab(),
            _buildSpecialTab(),
            _buildStatsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatsBar(),
            const SizedBox(height: 16),
            _buildCharacterCard(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _gainWeight,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Tap to Gain Weight'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 64),
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildShop()),
          ],
        ),
      ),
    );
  }

  Widget _buildSkinTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: _availableSkins.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final skin = _availableSkins[index];
            final isSelected = _currentSkin == skin;

            return GestureDetector(
              onTap: () => _selectSkin(skin),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.purple : const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.pinkAccent : Colors.grey,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, size: 42),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        skin,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      if (isSelected)
                        const Text('Selected', style: TextStyle(color: Colors.amber, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpecialTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: const Color(0xFF1F2937),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Special Upgrades', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Current Multiplier: ${_getMultiplier().toStringAsFixed(1)}x', style: const TextStyle(fontSize: 16, color: Colors.amber)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _specialUpgradesList.length,
                itemBuilder: (context, index) {
                  final upgrade = _specialUpgradesList[index];
                  final count = _specialUpgrades[upgrade.id] ?? 0;
                  final isAffordable = _cash >= upgrade.cost;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(upgrade.icon, color: upgrade.color),
                      title: Text(upgrade.name),
                      subtitle: Text(upgrade.description),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('x$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: upgrade.color)),
                          ElevatedButton(
                            onPressed: isAffordable ? () => _buySpecialUpgrade(upgrade) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAffordable ? upgrade.color : Colors.grey,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: Text('${upgrade.cost}'),
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
    );
  }

  Widget _buildStatsTab() {
    final settings = _skinSettings[_currentSkin];
    final maxStage = settings?.stageCount ?? 20;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: const Color(0xFF1F2937),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Game Statistics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildStatRow('Current Weight', '$_weight lb', Colors.green),
                      _buildStatRow('Max Weight Ever', '$_maxWeightReached lb', Colors.lightBlue),
                      _buildStatRow('Lifetime Weight Gained', '$_totalLifetimeWeight lb', Colors.blue),
                      _buildStatRow('Total Taps', '$_totalTaps', Colors.pink),
                      _buildStatRow('Current Level', '$_level/$maxStage', Colors.orange),
                      _buildStatRow('Rebirths', '$_rebirths', Colors.purple),
                      _buildStatRow('Tap Power', '$_tapPower', Colors.red),
                      _buildStatRow('Auto Gain/Sec', '$_autoGain', Colors.cyan),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF1F2937),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rebirth System', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text('Current Multiplier: ${_getMultiplier().toStringAsFixed(1)}x', style: const TextStyle(fontSize: 16, color: Colors.amber, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _performRebirth,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Rebirth'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF1F2937),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Achievements Unlocked', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildAchievement('First Upgrade', _achievements['first_upgrade']!),
                      _buildAchievement('Reach 500 lbs', _achievements['reach_500']!),
                      _buildAchievement('Reach 1000 lbs', _achievements['reach_1000']!),
                      _buildAchievement('First Rebirth', _achievements['first_rebirth']!),
                      _buildAchievement('Mega Gainer', _achievements['mega_gainer']!),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievement(String name, bool unlocked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(unlocked ? Icons.check_circle : Icons.lock, color: unlocked ? Colors.amber : Colors.grey),
          const SizedBox(width: 12),
          Text(name, style: TextStyle(fontSize: 16, color: unlocked ? Colors.white : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final settings = _skinSettings[_currentSkin];
    final maxStage = settings?.stageCount ?? 20;

    return Row(
      children: [
        Expanded(child: _StatCard(title: 'Weight', value: '$_weight lb', color: Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(title: 'Gain', value: '$_cash', color: Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(title: 'Stage', value: '$_level/$maxStage', color: Colors.blue)),
      ],
    );
  }

  Widget _buildCharacterCard() {
    final currentSkinPath = _getCurrentSkinImage();
    final nextLevelWeight = _getWeightForNextLevel();
    final weightUntilNext = nextLevelWeight - _weight;
    final settings = _skinSettings[_currentSkin];
    final isMaxLevel = _level >= (settings?.stageCount ?? 20);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(_skinSettings[_currentSkin]?.displayName ?? _currentSkin, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          Container(
            width: 240,
            height: 280,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple, width: 2),
            ),
            child: Center(
              child: Image.asset(
                currentSkinPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_not_supported, size: 60),
                      const SizedBox(height: 8),
                      Text('Stage $_level/${settings?.stageCount ?? 20}', style: const TextStyle(fontSize: 16)),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Tap power: $_tapPower  •  Auto gain: $_autoGain/sec', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          if (!isMaxLevel)
            Text('Next stage: $weightUntilNext lbs away', style: TextStyle(fontSize: 14, color: Colors.amber[300]))
          else
            const Text('Max stage reached!', style: TextStyle(fontSize: 14, color: Colors.greenAccent)),
        ],
      ),
    );
  }

  Widget _buildShop() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Regular Upgrades', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _upgrades.length,
              itemBuilder: (context, index) {
                final upgrade = _upgrades[index];
                final isAffordable = _cash >= upgrade.cost;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(upgrade.name),
                    subtitle: Text('${upgrade.description} • Cost: ${upgrade.cost}'),
                    trailing: ElevatedButton(
                      onPressed: isAffordable ? () => _buyUpgrade(upgrade) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAffordable ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Buy'),
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

class Upgrade {
  final String name;
  final int cost;
  final int tapBoost;
  final int passiveBoost;
  final String description;

  Upgrade({
    required this.name,
    required this.cost,
    required this.tapBoost,
    required this.passiveBoost,
    required this.description,
  });
}

class SpecialUpgrade {
  final String id;
  final String name;
  final int cost;
  final String description;
  final IconData icon;
  final Color color;

  SpecialUpgrade({
    required this.id,
    required this.name,
    required this.cost,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class SkinSettings {
  final String displayName;
  final int stageCount;
  final int finalWeight;
  final List<int> stageWeights;

  SkinSettings({
    required this.displayName,
    required this.stageCount,
    required this.finalWeight,
    required this.stageWeights,
  });
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
