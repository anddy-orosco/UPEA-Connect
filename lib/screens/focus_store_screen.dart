import 'package:flutter/material.dart';
import '../services/focus_service.dart';

class FocusStoreScreen extends StatefulWidget {
  const FocusStoreScreen({super.key});

  @override
  State<FocusStoreScreen> createState() => _FocusStoreScreenState();
}

class _FocusStoreScreenState extends State<FocusStoreScreen> {
  final FocusService _focusService = FocusService();
  int _coins = 0;

  String _equippedSpecies = 'sp_oak';
  List<String> _purchasedSpecies = ['sp_oak'];

  String _equippedPot = 'pot_default';
  List<String> _purchasedPots = ['pot_default'];

  // Catálogo de Plantas (Sin Bonsái)
  final List<Map<String, dynamic>> _speciesCatalog = [
    {
      'id': 'sp_oak',
      'name': 'Roble Clásico',
      'price': 0,
      'image': 'assets/images/fase4_planta_frondosa.png',
      'description': 'El roble tradicional. Robusto y lleno de vida.',
    },
    {
      'id': 'sp_rose',
      'name': 'Rosal de Pasión',
      'price': 150,
      'image': 'assets/images/fase4_rosa_floripondio.png',
      'description': 'Hermosas rosas rojas que florecen con tu estudio.',
    },
    {
      'id': 'sp_sakura',
      'name': 'Cerezo Sakura',
      'price': 250,
      'image': 'assets/images/fase4_sakura_plena.png',
      'description': 'Elegante árbol japonés con pétalos rosados.',
    },
  ];

  // Catálogo de Macetas
  final List<Map<String, dynamic>> _potsCatalog = [
    {
      'id': 'pot_default',
      'name': 'Maceta Clásica',
      'price': 0,
      'image': 'assets/images/maceta_normal.png',
      'description': 'La maceta tradicional de barro.',
    },
    {
      'id': 'pot_gold',
      'name': 'Maceta Áurea',
      'price': 200,
      'image': 'assets/images/maceta_dorada.png',
      'description': 'Hecha de oro brillante para premiar tu esfuerzo.',
    },
    {
      'id': 'pot_japanese',
      'name': 'Cerámica Zen',
      'price': 180,
      'image': 'assets/images/maceta_japonesa.png',
      'description': 'Estilo oriental tradicional para momentos de paz.',
    },
    {
      'id': 'pot_volcanic',
      'name': 'Cuenca Basáltica',
      'price': 220,
      'image': 'assets/images/maceta_volcanica.png',
      'description': 'Tallada en piedra volcánica de alta resistencia.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    final coins = await _focusService.getCoins();
    final purchasedSp = await _focusService.getPurchasedSpecies();
    final equippedSp = await _focusService.getEquippedSpecies();

    final purchasedPt = await _focusService.getPurchasedPots();
    final equippedPt = await _focusService.getEquippedPot();

    setState(() {
      _coins = coins;
      _purchasedSpecies = purchasedSp;
      _equippedSpecies = equippedSp;
      _purchasedPots = purchasedPt;
      _equippedPot = equippedPt;
    });
  }

  Future<void> _handleSpeciesAction(Map<String, dynamic> item) async {
    final String id = item['id'];
    final int price = item['price'];
    final bool isOwned = _purchasedSpecies.contains(id);

    if (_equippedSpecies == id) return;

    if (isOwned) {
      await _focusService.equipSpecies(id);
      await _loadStoreData();
      _showMessage('¡${item['name']} equipada!');
    } else {
      final success = await _focusService.buySpecies(id, price);
      if (success) {
        await _focusService.equipSpecies(id);
        await _loadStoreData();
        _showMessage('🎉 ¡Compraste y equipaste ${item['name']}!');
      } else {
        _showMessage('❌ No tienes suficientes monedas.', isError: true);
      }
    }
  }

  Future<void> _handlePotAction(Map<String, dynamic> item) async {
    final String id = item['id'];
    final int price = item['price'];
    final bool isOwned = _purchasedPots.contains(id);

    if (_equippedPot == id) return;

    if (isOwned) {
      await _focusService.equipPot(id);
      await _loadStoreData();
      _showMessage('¡${item['name']} equipada!');
    } else {
      final success = await _focusService.buyPot(id, price);
      if (success) {
        await _focusService.equipPot(id);
        await _loadStoreData();
        _showMessage('🎉 ¡Compraste y equipaste ${item['name']}!');
      } else {
        _showMessage('❌ No tienes suficientes monedas.', isError: true);
      }
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2C),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Tienda de Botánica 🛒', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '$_coins',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.local_florist_rounded), text: 'Plantas'),
              Tab(icon: Icon(Icons.inventory_2_rounded), text: 'Macetas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGrid(_speciesCatalog, isPlantTab: true),
            _buildGrid(_potsCatalog, isPlantTab: false),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> catalog, {required bool isPlantTab}) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: catalog.length,
      itemBuilder: (context, index) {
        final item = catalog[index];
        final String id = item['id'];
        final bool isOwned = isPlantTab
            ? _purchasedSpecies.contains(id)
            : _purchasedPots.contains(id);
        final bool isEquipped = isPlantTab
            ? _equippedSpecies == id
            : _equippedPot == id;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEquipped ? Colors.amber : Colors.white12,
              width: isEquipped ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Image.asset(
                      item['image'],
                      height: 85,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) =>
                      const Icon(Icons.nature, size: 60, color: Colors.white30),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['description'],
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEquipped
                          ? Colors.amber
                          : (isOwned ? Colors.indigoAccent : Colors.green.shade600),
                      foregroundColor: isEquipped ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => isPlantTab
                        ? _handleSpeciesAction(item)
                        : _handlePotAction(item),
                    child: Text(
                      isEquipped
                          ? 'Equipado'
                          : (isOwned
                          ? 'Equipar'
                          : 'Comprar (${item['price']} 🪙)'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}