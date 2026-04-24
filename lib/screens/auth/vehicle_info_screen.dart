import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/dashboard_screen.dart';
import 'login_screen.dart';

class VehicleInfoScreen extends StatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _submitVehicleDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Supabase.instance.client.auth;
      final user = auth.currentUser ?? auth.currentSession?.user;

      debugPrint('[Vehicle] Saving vehicle. User: ${user?.id}, Session: ${auth.currentSession != null}');

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Session lost. Please log in again.'),
              action: SnackBarAction(
                label: 'Log In',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 10),
            ),
          );
        }
        throw Exception('Authentication session not found.');
      }

      final make  = _makeController.text.trim();
      final model = _modelController.text.trim();
      final year  = int.tryParse(_yearController.text.trim()) ?? DateTime.now().year;
      final plate = _plateController.text.trim().toUpperCase();

      // 1. Upsert into driver_vehicles
      //    Using upsert so retrying after a network error won't create duplicates.
      //    Supabase upsert on (driver_id, license_plate) requires a unique index;
      //    if that doesn't exist yet, the SQL migration adds it.
      try {
        await Supabase.instance.client.from('driver_vehicles').upsert({
          'driver_id':     user.id,
          'make':          make,
          'model':         model,
          'year':          year,
          'license_plate': plate,
          'updated_at':    DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'driver_id, license_plate');
        debugPrint('[Vehicle] driver_vehicles upserted ✓');
      } catch (vehicleErr) {
        debugPrint('[Vehicle] driver_vehicles error: $vehicleErr');
        // If the unique conflict index doesn't exist yet, fall back to plain insert
        await Supabase.instance.client.from('driver_vehicles').insert({
          'driver_id':     user.id,
          'make':          make,
          'model':         model,
          'year':          year,
          'license_plate': plate,
        });
        debugPrint('[Vehicle] driver_vehicles inserted (fallback) ✓');
      }

      // 2. Update drivers table with vehicle_type representation
      final vehicleType = '$make $model ($plate)';
      try {
        await Supabase.instance.client
            .from('drivers')
            .update({
              'vehicle_type': vehicleType,
              'updated_at':   DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', user.id);
        debugPrint('[Vehicle] drivers.vehicle_type updated ✓');
      } catch (driverErr) {
        debugPrint('[Vehicle] drivers update error (non-fatal): $driverErr');
        // Non-fatal — the vehicle row is already saved. Continue.
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      debugPrint('[Vehicle] Submit failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save vehicle details: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Vehicle Details',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Register your fuel tanker to start receiving\ndelivery requests.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                
                _buildTextField(
                  label: 'Vehicle Make',
                  hint: 'e.g. Ford, Mercedes, Isuzu',
                  controller: _makeController,
                  icon: Icons.directions_car_filled_outlined,
                  validator: (v) => v!.isEmpty ? 'Please enter make' : null,
                ),
                const SizedBox(height: 20),
                
                _buildTextField(
                  label: 'Model / Variant',
                  hint: 'e.g. F-550 Fuel Tanker',
                  controller: _modelController,
                  icon: Icons.local_shipping_outlined,
                  validator: (v) => v!.isEmpty ? 'Please enter model' : null,
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Year',
                        hint: '2023',
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        icon: Icons.calendar_today_outlined,
                        validator: (v) => v!.isEmpty ? 'Req' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: 'License Plate',
                        hint: 'ABC-1234',
                        controller: _plateController,
                        icon: Icons.badge_outlined,
                        validator: (v) => v!.isEmpty ? 'Req' : null,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitVehicleDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save & Proceed',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFFFF4D00), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF4D00), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
