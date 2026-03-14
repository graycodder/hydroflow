import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watermemo/features/auth/domain/entities/salesman.dart';
import 'package:watermemo/features/auth/domain/repositories/agency_repository.dart';
import 'package:watermemo/core/service_locator.dart' as di;
import 'package:watermemo/core/widgets/hydro_flow_loader.dart';
import 'package:firebase_database/firebase_database.dart';

class EditSalesmanDialog extends StatefulWidget {
  final Salesman salesman;
  final int maxAgencyCustomers;
  final List<Salesman> existingSalesmen;

  const EditSalesmanDialog({
    super.key,
    required this.salesman,
    this.maxAgencyCustomers = 0,
    this.existingSalesmen = const [],
  });

  @override
  State<EditSalesmanDialog> createState() => _EditSalesmanDialogState();
}

class _EditSalesmanDialogState extends State<EditSalesmanDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
 // late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _zoneController;
  late TextEditingController _quotaController;
  bool _isChecking = false;
  bool _isPasswordVisible = false;
  String? _phoneError;
  List<String> _availableZones = [];
  List<String> _selectedZones = [];
  bool _isLoadingZones = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.salesman.name);
    _phoneController = TextEditingController(text: widget.salesman.phoneNumber);
    _phoneController.addListener(_onPhoneChanged);
   // _usernameController = TextEditingController(text: widget.salesman.username);
    _passwordController = TextEditingController(text: widget.salesman.password);
    _zoneController = TextEditingController(text: widget.salesman.zone);
  //  _quotaController = TextEditingController(text: widget.salesman.maxCustomers.toString());
    // Pre-populate selected zones from existing salesman data
    if (widget.salesman.zone.isNotEmpty) {
      _selectedZones = widget.salesman.zone.split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e.toLowerCase() != 'all')
          .toList();
    }
    _fetchAgencyZones();
  }

  Future<void> _fetchAgencyZones() async {
    setState(() => _isLoadingZones = true);
    try {
      final ref = FirebaseDatabase.instance.ref().child('Customers');
      final snapshot = await ref.orderByChild('agencyId').equalTo(widget.salesman.agencyId).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final Set<String> zones = {};
        for (final value in data.values) {
          final customer = Map<String, dynamic>.from(value as Map);
          final zone = customer['zone'] as String?;
          if (zone != null && zone.trim().isNotEmpty) {
            zones.add(zone.trim());
          }
        }
        if (mounted) {
          setState(() {
            _availableZones = zones.toList()..sort();
            _isLoadingZones = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingZones = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingZones = false);
      print('Error fetching zones: $e');
    }
  }

  void _onPhoneChanged() {
    if (_phoneError != null) {
      setState(() {
        _phoneError = null;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
  //  _usernameController.dispose();
    _passwordController.dispose();
    _zoneController.dispose();
   // _quotaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      FocusManager.instance.primaryFocus?.unfocus();

      // Give keyboard a moment to dismiss
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      setState(() => _isChecking = true);
      WaterMemoLoader.show(context, message: 'Checking phone number...');

      try {
        final repo = di.sl<AgencyRepository>();
        final phone = _phoneController.text.trim();
        final isUnique = await repo.isPhoneNumberUnique(phone, excludeSalesmanId: widget.salesman.id);

        if (!mounted) return;
        WaterMemoLoader.hide(context);

        if (!isUnique) {
          setState(() {
            _isChecking = false;
            _phoneError = 'Phone number already in use';
          });
          return;
        }

        final updatedSalesman = widget.salesman.copyWith(
          name: _nameController.text.trim(),
          phoneNumber: phone,
          zone: _selectedZones.isEmpty ? 'all' : _selectedZones.join(', '),
          maxCustomers: widget.salesman.maxCustomers,
          password: _passwordController.text.trim().isNotEmpty 
              ? _passwordController.text.trim() 
              : widget.salesman.password, 
        );

        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.pop(context, updatedSalesman);
      } catch (e) {
        if (mounted) {
          WaterMemoLoader.hide(context);
          setState(() => _isChecking = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error validating phone number: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate remaining quota EXCLUDING this salesman's current quota
    final otherAllocated = widget.existingSalesmen
        .where((s) => s.id != widget.salesman.id)
        .fold<int>(0, (sum, s) => sum + s.maxCustomers);
    final remainingForThisUser = widget.maxAgencyCustomers - otherAllocated;

    return AlertDialog(
      title: Text('Edit Salesman: ${widget.salesman.name}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
                ],
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter name';
                  }
                  if (value.trim().length > 20) {
                    return 'Name must be at most 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  errorText: _phoneError,
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.trim().length != 10) {
                    return 'Phone number must be exactly 10 digits';
                  }
                  return null;
                },
              ),
              // const SizedBox(height: 12),
              // TextFormField(
              //   controller: _usernameController,
              //   decoration: const InputDecoration(
              //     labelText: 'Username',
              //     helperText: 'Cannot be changed',
              //     enabled: false, 
              //     filled: true,
              //   ),
              //   readOnly: true,
              // ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  helperText: 'Leave blank to keep current password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Min 6 characters';
                  }
                  return null;
                },
              ),
                const SizedBox(height: 12),
              // Custom Multi-Select Zone Picker
              _buildZonePicker(),
              // const SizedBox(height: 12),
              // TextFormField(
              //   controller: _quotaController,
              //   decoration: InputDecoration(
              //     labelText: 'Customer Quota',
              //     helperText: 'Agency Limit: ${widget.maxAgencyCustomers}. Already used by others: $otherAllocated. Available for this salesman: $remainingForThisUser',
              //     helperMaxLines: 3,
              //   ),
              //   keyboardType: TextInputType.number,
              //   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              //   onChanged: (value) {
              //     if (value.length > 1 && value.startsWith('0')) {
              //       String newText = value.replaceFirst(RegExp(r'^0+'), '');
              //       if (newText.isEmpty) newText = '0';
              //       _quotaController.value = TextEditingValue(
              //         text: newText,
              //         selection: TextSelection.collapsed(offset: newText.length),
              //       );
              //     }
              //   },
              //   validator: (value) {
              //     if (value == null || value.isEmpty) return 'Please enter quota';
              //     final qty = int.tryParse(value);
              //     if (qty == null || qty < 0) return 'Enter a valid number';
                  
              //     if (qty > remainingForThisUser) {
              //       return 'Exceeds Agency Limit ($remainingForThisUser remaining)';
              //     }
              //     return null;
              //   },
              // ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isChecking ? null : _submit,
          child: _isChecking 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Update'),
        ),
      ],
    );
  }

  // ----- Custom Zone Picker -----
  Widget _buildZonePicker() {
    if (_isLoadingZones) {
      return const Center(child: CircularProgressIndicator());
    }

    final actualRoutes = _availableZones.where((z) => z != 'All').toList();
    final allSelected = actualRoutes.isNotEmpty &&
        actualRoutes.every((z) => _selectedZones.contains(z));
    final displayText = _selectedZones.isEmpty
        ? 'Tap to assign routes'
        : (allSelected ? 'All Routes' : _selectedZones.join(', '));

    return FormField<List<String>>(
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                await _openZonePicker(actualRoutes);
                state.didChange(_selectedZones);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Assign Route / Zone',
                  prefixIcon: const Icon(Icons.map_outlined),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  errorText: state.errorText,
                ),
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: _selectedZones.isEmpty ? Theme.of(context).hintColor : null,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openZonePicker(List<String> actualRoutes) async {
    final tempSelected = List<String>.from(_selectedZones);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isAllSelected = actualRoutes.isNotEmpty &&
                actualRoutes.every((z) => tempSelected.contains(z));

            void toggleAll() {
              setDialogState(() {
                if (isAllSelected) {
                  tempSelected.clear();
                } else {
                  tempSelected.clear();
                  tempSelected.addAll(actualRoutes);
                }
              });
            }

            void toggleRoute(String route) {
              setDialogState(() {
                if (tempSelected.contains(route)) {
                  tempSelected.remove(route);
                } else {
                  tempSelected.add(route);
                }
              });
            }

            return AlertDialog(
              title: const Text('Select Routes / Zones'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      value: isAllSelected,
                      title: const Text('All Routes', style: TextStyle(fontWeight: FontWeight.bold)),
                      secondary: const Icon(Icons.select_all),
                      onChanged: (_) => toggleAll(),
                    ),
                    const Divider(height: 1),
                    if (actualRoutes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No routes found. Add customers with zones first.'),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView(
                          shrinkWrap: true,
                          children: actualRoutes.map((route) => CheckboxListTile(
                            value: tempSelected.contains(route),
                            title: Text(route),
                            onChanged: (_) => toggleRoute(route),
                          )).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedZones.clear();
                      _selectedZones.addAll(tempSelected);
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
