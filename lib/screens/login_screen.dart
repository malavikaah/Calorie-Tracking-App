import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import 'signup_screen.dart';
import 'registration_screen.dart';
import 'dietitian_registration_screen.dart';
import 'dashboard_screen.dart';
import 'dietitian_dashboard_screen.dart';
import '../models/user_account.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isLoading = true;
      });

      final appState = Provider.of<AppState>(context, listen: false);
      final success = await appState.login(_email, _password);
      
      if (success) {
        // Wait for AppState to process the user authentication stream,
        // fetch accounts/profile details, and trigger isLoggedIn = true.
        // This ensures the loading spinner remains active until the page transitions.
        int retries = 0;
        while (!appState.isLoggedIn && retries < 20) {
          await Future.delayed(const Duration(milliseconds: 500));
          retries++;
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
               content: Text('Invalid Email or Password. Please try again.'),
               backgroundColor: Colors.red,
            )
          );
        }
      }

      if (mounted) {
        setState(() {
           _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/logo.png',
                      height: 180,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 32),
                  const SizedBox(height: 48),
                  
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
                  const SizedBox(height: 32),
                  
                  // Login Button
                  _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        child: const Text('Login'),
                      ),
                  
                  const SizedBox(height: 24),
                  
                  // Navigation to Signup
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor, 
                              fontWeight: FontWeight.bold
                            ),
                          )
                        ]
                      ),
                    )
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
