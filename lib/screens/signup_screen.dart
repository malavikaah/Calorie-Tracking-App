import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/user_account.dart';
import '../theme.dart';
import 'registration_screen.dart';
import 'dietitian_registration_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  String _email = '';
  String _password = '';
  UserRole _role = UserRole.user;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isLoading = true;
      });

      final appState = Provider.of<AppState>(context, listen: false);
      final success = await appState.signup(_email, _password, role: _role);
      
      if (success) {
        // Wait for AppState to process the new user and trigger login state
        // This prevents the screen from popping back to LoginScreen prematurely
        int retries = 0;
        while (!appState.isLoggedIn && retries < 20) {
          await Future.delayed(const Duration(milliseconds: 500));
          retries++;
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
               content: Text('Failed to create account. Please try again.'),
               backgroundColor: Colors.red,
            )
          );
        }
      }

      setState(() {
         _isLoading = false;
      });

      if (success && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
         backgroundColor: Colors.transparent,
         elevation: 0,
         leading: IconButton(
           icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
           onPressed: () => Navigator.pop(context),
         )
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your fitness journey today',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Role Selection
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _role = UserRole.user),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _role == UserRole.user ? Theme.of(context).primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'User',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _role == UserRole.user ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _role = UserRole.dietitian),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _role == UserRole.dietitian ? Theme.of(context).primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Dietitian',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _role == UserRole.dietitian ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email Field
                  TextFormField(
                    decoration: const InputDecoration(
                       labelText: 'Email',
                       prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                       if (value == null || value.isEmpty || !value.contains('@')) {
                           return 'Please enter a valid email address';
                       }
                       return null;
                    },
                    onSaved: (value) => _email = value!.trim(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                       labelText: 'Password',
                       prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                       if (value == null || value.isEmpty || value.length < 6) {
                           return 'Password must be at least 6 characters';
                       }
                       return null;
                    },
                    onSaved: (value) => _password = value!,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    decoration: const InputDecoration(
                       labelText: 'Confirm Password',
                       prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) {
                       if (value != _passwordController.text) {
                           return 'Passwords do not match';
                       }
                       return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  
                  // Signup Button
                  _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _signup,
                        child: const Text('Sign Up'),
                      ),
                  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
