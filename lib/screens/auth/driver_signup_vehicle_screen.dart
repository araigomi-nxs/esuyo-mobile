import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

class DriverSignupVehicleScreen extends StatefulWidget {
  const DriverSignupVehicleScreen({super.key});

  @override
  State<DriverSignupVehicleScreen> createState() =>
      _DriverSignupVehicleScreenState();
}

class _DriverSignupVehicleScreenState extends State<DriverSignupVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateNumberController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  String? _selectedCategory;
  bool _vehiclePhotoUploaded = false;
  bool _orrPhotoUploaded = false;
  bool _isLoading = false;

  final List<String> _categories = ['Jeepney', 'Tricycle', 'Van', 'Motorcycle'];

  @override
  void dispose() {
    _plateNumberController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _uploadVehiclePhoto() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _vehiclePhotoUploaded = true;
          _isLoading = false;
        });
      }
    });
  }

  void _uploadOrrPhoto() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _orrPhotoUploaded = true;
          _isLoading = false;
        });
      }
    });
  }

  void _completeSignup() {
    if (_formKey.currentState!.validate() &&
        _vehiclePhotoUploaded &&
        _orrPhotoUploaded) {
      setState(() => _isLoading = true);

      // Simulate final signup
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isLoading = false);
          // Show success and go to driver dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );
          context.go('/driver');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _formKey.currentState?.validate() ?? false;
    final allUploaded = _vehiclePhotoUploaded && _orrPhotoUploaded;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/driver-signup-license'),
        ),
        title: Text(
          'Driver Registration',
          style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress indicator
                Row(
                  children: [
                    _progressStep(1, true),
                    _progressConnector(true),
                    _progressStep(2, true),
                    _progressConnector(true),
                    _progressStep(3, true),
                    _progressConnector(true),
                    _progressStep(4, true),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  'Vehicle Details',
                  style: GoogleFonts.lexend(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your registration with vehicle information',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: 32),

                // Vehicle Category
                Text(
                  'VEHICLE CATEGORY',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.outline,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() => _selectedCategory = newValue);
                  },
                  decoration: _inputDecoration(
                    hint: 'Select vehicle type',
                    prefixIcon: Icons.directions_bus_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a vehicle category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Plate Number
                Text(
                  'PLATE NUMBER',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.outline,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _plateNumberController,
                  style: GoogleFonts.lexend(fontSize: 14),
                  decoration: _inputDecoration(
                    hint: 'e.g., ABC 1234',
                    prefixIcon: Icons.confirmation_number,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your plate number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Model
                Text(
                  'VEHICLE MODEL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.outline,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _modelController,
                  style: GoogleFonts.lexend(fontSize: 14),
                  decoration: _inputDecoration(
                    hint: 'e.g., Toyota Hiace',
                    prefixIcon: Icons.info_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your vehicle model';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Color
                Text(
                  'VEHICLE COLOR',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.outline,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _colorController,
                  style: GoogleFonts.lexend(fontSize: 14),
                  decoration: _inputDecoration(
                    hint: 'e.g., Yellow',
                    prefixIcon: Icons.palette_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your vehicle color';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Vehicle Photo
                Text(
                  'VEHICLE PHOTO',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.outline,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _vehiclePhotoUploaded
                          ? AppColors.tertiary
                          : AppColors.outline.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    color: AppColors.surfaceContainerLow,
                  ),
                  child: _vehiclePhotoUploaded
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.tertiary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_bus,
                                      size: 50,
                                      color: AppColors.tertiary,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Vehicle photo uploaded',
                                      style: GoogleFonts.lexend(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.tertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: AppColors.outline.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap below to upload',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.outline,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _uploadVehiclePhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: Text(
                      'Upload Vehicle Photo',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onTertiary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ORR Certificate Photo
                Text(
                  'ORR CERTIFICATE (MOCK)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.outline,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _orrPhotoUploaded
                          ? AppColors.tertiary
                          : AppColors.outline.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    color: AppColors.surfaceContainerLow,
                  ),
                  child: _orrPhotoUploaded
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.tertiary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.document_scanner,
                                      size: 50,
                                      color: AppColors.tertiary,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'ORR certificate uploaded',
                                      style: GoogleFonts.lexend(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.tertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.tertiary,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: AppColors.outline.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap below to upload',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.outline,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _uploadOrrPhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.image_search, size: 18),
                    label: Text(
                      'Upload ORR Certificate',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onTertiary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Complete Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (canSubmit && allUploaded && !_isLoading)
                        ? _completeSignup
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (canSubmit && allUploaded)
                          ? AppColors.tertiary
                          : AppColors.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Complete Registration',
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: (canSubmit && allUploaded)
                                  ? AppColors.onTertiary
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _progressStep(int step, bool isCompleted) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? AppColors.tertiary
            : AppColors.surfaceContainerHigh,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                step.toString(),
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }

  Widget _progressConnector(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? AppColors.primary : AppColors.surfaceContainerHigh,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: AppColors.outline,
      ),
      prefixIcon: Icon(prefixIcon, color: AppColors.outline, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
