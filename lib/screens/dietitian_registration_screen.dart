import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dietitian_profile.dart';
import '../providers/app_state.dart';
import 'dietitian_dashboard_screen.dart';
import 'pending_approval_screen.dart';

class DietitianRegistrationScreen extends StatefulWidget {
  const DietitianRegistrationScreen({Key? key}) : super(key: key);

  @override
  _DietitianRegistrationScreenState createState() => _DietitianRegistrationScreenState();
}

class _DietitianRegistrationScreenState extends State<DietitianRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _name = '';
  String _specialization = '';
  String _education = '';
  String _experience = '';
  String _bio = '';
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isLoading = true;
      });

      final profile = DietitianProfile(
        name: _name,
        specialization: _specialization,
        education: _education,
        experience: _experience,
        bio: _bio,
        isApproved: false,
      );

      final appState = Provider.of<AppState>(context, listen: false);
      await appState.registerDietitian(profile);
      
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
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
                  'Dietitian Profile',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us about your professional background',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Name
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                  onSaved: (value) => _name = value!,
                ),
                const SizedBox(height: 16),
                
                // Specialization
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Specialization (e.g. Clinical Nutrition)',
                    prefixIcon: Icon(Icons.star),
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter your specialization' : null,
                  onSaved: (value) => _specialization = value!,
                ),
                const SizedBox(height: 16),
                
                // Education
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Education & Certifications',
                    prefixIcon: Icon(Icons.school),
                  ),
                  maxLines: 2,
                  validator: (value) => value!.isEmpty ? 'Please enter your education' : null,
                  onSaved: (value) => _education = value!,
                ),
                const SizedBox(height: 16),

                // Experience
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Years of Experience',
                    prefixIcon: Icon(Icons.work),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter your experience' : null,
                  onSaved: (value) => _experience = value!,
                ),
                const SizedBox(height: 16),

                // Bio
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Professional Bio',
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: (value) => value!.isEmpty ? 'Please enter a short bio' : null,
                  onSaved: (value) => _bio = value!,
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 40),
                _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Complete Profile', style: TextStyle(fontSize: 18)),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
