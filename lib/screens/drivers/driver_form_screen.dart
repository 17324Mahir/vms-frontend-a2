import 'package:flutter/material.dart';

import '../../core/errors/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../data/driver_repository.dart';
import '../../models/driver.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/workspace_section_header.dart';

class DriverFormScreen extends StatefulWidget {
  final Driver? driverToEdit;

  const DriverFormScreen({super.key, this.driverToEdit});

  @override
  State<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends State<DriverFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DriverRepository _driverRepo = DriverRepository.instance;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _licenseCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;

  DriverStatus _status = DriverStatus.available;
  DateTime? _licenseExpiryDate;

  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditMode => widget.driverToEdit != null;

  @override
  void initState() {
    super.initState();
    final d = widget.driverToEdit;
    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _licenseCtrl = TextEditingController(text: d?.licenseNumber ?? '');
    _phoneCtrl = TextEditingController(text: d?.phone ?? '');
    _emailCtrl = TextEditingController(text: d?.email ?? '');
    if (d != null) {
      _status = d.status;
      _licenseExpiryDate = d.licenseExpiryDate;
    } else {
      _licenseExpiryDate = DateTime.now().add(const Duration(days: 365 * 2));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _licenseCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final payload = {
      'name': _nameCtrl.text.trim(),
      'licenseNumber': _licenseCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isNotEmpty
          ? _phoneCtrl.text.trim()
          : null,
      'email': _emailCtrl.text.trim().isNotEmpty
          ? _emailCtrl.text.trim()
          : null,
      'status': _status.toBackendString(),
      if (_licenseExpiryDate != null)
        'licenseExpiryDate': _licenseExpiryDate!.toIso8601String().substring(
          0,
          10,
        ),
    };

    try {
      if (_isEditMode) {
        await _driverRepo.updateDriver(widget.driverToEdit!.id, payload);
      } else {
        await _driverRepo.createDriver(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Driver updated successfully'
                  : 'Driver registered successfully',
            ),
            backgroundColor: const Color(0xFF15803D),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: _isEditMode ? 'Edit Driver' : 'Register New Driver',
      showBackButton: true,
      onBack: () => Navigator.of(context).pop(),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(AppTheme.space24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  WorkspaceSectionHeader(
                    label: 'DRIVER WORKFORCE',
                    title: _isEditMode
                        ? 'Update Driver Profile'
                        : 'Driver Registration',
                    description: 'Keep contact information, license details and availability up to date.',
                  ),
                  const SizedBox(height: AppTheme.space20),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: const Color(0xFFF87171)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.space8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                  ],
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. John Doe',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Driver name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.space16),
                  TextFormField(
                    controller: _licenseCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Driver License Number *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. DL-88741-XYZ',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'License number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.space16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                            hintText: '+1-555-0100',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: TextFormField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            border: OutlineInputBorder(),
                            hintText: 'driver@starkgroup.com',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<DriverStatus>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: 'Driver Status *',
                            border: OutlineInputBorder(),
                          ),
                          items: DriverStatus.values.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(s.label),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _status = val);
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _licenseExpiryDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2050),
                            );
                            if (picked != null) {
                              setState(() => _licenseExpiryDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'License Expiry Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _licenseExpiryDate != null
                                  ? _licenseExpiryDate!
                                        .toIso8601String()
                                        .substring(0, 10)
                                  : 'Select Date',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : (_isEditMode ? 'Update Driver' : 'Save Driver'),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.navy900,
                        ),
                      ),
                    ],
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
