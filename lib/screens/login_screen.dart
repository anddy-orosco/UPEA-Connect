import 'dart:convert'; // <-- IMPORTANTE: Agregar este import
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../models/user_model.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _carreraController = TextEditingController();
  final _semestreController = TextEditingController();

  bool _isLoading = false;

  Future<void> _iniciarSesion() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();

        // Guardar usuario actual
        await prefs.setString('user_nombre', _nombreController.text.trim());
        await prefs.setString('user_email', _emailController.text.trim());
        await prefs.setString('user_carrera', _carreraController.text.trim());
        await prefs.setString('user_semestre', _semestreController.text.trim());
        await prefs.setBool('is_logged_in', true);

        // Guardar en lista de cuentas
        final accountsJson = prefs.getString('saved_accounts') ?? '[]';
        List<dynamic> accounts = jsonDecode(accountsJson);

        final newAccount = {
          'nombre': _nombreController.text.trim(),
          'email': _emailController.text.trim(),
          'carrera': _carreraController.text.trim(),
          'semestre': _semestreController.text.trim(),
        };

        // Verificar si ya existe
        bool exists = accounts.any((acc) => acc['email'] == newAccount['email']);
        if (!exists) {
          accounts.add(newAccount);
          await prefs.setString('saved_accounts', jsonEncode(accounts));
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar los datos: $e'),
              backgroundColor: AppColors.rojoAlerta,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.azulGradiente,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.blanco,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.azulOscuro.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 35,
                      color: AppColors.azulPrincipal,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Título
                  Text(
                    'Bienvenido Estudiante',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blanco,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Formulario
                  Container(
                    width: 320,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.blanco,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.azulOscuro.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Nombre
                          TextFormField(
                            controller: _nombreController,
                            style: const TextStyle(fontSize: 14),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu nombre';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Nombre completo',
                              labelStyle: const TextStyle(fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              prefixIcon: Icon(Icons.person, size: 18, color: AppColors.azulPrincipal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.grisClaro,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(fontSize: 14),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu email';
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Email inválido';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
                              labelStyle: const TextStyle(fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              prefixIcon: Icon(Icons.email, size: 18, color: AppColors.azulPrincipal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.grisClaro,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Carrera
                          TextFormField(
                            controller: _carreraController,
                            style: const TextStyle(fontSize: 14),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu carrera';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Carrera',
                              labelStyle: const TextStyle(fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              prefixIcon: Icon(Icons.school, size: 18, color: AppColors.azulPrincipal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.grisClaro,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Semestre
                          TextFormField(
                            controller: _semestreController,
                            style: const TextStyle(fontSize: 14),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu semestre';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Semestre',
                              labelStyle: const TextStyle(fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              prefixIcon: Icon(Icons.grade, size: 18, color: AppColors.azulPrincipal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.grisClaro,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Botón Comenzar
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _iniciarSesion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.azulPrincipal,
                                foregroundColor: AppColors.blanco,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.blanco,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text(
                                'Comenzar',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
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

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _carreraController.dispose();
    _semestreController.dispose();
    super.dispose();
  }
}