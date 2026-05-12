import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../services/supabase_service.dart';

class BenefitsScreen extends StatefulWidget {
  const BenefitsScreen({super.key});

  @override
  State<BenefitsScreen> createState() => _BenefitsScreenState();
}

class _BenefitsScreenState extends State<BenefitsScreen> {
  int _selectedBenefit = -1;
  String? _uploadedFileName;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _benefits = [
    {
      'title': 'Regular',
      'subtitle': 'Standard fare, no ID required',
      'icon': Icons.person_rounded,
      'color': AppColors.outline,
      'requiresId': false,
    },
    {
      'title': 'Student Discount',
      'subtitle': 'Valid Student ID required • 20% off',
      'icon': Icons.school_rounded,
      'color': AppColors.primary,
      'requiresId': true,
    },
    {
      'title': 'Senior Citizen',
      'subtitle': 'Senior Citizen ID required • 20% off',
      'icon': Icons.elderly_woman_rounded,
      'color': AppColors.tertiary,
      'requiresId': true,
    },
    {
      'title': 'PWD Discount',
      'subtitle': 'PWD ID required • 20% off',
      'icon': Icons.accessible_rounded,
      'color': AppColors.secondary,
      'requiresId': true,
    },
  ];

  bool get _requiresId =>
      _selectedBenefit > 0 &&
      (_benefits[_selectedBenefit]['requiresId'] as bool);

  void _selectBenefit(int index) {
    setState(() {
      _selectedBenefit = index;
      if (!(_benefits[index]['requiresId'] as bool)) {
        _uploadedFileName = null;
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedBenefit == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a fare type',
              style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_requiresId && _uploadedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload your ID to avail the discount',
              style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    const typeMap = ['regular', 'student', 'senior', 'pwd'];
    try {
      await SupabaseService.updateBenefitType(typeMap[_selectedBenefit]);
    } catch (_) {}
    if (mounted) context.go('/passenger');
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
        actions: const [],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select your fare type',
                style: GoogleFonts.lexend(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose Regular or apply for a discounted fare with a valid ID.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.outline,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // Benefit options
              ...List.generate(_benefits.length, (index) {
                final benefit = _benefits[index];
                final isSelected = _selectedBenefit == index;
                final color = benefit['color'] as Color;
                final requiresId = benefit['requiresId'] as bool;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _selectBenefit(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.08)
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? color
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
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(benefit['icon'] as IconData,
                                color: color, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      benefit['title'] as String,
                                      style: GoogleFonts.lexend(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    if (!requiresId) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.outline
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'No ID needed',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.outline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
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
                          const SizedBox(width: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: isSelected
                                ? Icon(Icons.check_circle_rounded,
                                    key: const ValueKey('checked'),
                                    color: color, size: 22)
                                : Icon(Icons.radio_button_unchecked_rounded,
                                    key: const ValueKey('unchecked'),
                                    color: AppColors.outlineVariant, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Upload section — only shown when a benefit with ID is selected
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _requiresId
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UPLOAD VALID ID',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.outline,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => setState(
                                  () => _uploadedFileName = 'valid_id.jpg'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 24, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: _uploadedFileName != null
                                      ? AppColors.primary.withValues(alpha: 0.05)
                                      : AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _uploadedFileName != null
                                        ? AppColors.primary
                                        : AppColors.outline
                                            .withValues(alpha: 0.25),
                                    width: _uploadedFileName != null ? 2 : 1,
                                    style: _uploadedFileName != null
                                        ? BorderStyle.solid
                                        : BorderStyle.solid,
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
                                      size: 34,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _uploadedFileName != null
                                          ? _uploadedFileName!
                                          : 'Tap to upload a photo of your ID',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: _uploadedFileName != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: _uploadedFileName != null
                                            ? AppColors.primary
                                            : AppColors.outline,
                                      ),
                                    ),
                                    if (_uploadedFileName == null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'JPG, PNG or PDF • Max 5MB',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: AppColors.outline
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (_uploadedFileName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _uploadedFileName = null),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.close_rounded,
                                          size: 14, color: AppColors.outline),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Remove file',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppColors.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _selectedBenefit == 0
                              ? 'Continue as Regular'
                              : 'Submit for Review',
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
