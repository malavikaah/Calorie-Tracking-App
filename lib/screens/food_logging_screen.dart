import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/food_entry.dart';
import '../theme.dart';
import '../services/image_analysis_service.dart';

class FoodLoggingScreen extends StatefulWidget {
  const FoodLoggingScreen({Key? key}) : super(key: key);

  @override
  _FoodLoggingScreenState createState() => _FoodLoggingScreenState();
}

class _FoodLoggingScreenState extends State<FoodLoggingScreen> {
  XFile? _image;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  
  // Manual entry controllers
  final _nameController = TextEditingController();
  final _calController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _image = pickedFile;
          _imageBytes = bytes;
        });
        _analyzeImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _analyzeImage() async {
    setState(() {
      _isAnalyzing = true;
    });

    Map<String, String> results = {};
    if (_image != null) {
      final bytes = await _image!.readAsBytes();
      final profile = Provider.of<AppState>(context, listen: false).userProfile;
      final healthCondition = profile?.healthCondition ?? 'none';
      results = await ImageAnalysisService.analyzeFood(bytes, healthCondition: healthCondition);
    }

    setState(() {
      _isAnalyzing = false;
      if (results.isNotEmpty) {
        if (results['name'] == 'Not Food') {
          _image = null;
          _imageBytes = null;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Not Food?'),
              content: const Text('The AI couldn\'t find any food in this image. Please upload a clear photo of your meal.'),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
            ),
          );
          return;
        }
        _nameController.text = results['name'] ?? '';
        _calController.text = results['calories'] ?? '';
        _carbsController.text = results['carbs'] ?? '';
        _proteinController.text = results['protein'] ?? '';
        _fatController.text = results['fat'] ?? '';
      }
    });

    if (results.isNotEmpty && results['healthAlert'] != null && results['healthAlert']!.isNotEmpty) {
      final isGood = results['isGoodForCondition'] == 'true';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(isGood ? Icons.check_circle : Icons.warning_amber_rounded, color: isGood ? Colors.green : Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(isGood ? 'Good for You!' : 'Health Alert!', style: const TextStyle(fontSize: 18))),
            ],
          ),
          content: Text(results['healthAlert']!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food identified! Adjust values if necessary.')),
      );
    }
  }

  Future<void> _analyzeFoodText() async {
    final foodName = _nameController.text.trim();
    if (foodName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a food name to update.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    final profile = Provider.of<AppState>(context, listen: false).userProfile;
    final healthCondition = profile?.healthCondition ?? 'none';
    
    final results = await ImageAnalysisService.analyzeFoodText(foodName, healthCondition: healthCondition);

    if (!mounted) return;

    setState(() {
      _isAnalyzing = false;
      if (results.isNotEmpty) {
        _nameController.text = results['name'] ?? foodName;
        _calController.text = results['calories'] ?? '';
        _carbsController.text = results['carbs'] ?? '';
        _proteinController.text = results['protein'] ?? '';
        _fatController.text = results['fat'] ?? '';
      }
    });

    if (results.isNotEmpty && results['healthAlert'] != null && results['healthAlert']!.isNotEmpty) {
      final isGood = results['isGoodForCondition'] == 'true';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(isGood ? Icons.check_circle : Icons.warning_amber_rounded, color: isGood ? Colors.green : Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(isGood ? 'Good for You!' : 'Health Alert!', style: const TextStyle(fontSize: 18))),
            ],
          ),
          content: Text(results['healthAlert']!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nutrition updated for new food name!')),
      );
    }
  }

  void _saveFood() {
    if (_nameController.text.isEmpty || _calController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Calories are required.')),
      );
      return;
    }

    final entry = FoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      calories: int.tryParse(_calController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      carbs: double.tryParse(_carbsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
      protein: double.tryParse(_proteinController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
      fat: double.tryParse(_fatController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
      timestamp: DateTime.now(),
      imagePath: _image?.path,
    );

    Provider.of<AppState>(context, listen: false).addFoodLog(entry);
    Provider.of<AppState>(context, listen: false).earnCalocredits(3); // Reward 3 credits for logging
    Navigator.pop(context);
    
    // Manual Check for alerts
    final profile = Provider.of<AppState>(context, listen: false).userProfile;
    if (profile != null && profile.healthCondition != 'none') {
       bool isBad = false;
       String alertMessage = '';
       if (profile.healthCondition == 'diabetes' && entry.carbs > 50) {
         isBad = true;
         alertMessage = '⚠️ Health Alert: High carbs detected (${entry.carbs}g). Not recommended for diabetes!';
       } else if (profile.healthCondition == 'cholesterol' && entry.fat > 20) {
         isBad = true;
         alertMessage = '⚠️ Health Alert: High fat detected (${entry.fat}g). Not recommended for high cholesterol!';
       } else if (profile.healthCondition == 'high_bp' && entry.fat > 25) {
         isBad = true;
         alertMessage = '⚠️ Health Alert: Watch out for your blood pressure!';
       }

       if (isBad) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(alertMessage),
             backgroundColor: Colors.red[700],
             duration: const Duration(seconds: 4),
           ),
         );
       } else {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('👍 This meal looks okay for your condition. +3 Calocredits'),
             backgroundColor: Colors.green[700],
           ),
         );
       }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal logged successfully! +3 Calocredits')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Meal'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Picker Section
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  image: _imageBytes != null 
                      ? DecorationImage(
                          image: MemoryImage(_imageBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 50, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('Tap to select image', style: TextStyle(color: Colors.grey[600])),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            if (_isAnalyzing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Analyzing food...'),
                  ],
                ),
              ),

            if (!_isAnalyzing) ...[
              Text(
                'Food Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Food Name',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor),
                    tooltip: 'Update Nutrition via AI',
                    onPressed: _analyzeFoodText,
                  ),
                ),
                onSubmitted: (_) => _analyzeFoodText(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _calController,
                      decoration: const InputDecoration(labelText: 'Calories (kcal)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _carbsController,
                      decoration: const InputDecoration(labelText: 'Carbs (g)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _proteinController,
                      decoration: const InputDecoration(labelText: 'Protein (g)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _fatController,
                      decoration: const InputDecoration(labelText: 'Fat (g)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveFood,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Save Meal'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
