import 'package:flutter/material.dart';
import '../../core/errors/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/driver_repository.dart';
import '../../data/mock_data.dart';
import '../../data/vehicle_repository.dart';
import '../../models/driver.dart';
import '../../models/vehicle.dart';
import '../../router/app_router.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/confirmation_dialog.dart';

/// Reusable form screen for both Registering a new vehicle and Editing an existing vehicle.
class VehicleFormScreen extends StatefulWidget {
  final Vehicle? vehicleToEdit;
  final int? vehicleId;

  const VehicleFormScreen({
    super.key,
    this.vehicleToEdit,
    this.vehicleId,
  });

  bool get isEditing => vehicleToEdit != null || vehicleId != null;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _numberController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;

  final _numberFocusNode = FocusNode();
  final _brandFocusNode = FocusNode();
  final _modelFocusNode = FocusNode();

  String? _selectedCompany;
  String? _selectedType;
  VehicleStatus _selectedStatus = VehicleStatus.active;
  int? _selectedDriverId;
  List<Driver> _availableDrivers = [];

  bool _isSaving = false;
  bool _isLoadingRecord = false;
  String? _loadRecordError;
  Vehicle? _loadedVehicle;

  final Map<String, String> _serverFieldErrors = {};

  // Track initial values to determine whether form is dirty
  String _initialNumber = '';
  String? _initialCompany;
  String? _initialType;
  String _initialBrand = '';
  String _initialModel = '';
  VehicleStatus _initialStatus = VehicleStatus.active;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController();
    _brandController = TextEditingController();
    _modelController = TextEditingController();

    DriverRepository.instance.getAvailableDrivers().then((drivers) {
      if (mounted) setState(() => _availableDrivers = drivers);
    }).catchError((_) {});

