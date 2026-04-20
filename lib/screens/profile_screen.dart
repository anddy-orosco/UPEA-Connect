import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/colors.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onUserUpdated;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _carreraController;
  late TextEditingController _semestreController;
  String? _fotoPath;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.user.nombre);
    _emailController = TextEditingController(text: widget.user.email);
    _carreraController = TextEditingController(text: widget.user.carrera);
    _semestreController = TextEditingController(text: widget.user.semestre);
    _fotoPath = widget.user.fotoPath;
  }

  Future<void> _seleccionarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _fotoPath = image.path;
      });
    }
  }

  Future<void> _guardarCambios() async {
    final prefs = await SharedPreferences.getInstance();

    // Actualizar SharedPreferences
    await prefs.setString('user_nombre', _nombreController.text);
    await prefs.setString('user_email', _emailController.text);
    await prefs.setString('user_carrera', _carreraController.text);
    await prefs.setString('user_semestre', _semestreController.text);

    // Crear usuario actualizado
    final updatedUser = UserModel(
      nombre: _nombreController.text,
      email: _emailController.text,
      carrera: _carreraController.text,
      semestre: _semestreController.text,
      fotoPath: _fotoPath,
    );

    // Notificar al home que los datos cambiaron
    widget.onUserUpdated(updatedUser);

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil actualizado correctamente'),
        backgroundColor: AppColors.verdeExito,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Foto de perfil
          GestureDetector(
            onTap: _isEditing ? _seleccionarFoto : null,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.azulPrincipal,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.azulOscuro.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _fotoPath != null
                        ? Image.file(
                      File(_fotoPath!),
                      fit: BoxFit.cover,
                    )
                        : Container(
                      color: AppColors.grisClaro,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: AppColors.azulPrincipal,
                      ),
                    ),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: AppColors.azulPrincipal,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.blanco,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: AppColors.blanco,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Formulario
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoField(
                    label: 'Nombre completo',
                    value: _nombreController.text,
                    icon: Icons.person,
                    controller: _nombreController,
                    isEditing: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoField(
                    label: 'Correo electrónico',
                    value: _emailController.text,
                    icon: Icons.email,
                    controller: _emailController,
                    isEditing: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoField(
                    label: 'Carrera',
                    value: _carreraController.text,
                    icon: Icons.school,
                    controller: _carreraController,
                    isEditing: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoField(
                    label: 'Semestre',
                    value: _semestreController.text,
                    icon: Icons.grade,
                    controller: _semestreController,
                    isEditing: _isEditing,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!_isEditing)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar Perfil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulPrincipal,
                    foregroundColor: AppColors.blanco,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

              if (_isEditing) ...[
                ElevatedButton.icon(
                  onPressed: _guardarCambios,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdeExito,
                    foregroundColor: AppColors.blanco,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _nombreController.text = widget.user.nombre;
                      _emailController.text = widget.user.email;
                      _carreraController.text = widget.user.carrera;
                      _semestreController.text = widget.user.semestre;
                      _fotoPath = widget.user.fotoPath;
                    });
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.rojoAlerta,
                    side: const BorderSide(color: AppColors.rojoAlerta),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    required TextEditingController controller,
    required bool isEditing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        isEditing
            ? TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.azulPrincipal, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.azulPrincipal),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        )
            : Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.grisClaro,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.azulPrincipal, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.isEmpty ? 'No especificado' : value,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ],
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