import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/core/constants/app_constants.dart';
import 'package:yappieyappie/services/auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool showPassword = false;
  String? errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);

      if (isLogin) {
        // Log in with Email OR Username
        await authService.signIn(
          identifier: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Sign up with Name, Email, Password
        await authService.signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (e) {
      setState(() => errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- BRANDING SECTION ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.forum_rounded,
                        size: 80, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppConstants.appName,
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1),
                  ),
                  // The Quote
                  const Text(
                    "Private Circle • No Noise",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 50),

                  // --- INPUT FIELDS ---

                  // Name Field (Signup only)
                  if (!isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Name is mandatory'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email or Username Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText:
                          isLogin ? 'Email or Username' : 'Email Address',
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Required field'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Password Field with Visibility Toggle
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(showPassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded),
                        onPressed: () =>
                            setState(() => showPassword = !showPassword),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    validator: (value) => (value == null || value.length < 6)
                        ? 'Min 6 characters'
                        : null,
                  ),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Text(errorMessage!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13)),
                  ],

                  const SizedBox(height: 30),

                  // --- ACTION BUTTONS ---
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 58),
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          child: Text(
                            isLogin ? 'Login to Yappie' : 'Join the Circle',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => setState(() {
                      isLogin = !isLogin;
                      errorMessage = null;
                    }),
                    child: RichText(
                      text: TextSpan(
                        style:
                            TextStyle(color: theme.textTheme.bodyMedium?.color),
                        children: [
                          TextSpan(
                              text: isLogin
                                  ? "New here? "
                                  : "Already a member? "),
                          TextSpan(
                            text: isLogin ? "Create Account" : "Login Instead",
                            style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
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
