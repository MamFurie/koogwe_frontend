import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../services/ride_service.dart';
import '../driver/driver_home.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() => _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _plateController = TextEditingController();
  final _rideService = RideService();
  bool _isLoading = false;
  String _selectedType = 'Moto';

  final _vehicleTypes = ['Moto', 'Eco', 'Confort'];

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_makeController.text.isEmpty || _modelController.text.isEmpty ||
        _colorController.text.isEmpty || _plateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _rideService.updateVehicle(
      vehicleMake: _makeController.text.trim(),
      vehicleModel: _modelController.text.trim(),
      vehicleColor: _colorController.text.trim(),
      licensePlate: _plateController.text.trim().toUpperCase(),
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverHome()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erreur'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Illustration
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
                  child: const Icon(Icons.directions_car, color: AppColors.primary, size: 52),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Enregistrez votre véhicule', style: AppText.h2, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Ces infos seront visibles par les passagers lors de chaque course.', style: AppText.bodySecondary, textAlign: TextAlign.center),

              const SizedBox(height: 32),

              // Vehicle type selector
              const Text('Type de véhicule', style: AppText.h4),
              const SizedBox(height: 12),
              Row(
                children: _vehicleTypes.map((type) {
                  final selected = _selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: type != _vehicleTypes.last ? 10 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 1.5),
                        ),
                        child: Text(
                          type,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              _inputField(_makeController, 'Marque', 'Ex: Toyota', Icons.directions_car_outlined),
              const SizedBox(height: 16),
              _inputField(_modelController, 'Modèle', 'Ex: Corolla', Icons.car_crash_outlined),
              const SizedBox(height: 16),
              _inputField(_colorController, 'Couleur', 'Ex: Noir', Icons.color_lens_outlined),
              const SizedBox(height: 16),
              _inputField(_plateController, 'Plaque d\'immatriculation', 'Ex: TG-4589-BZ', Icons.confirmation_number_outlined),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Enregistrer et continuer'),
              ),

              const SizedBox(height: 16),

              // Skip (pour le dev)
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverHome())),
                  child: const Text('Ignorer pour l\'instant', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
        ),
      ],
    );
  }
}
