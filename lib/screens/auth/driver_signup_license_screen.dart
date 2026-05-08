import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

class DriverSignupLicenseScreen extends StatefulWidget {
  const DriverSignupLicenseScreen({super.key});

  @override
  State<DriverSignupLicenseScreen> createState() =>
      _DriverSignupLicenseScreenState();
}

class _DriverSignupLicenseScreenState extends State<DriverSignupLicenseScreen> {
  bool _licenseUploaded = false;
  bool _isLoading = false;

  void _uploadLicense() {
    setState(() => _isLoading = true);

    // Simulate license upload
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _licenseUploaded = true;
          _isLoading = false;
        });
      }
    });
  }

  void _nextStep() {
    if (_licenseUploaded) {
      setState(() => _isLoading = true);

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _isLoading = false);
          context.go('/driver-signup-vehicle');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/driver-signup-selfie'),
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
                  _progressConnector(false),
                  _progressStep(4, false),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'Upload License',
                style: GoogleFonts.lexend(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a clear photo of your driver\'s license (both sides)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.outline,
                ),
              ),
              const SizedBox(height: 48),

              // License preview - Front
              Text(
                'LICENSE FRONT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.outline,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _licenseUploaded
                        ? AppColors.tertiary
                        : AppColors.outline.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  color: AppColors.surfaceContainerLow,
                ),
                child: _licenseUploaded
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.tertiary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.credit_card,
                                    size: 50,
                                    color: AppColors.tertiary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'License front uploaded',
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
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
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
                            'No image selected',
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              // License preview - Back
              Text(
                'LICENSE BACK',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.outline,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _licenseUploaded
                        ? AppColors.tertiary
                        : AppColors.outline.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  color: AppColors.surfaceContainerLow,
                ),
                child: _licenseUploaded
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.tertiary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.credit_card,
                                    size: 50,
                                    color: AppColors.tertiary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'License back uploaded',
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
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.tertiary,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
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
                            'No image selected',
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 32),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.tertiary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: AppColors.tertiary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'License Requirements',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _guideline('Valid driver\'s license (PRC-issued)'),
                    _guideline('Clear, readable text and numbers'),
                    _guideline('Both front and back sides'),
                    _guideline('Must not be expired'),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Upload Button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _uploadLicense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.image_search, size: 20),
                  label: Text(
                    _licenseUploaded ? 'Change License' : 'Upload License',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onTertiary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Continue Button (only enabled if license uploaded)
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _licenseUploaded ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _licenseUploaded
                        ? AppColors.tertiary
                        : AppColors.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _licenseUploaded
                          ? Colors.white
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guideline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: AppColors.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressStep(int step, bool isCompleted) {
    final isActive = step <= 3;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive || isCompleted
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
                  color: isActive ? Colors.white : AppColors.onSurfaceVariant,
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
}
