import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

class BenefitsScreen extends StatefulWidget {
  const BenefitsScreen({super.key});

  @override
  State<BenefitsScreen> createState() => _BenefitsScreenState();
}

class _BenefitsScreenState extends State<BenefitsScreen> {
  int _selectedBenefit = 0;
  String? _uploadedFileName;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _benefits = [
    {
      'title': 'Student Discount',
      'subtitle': 'Valid Student ID required',
      'icon': Icons.school_rounded,
      'color': AppColors.primary,
    },
    {
      'title': 'Senior Citizen',
      'subtitle': 'Senior Citizen ID required',
      'icon': Icons.elderly_woman_rounded,
      'color': AppColors.tertiary,
    },
    {
      'title': 'PWD Discount',
      'subtitle': 'PWD ID required',
      'icon': Icons.accessible_rounded,
      'color': AppColors.secondary,
    },
  ];

  void _selectBenefit(int index) {
    setState(() => _selectedBenefit = index);
  }

  void _skip() {
    context.go('/passenger');
  }

  void _submit() {
    if (_selectedBenefit == 0 || _uploadedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a benefit type and upload your ID',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate upload - replace with actual backend
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/passenger');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Apply Benefits',
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _skip,
            child: Text(
              'Skip',
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.outline,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get 20% off on every ride!',
                style: GoogleFonts.lexend(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your benefit type and upload a photo of your valid ID to avail the discount.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.outline,
                ),
              ),
              const SizedBox(height: 32),

              // Benefit Options
              ...List.generate(_benefits.length, (index) {
                final benefit = _benefits[index];
                final isSelected = _selectedBenefit == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _selectBenefit(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (benefit['color'] as Color).withValues(alpha: 0.1)
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? benefit['color'] as Color
                              : AppColors.outline.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: (benefit['color'] as Color).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              benefit['icon'] as IconData,
                              color: benefit['color'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  benefit['title'] as String,
                                  style: GoogleFonts.lexend(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Text(
                                  benefit['subtitle'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: benefit['color'] as Color,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const Spacer(),

              // Upload Section
              if (_selectedBenefit > 0) ...[
                Text(
                  'UPLOAD ID',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.outline,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // Simulate file pick
                    setState(() => _uploadedFileName = 'valid_id_2024.pdf');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _uploadedFileName != null
                            ? AppColors.primary
                            : AppColors.outline.withValues(alpha: 0.2),
                        width: _uploadedFileName != null ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _uploadedFileName != null
                              ? Icons.check_circle_rounded
                              : Icons.cloud_upload_outlined,
                          color: _uploadedFileName != null
                              ? AppColors.primary
                              : AppColors.outline,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _uploadedFileName != null
                              ? _uploadedFileName!
                              : 'Tap to upload photo of your ID',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: _uploadedFileName != null
                                ? AppColors.primary
                                : AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_selectedBenefit == 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Senior discount: 20% off every ride',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                          'Submit for Review',
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Maybe later',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.outline,
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
}