    if (widget.vehicleToEdit != null) {
      _initFromVehicle(widget.vehicleToEdit!);
    } else if (widget.vehicleId != null) {
      final cached = VehicleRepository.instance.getById(widget.vehicleId!);
      if (cached != null) {
        _initFromVehicle(cached);
      } else {
        _isLoadingRecord = true;
        _initControllersEmpty();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadVehicleRecord(widget.vehicleId!);
        });
      }
    } else {
      _initControllersEmpty();
    }
  }

  void _initControllersEmpty() {
    _initialNumber = '';
    _initialCompany = kDefaultCompanies.first;
    _initialType = kDefaultVehicleTypes.first;
    _initialBrand = '';
    _initialModel = '';
    _initialStatus = VehicleStatus.active;

    _numberController.text = '';
    _selectedCompany = _initialCompany;
    _selectedType = _initialType;
    _brandController.text = '';
    _modelController.text = '';
    _selectedStatus = _initialStatus;
    _selectedDriverId = null;
  }

  void _initFromVehicle(Vehicle v) {
    _loadedVehicle = v;
    _initialNumber = v.vehicleNumber;
    _initialCompany = v.company;
    _initialType = v.type;
    _initialBrand = v.brand;
    _initialModel = v.model;
    _initialStatus = v.status;

    _numberController.text = _initialNumber;
    _selectedCompany = _initialCompany;
    _selectedType = _initialType;
    _brandController.text = _initialBrand;
    _modelController.text = _initialModel;
    _selectedStatus = _initialStatus;
    _selectedDriverId = v.assignedDriver?.id;
  }

  Future<void> _loadVehicleRecord(int id) async {
    try {
      final vehicle = await VehicleRepository.instance.fetchVehicleById(id);
      if (!mounted) return;
      setState(() {
        _isLoadingRecord = false;
        _loadRecordError = null;
        _initFromVehicle(vehicle);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingRecord = false;
        _loadRecordError = e.isNotFound
            ? 'Vehicle #$id was not found.'
            : e.message;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingRecord = false;
        _loadRecordError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingRecord = false;
        _loadRecordError = 'Failed to load vehicle record: $e';
      });
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _numberFocusNode.dispose();
    _brandFocusNode.dispose();
    _modelFocusNode.dispose();
    super.dispose();
  }

  bool get _isDirty {
    if (_isLoadingRecord || _loadRecordError != null) return false;
    return _numberController.text.trim() != _initialNumber.trim() ||
        _selectedCompany != _initialCompany ||
        _selectedType != _initialType ||
        _brandController.text.trim() != _initialBrand.trim() ||
        _modelController.text.trim() != _initialModel.trim() ||
        _selectedStatus != _initialStatus;
  }

  Vehicle? get _targetVehicle => widget.vehicleToEdit ?? _loadedVehicle;
  int? get _targetVehicleId => _targetVehicle?.id ?? widget.vehicleId;

  Future<void> _handleCancel() async {
    if (_isDirty) {
      final discard = await ConfirmationDialog.showDiscard(context);
      if (!discard) return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    setState(() {
      _serverFieldErrors.clear();
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final trimmedNumber = _numberController.text.trim();
    final repo = VehicleRepository.instance;
    final activeId = _targetVehicleId;

    // Early client advisory check to provide instant feedback
    final isDuplicate = repo.isVehicleNumberDuplicate(
      trimmedNumber,
      excludeId: activeId,
    );

    if (isDuplicate) {
      setState(() {
        _serverFieldErrors['vehicleNumber'] =
            'A vehicle with Vehicle Number "$trimmedNumber" is already registered. A vehicle with this Vehicle Number already exists.';
      });
      _numberFocusNode.requestFocus();
      return;
    }

    setState(() => _isSaving = true);

    final vehicle = Vehicle(
      id: activeId ?? 0,
      vehicleNumber: trimmedNumber,
      company: _selectedCompany ?? kDefaultCompanies.first,
      type: _selectedType ?? kDefaultVehicleTypes.first,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      status: _selectedStatus,
    );

    try {
      final Vehicle result;
      if (widget.isEditing && activeId != null && activeId > 0) {
        result = await repo.update(vehicle, assignedDriverId: _selectedDriverId);
      } else {
        result = await repo.add(vehicle, assignedDriverId: _selectedDriverId);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Vehicle ${result.vehicleNumber} successfully updated.'
                : 'Vehicle ${result.vehicleNumber} successfully registered.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(result);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        if (e.isDuplicateVehicleNumber) {
          _serverFieldErrors['vehicleNumber'] =
              e.getFieldError('vehicleNumber') ??
                  'A vehicle with this Vehicle Number already exists.';
          _numberFocusNode.requestFocus();
        } else if (e.isValidationFailed && e.fieldErrors.isNotEmpty) {
          for (final fe in e.fieldErrors) {
            _serverFieldErrors[fe.field] = fe.message;
          }
          if (_serverFieldErrors.containsKey('vehicleNumber')) {
            _numberFocusNode.requestFocus();
          } else if (_serverFieldErrors.containsKey('brand')) {
            _brandFocusNode.requestFocus();
          } else if (_serverFieldErrors.containsKey('model')) {
            _modelFocusNode.requestFocus();
          }
        }
      });

      if (e.isNotFound) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vehicle record is no longer available.',
            ),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Fleet List',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context)
                    .pushReplacementNamed(AppRouter.vehiclesRoute);
              },
            ),
          ),
        );
      } else if (!e.isDuplicateVehicleNumber && !e.isValidationFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save vehicle: $e'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit Vehicle' : 'Register Vehicle';
    final isDesktop = Responsive.isDesktop(context);

    if (_isLoadingRecord) {
      return AppShell(
        title: title,
        showBackButton: true,
        onBack: _handleCancel,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppTheme.space16),
              Text(
                'Loading vehicle details...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadRecordError != null) {
      return AppShell(
        title: title,
        showBackButton: true,
        onBack: _handleCancel,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppTheme.errorRed,
                    ),
                    const SizedBox(height: AppTheme.space16),
                    const Text(
                      'Vehicle Not Available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      _loadRecordError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Back to Fleet List'),
                        ),
                        if (widget.vehicleId != null) ...[
                          const SizedBox(width: AppTheme.space12),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isLoadingRecord = true;
                                _loadRecordError = null;
                              });
                              _loadVehicleRecord(widget.vehicleId!);
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retry'),
                          ),
                        ],
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

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final discard = await ConfirmationDialog.showDiscard(context);
        if (discard && mounted) {
          nav.pop();
        }
      },
      child: AppShell(
        title: title,
        showBackButton: true,
        onBack: _handleCancel,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFormHeader(title),
                    const SizedBox(height: AppTheme.space24),
                    _buildIdentityCard(isDesktop),
                    const SizedBox(height: AppTheme.space20),
                    _buildDetailsCard(isDesktop),
                    const SizedBox(height: AppTheme.space20),
                    _buildStatusCard(),
                    const SizedBox(height: AppTheme.space24),
                    _buildFormActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.isEditing
              ? 'Update vehicle details and status.'
              : 'Add a new vehicle to the fleet registry.',
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildIdentityCard(bool isDesktop) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Vehicle Identity',
                'Registration number and company'),
            const SizedBox(height: AppTheme.space16),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildVehicleNumberField()),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(child: _buildCompanyField()),
                ],
              )
            else ...[
              _buildVehicleNumberField(),
              const SizedBox(height: AppTheme.space16),
              _buildCompanyField(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(bool isDesktop) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Vehicle Details',
                'Type, brand, and model'),
            const SizedBox(height: AppTheme.space16),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTypeField()),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(child: _buildBrandField()),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(child: _buildModelField()),
                ],
              )
            else ...[
              _buildTypeField(),
              const SizedBox(height: AppTheme.space16),
              _buildBrandField(),
              const SizedBox(height: AppTheme.space16),
              _buildModelField(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Fleet Status & Driver',
                'Current deployment status and assigned driver'),
            const SizedBox(height: AppTheme.space16),
            Wrap(
              spacing: AppTheme.space24,
              runSpacing: AppTheme.space16,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: _buildStatusField(),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: _buildDriverField(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assigned Driver',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark),
        ),
        const SizedBox(height: AppTheme.space4),
        DropdownButtonFormField<int?>(
          initialValue: _selectedDriverId,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Unassigned (No Driver)', style: TextStyle(fontStyle: FontStyle.italic)),
            ),
            ..._availableDrivers.map((d) {
              return DropdownMenuItem<int?>(
                value: d.id,
                child: Text('${d.name} (${d.licenseNumber}) - ${d.status.label}'),
              );
            }),
          ],
          onChanged: (val) {
            setState(() => _selectedDriverId = val);
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildVehicleNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Number *',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark),
        ),
        const SizedBox(height: AppTheme.space4),
        TextFormField(
          controller: _numberController,
          focusNode: _numberFocusNode,
          decoration: InputDecoration(
            hintText: 'e.g. STK-1001',
            errorText: _serverFieldErrors['vehicleNumber'],
          ),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return 'Vehicle Number is required.';
            }
            if (trimmed.length > 64) {
              return 'Vehicle Number cannot exceed 64 characters.';
            }
            return null;
          },
          onChanged: (_) {
            if (_serverFieldErrors.containsKey('vehicleNumber')) {
              setState(() => _serverFieldErrors.remove('vehicleNumber'));
            }
          },
        ),
      ],
    );
  }

  Widget _buildCompanyField() {
    final availableCompanies = {
      ...kDefaultCompanies,
      if (_selectedCompany != null && _selectedCompany!.isNotEmpty)
        _selectedCompany!,
      for (final v in VehicleRepository.instance.allVehicles) v.company,
    }.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company *',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark),
        ),
        const SizedBox(height: AppTheme.space4),
        DropdownButtonFormField<String>(
          initialValue: _selectedCompany,
          isExpanded: true,
          decoration: InputDecoration(
            errorText: _serverFieldErrors['company'],
          ),
          items: availableCompanies.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(c, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedCompany = val;
                _serverFieldErrors.remove('company');
              });
            }
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Company is required.';
            }
            if (value.trim().length > 120) {
              return 'Company cannot exceed 120 characters.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTypeField() {
    final availableTypes = {
      ...kDefaultVehicleTypes,
      if (_selectedType != null && _selectedType!.isNotEmpty) _selectedType!,
      for (final v in VehicleRepository.instance.allVehicles) v.type,
    }.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type *',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark),
        ),
        const SizedBox(height: AppTheme.space4),
        DropdownButtonFormField<String>(
          initialValue: _selectedType,
          isExpanded: true,
          decoration: InputDecoration(
            errorText: _serverFieldErrors['type'],
          ),
          items: availableTypes.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text(t, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedType = val;
                _serverFieldErrors.remove('type');
              });
            }
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vehicle Type is required.';
            }
            if (value.trim().length > 60) {
              return 'Vehicle Type cannot exceed 60 characters.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBrandField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Brand *',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark),
        ),
        const SizedBox(height: AppTheme.space4),
        TextFormField(
          controller: _brandController,
          focusNode: _brandFocusNode,
          decoration: InputDecoration(
            hintText: 'e.g. Mercedes-Benz, Volvo',
            errorText: _serverFieldErrors['brand'],
          ),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return 'Brand is required.';
            }
            if (trimmed.length > 80) {
              return 'Brand cannot exceed 80 characters.';
            }
            return null;
          },
          onChanged: (_) {
            if (_serverFieldErrors.containsKey('brand')) {
              setState(() => _serverFieldErrors.remove('brand'));
            }
          },
        ),
      ],
    );
  }

  Widget _buildModelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Model *',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark),
        ),
        const SizedBox(height: AppTheme.space4),
        TextFormField(
          controller: _modelController,
          focusNode: _modelFocusNode,
          decoration: InputDecoration(
            hintText: 'e.g. Sprinter 2500, Model 3',
            errorText: _serverFieldErrors['model'],
          ),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return 'Model is required.';
            }
            if (trimmed.length > 120) {
              return 'Model cannot exceed 120 characters.';
            }
            return null;
          },
          onChanged: (_) {
            if (_serverFieldErrors.containsKey('model')) {
              setState(() => _serverFieldErrors.remove('model'));
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status *',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark),
        ),
        const SizedBox(height: AppTheme.space4),
        DropdownButtonFormField<VehicleStatus>(
          initialValue: _selectedStatus,
          isExpanded: true,
          decoration: InputDecoration(
            errorText: _serverFieldErrors['status'],
          ),
          items: VehicleStatus.values.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: s.dotColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(s.label, style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedStatus = val;
                _serverFieldErrors.remove('status');
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildFormActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _isSaving ? null : _handleCancel,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: AppTheme.space12),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.isEditing ? 'Save changes' : 'Register vehicle'),
        ),
      ],
    );
  }
}
