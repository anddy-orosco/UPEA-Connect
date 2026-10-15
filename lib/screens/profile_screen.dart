import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/colors.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/user_photo.dart';

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
  bool _isSaving = false;

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

  String _mimeDe(String nombreArchivo) {
    final ext = nombreArchivo.split('.').last.toLowerCase();
    if (ext == 'png') return 'image/png';
    if (ext == 'webp') return 'image/webp';
    return 'image/jpeg';
  }

  void _aviso(String texto, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: error ? AppColors.rojoAlerta : AppColors.verdeExito,
      ),
    );
  }

  Future<void> _guardarCambios() async {
    final nombre = _nombreController.text.trim();
    final carrera = _carreraController.text.trim();
    final semestre = _semestreController.text.trim();

    // Mismas reglas que valida el servidor.
    if (nombre.length < 2 || carrera.length < 2 || semestre.isEmpty) {
      _aviso(
        'Revisa los datos: nombre y carrera con al menos 2 letras, y el semestre no puede estar vacío.',
        error: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1) Si se eligió una foto nueva (ruta local), se sube primero.
      String? fotoUrlNueva;
      final fotoCambio = _fotoPath != null &&
          _fotoPath!.isNotEmpty &&
          _fotoPath != widget.user.fotoPath;

      if (fotoCambio && !_fotoPath!.startsWith('http')) {
        final bytes = await File(_fotoPath!).readAsBytes();
        final nombreArchivo = _fotoPath!.split(RegExp(r'[\\/]')).last;
        fotoUrlNueva = await ApiService.uploadImage(
          bytes,
          nombreArchivo,
          mimeType: _mimeDe(nombreArchivo),
        );
      }

      // 2) Se guarda el perfil en el servidor.
      final data = await ApiService.updateProfile(
        nombre: nombre,
        carrera: carrera,
        semestre: semestre,
        fotoUrl: fotoUrlNueva,
      );
      final u = (data['user'] ?? data) as Map<String, dynamic>;

      final nombreOk = (u['nombre'] as String?) ?? nombre;
      final carreraOk = (u['carrera'] as String?) ?? carrera;
      final semestreOk = (u['semestre'] as String?) ?? semestre;
      final fotoOk = (u['fotoUrl'] as String?) ?? _fotoPath;

      // 3) Solo si el servidor aceptó, se actualiza lo guardado en el celular.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_nombre', nombreOk);
      await prefs.setString('user_carrera', carreraOk);
      await prefs.setString('user_semestre', semestreOk);
      if (fotoOk != null && fotoOk.isNotEmpty) {
        await prefs.setString('user_foto_path', fotoOk);
      }

      final updatedUser = UserModel(
        nombre: nombreOk,
        email: widget.user.email,
        carrera: carreraOk,
        semestre: semestreOk,
        fotoPath: fotoOk,
      );

      // Notificar al home que los datos cambiaron
      widget.onUserUpdated(updatedUser);

      if (!mounted) return;
      setState(() {
        _fotoPath = fotoOk;
        _isEditing = false;
        _isSaving = false;
      });
      _aviso('Perfil actualizado correctamente');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final motivo = e.toString().replaceFirst('Exception: ', '');
      _aviso('No se pudo guardar: $motivo', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderBg = isDark ? Colors.white.withOpacity(0.07) : AppColors.grisClaro;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Foto de perfil
          GestureDetector(
            onTap: (_isEditing && !_isSaving) ? _seleccionarFoto : null,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: (_fotoPath != null && _fotoPath!.isNotEmpty)
                        ? UserPhoto(
                      path: _fotoPath!,
                      fallback: Container(
                        color: placeholderBg,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                        : Container(
                      color: placeholderBg,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: colorScheme.primary,
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
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: colorScheme.onPrimary,
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
                    colorScheme: colorScheme,
                    placeholderBg: placeholderBg,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoField(
                    label: 'Correo electrónico',
                    value: _emailController.text,
                    icon: Icons.email,
                    controller: _emailController,
                    isEditing: false, // el correo no se puede cambiar
                    colorScheme: colorScheme,
                    placeholderBg: placeholderBg,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoField(
                    label: 'Carrera',
                    value: _carreraController.text,
                    icon: Icons.school,
                    controller: _carreraController,
                    isEditing: _isEditing,
                    colorScheme: colorScheme,
                    placeholderBg: placeholderBg,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoField(
                    label: 'Semestre',
                    value: _semestreController.text,
                    icon: Icons.grade,
                    controller: _semestreController,
                    isEditing: _isEditing,
                    colorScheme: colorScheme,
                    placeholderBg: placeholderBg,
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
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
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
                  onPressed: _isSaving ? null : _guardarCambios,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Guardando...' : 'Guardar'),
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
                  onPressed: _isSaving ? null : () {
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
    required ColorScheme colorScheme,
    required Color placeholderBg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        isEditing
            ? TextFormField(
          controller: controller,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: colorScheme.primary, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.primary),
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
            color: placeholderBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.isEmpty ? 'No especificado' : value,
                  style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
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
