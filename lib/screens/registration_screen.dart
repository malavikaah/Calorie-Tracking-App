import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import 'dashboard_screen.dart'; // We will create this next

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _name = '';
  int _age = 25;
  String _gender = 'Male';
  double _height = 170.0;
  double _weight = 70.0;
  String _goal = 'maintain';
  String _healthCondition = 'none';

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AppState>(context, listen: false).userProfile;
    if (profile != null) {
      _name = profile.name;
      _age = profile.age;
      _gender = profile.gender;
      _height = profile.height;
      _weight = profile.weight;
      _goal = profile.goal;
      _healthCondition = profile.healthCondition;
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final appState = Provider.of<AppState>(context, listen: false);
      final profile = UserProfile(
        name: _name,
        email: appState.userAccount?.email ?? "",
        age: _age,
        gender: _gender,
        height: _height,
        weight: _weight,
        goal: _goal,
        healthCondition: _healthCondition,
      );

      await appState.registerUser(profile);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Welcome to CaloTrack',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s personalize your experience',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Name
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                  onSaved: (value) => _name = value!,
                ),
                const SizedBox(height: 16),
                
                // Age & Gender
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Age'),
                        keyboardType: TextInputType.number,
                        initialValue: _age.toString(),
                        validator: (value) => value!.isEmpty ? 'Enter age' : null,
                        onSaved: (value) => _age = int.parse(value!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: ['Male', 'Female', 'Other'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _gender = newValue!;
                          });
                        },
                        onSaved: (value) => _gender = value!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Height & Weight
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Height (cm)'),
                        keyboardType: TextInputType.number,
                        initialValue: _height.toString(),
                        validator: (value) => value!.isEmpty ? 'Enter height' : null,
                        onSaved: (value) => _height = double.parse(value!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Weight (kg)'),
                        keyboardType: TextInputType.number,
                        initialValue: _weight.toString(),
                        validator: (value) => value!.isEmpty ? 'Enter weight' : null,
                        onSaved: (value) => _weight = double.parse(value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Goal
                DropdownButtonFormField<String>(
                  value: _goal,
                  decoration: const InputDecoration(labelText: 'Fitness Goal'),
                  items: const [
                    DropdownMenuItem(value: 'weight loss', child: Text('Weight Loss')),
                    DropdownMenuItem(value: 'maintain', child: Text('Maintain Weight')),
                    DropdownMenuItem(value: 'weight gain', child: Text('Weight Gain')),
                  ],
                  onChanged: (newValue) {
                    setState(() {
                      _goal = newValue!;
                    });
                  },
                  onSaved: (value) => _goal = value!,
                ),
                const SizedBox(height: 16),

                // Health Condition
                DropdownButtonFormField<String>(
                  value: _healthCondition,
                  decoration: const InputDecoration(labelText: 'Health Condition'),
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('None')),
                    DropdownMenuItem(value: 'diabetes', child: Text('Diabetes')),
                    DropdownMenuItem(value: 'high_bp', child: Text('High Blood Pressure')),
                    DropdownMenuItem(value: 'cholesterol', child: Text('High Cholesterol')),
                  ],
                  onChanged: (newValue) {
                    setState(() {
                      _healthCondition = newValue!;
                    });
                  },
                  onSaved: (value) => _healthCondition = value!,
                ),

                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
