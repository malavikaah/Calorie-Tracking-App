import 'package:flutter/material.dart';
import '../models/library_food_model.dart';
import '../data/nutrition_data.dart';
import '../theme.dart';

class NutritionLibraryScreen extends StatefulWidget {
  const NutritionLibraryScreen({Key? key}) : super(key: key);

  @override
  _NutritionLibraryScreenState createState() => _NutritionLibraryScreenState();
}

class _NutritionLibraryScreenState extends State<NutritionLibraryScreen> {
  final List<LibraryFood> _allFoods = NutritionData.allFoods;

  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    List<LibraryFood> filteredFoods = _allFoods.where((food) {
      final matchesSearch = food.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || food.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Encyclopedia'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredFoods.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                return _buildFoodCard(filteredFoods[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? const Color(0xFF161B22) : Colors.white,
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Search food or nutrient...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white60 : Colors.black38,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? Colors.white70 : Colors.grey,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF2D3748) : Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', 'Fruits', 'Vegetables', 'Meat', 'Dairy', 'Dry Fruits', 'Oils', 'Seeds', 'Grains', 'Others'].map((cat) {
                bool isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedCategory = cat),
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? Colors.white 
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(LibraryFood food) {
    return GestureDetector(
      onTap: () => _showFoodDetails(food),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.asset(
                food.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D3748) : Colors.grey[200],
                    child: Icon(Icons.fastfood, size: 40, color: Theme.of(context).brightness == Brightness.dark ? Colors.white30 : Colors.grey),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${food.calories} kcal', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: food.vitamins.take(2).map((v) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text('Vit $v', style: TextStyle(fontSize: 9, color: Theme.of(context).primaryColor)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFoodDetails(LibraryFood food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40, 
                height: 4, 
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[300], 
                  borderRadius: BorderRadius.circular(2)
                )
              )
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                food.imagePath,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D3748) : Colors.grey[200],
                    child: Icon(Icons.fastfood, size: 80, color: Theme.of(context).brightness == Brightness.dark ? Colors.white30 : Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(food.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      Text(food.category, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: Column(
                    children: [
                      Text('${food.calories}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                      Text('kcal', style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Macronutrients', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMacroStat('Protein', '${food.protein}g', Colors.orange),
                _buildMacroStat('Fat', '${food.fat}g', Colors.blue),
                _buildMacroStat('Carbs', '${food.carbs}g', Colors.green),
                _buildMacroStat('Fiber', '${food.fiber}g', Colors.purple),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Vitamins & Minerals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Wrap(
               spacing: 8,
              runSpacing: 8,
              children: food.vitamins.map((v) => Chip(
                label: Text('Vitamin $v'),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                labelStyle: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12),
              )).toList(),
            ),
            const SizedBox(height: 32),
            const Text('Health Benefits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Text(food.benefits, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey[700], height: 1.5)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey)),
          ],
        ),
      ),
    );
  }
}
