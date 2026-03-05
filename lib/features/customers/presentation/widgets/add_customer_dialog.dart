import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_event.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_state.dart';
import 'package:flutter/services.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';
import 'package:hydroflow/features/auth/domain/repositories/agency_repository.dart';
import 'package:hydroflow/core/service_locator.dart' as di;
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';
import 'package:firebase_database/firebase_database.dart';

class AddCustomerDialog extends StatefulWidget {
  final Salesman currentUser;
  final CustomerBloc bloc;
  final bool isAgencyView;

  const AddCustomerDialog({
    super.key,
    required this.currentUser,
    required this.bloc,
    this.isAgencyView = false,
  });

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _zoneController = TextEditingController();
  final _depositController = TextEditingController();
  final _zoneFocusNode = FocusNode();
  String? _paymentMode;
  String? _selectedSalesmanId;
  List<Salesman> _availableSalesmen = [];
  bool _isLoadingSalesmen = false;
  bool _isSubmitting = false;
  List<String> _agencyZones = [];

  @override
  void initState() {
    super.initState();
    if (widget.isAgencyView) {
      _selectedSalesmanId = widget.currentUser.id; // Default to current user
      _fetchSalesmen();
    } else {
      _selectedSalesmanId = widget.currentUser.id;
    }
    _fetchAgencyZones();
  }

  Future<void> _fetchAgencyZones() async {
    try {
      final ref = FirebaseDatabase.instance.ref().child('Customers');
      final snapshot = await ref.orderByChild('agencyId').equalTo(widget.currentUser.agencyId).get();
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
            _agencyZones = zones.toList()..sort();
          });
        }
      }
    } catch (e) {
      print('Error fetching agency zones: $e');
    }
  }

  Future<void> _fetchSalesmen() async {
    setState(() => _isLoadingSalesmen = true);
    try {
      final repo = di.sl<AgencyRepository>();
      final salesmen = await repo.getSalesmenByAgency(widget.currentUser.agencyId);
      if (mounted) {
        setState(() {
          _availableSalesmen = salesmen;
          // Ensure selected ID is valid (it should be since owner is in the list usually, 
          // or we pick the first one if owner not found for some reason)
           if (!_availableSalesmen.any((s) => s.id == _selectedSalesmanId) && _availableSalesmen.isNotEmpty) {
             _selectedSalesmanId = _availableSalesmen.first.id;
           }
          _isLoadingSalesmen = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSalesmen = false);
      print('Error fetching salesmen: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _zoneController.dispose();
    _zoneFocusNode.dispose();
    _depositController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerBloc, CustomerState>(
      bloc: widget.bloc,
      listener: (context, state) {
        if (_isSubmitting) {
          if (state.status == CustomerStatus.submitting) {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
            HydroFlowLoader.show(context, message: 'Adding Customer...');
          } else if (state.status == CustomerStatus.failure ||
              (state.status == CustomerStatus.success && state.successMessage != null)) {
            HydroFlowLoader.hide(context);
            if (state.status == CustomerStatus.success) {
              _isSubmitting = false;
              Navigator.of(context, rootNavigator: true).pop(); // Close add dialog explicitly from root
            } else if (state.status == CustomerStatus.failure) {
              _isSubmitting = false;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Error'),
                  content: Text(state.errorMessage ?? 'Failed to add customer. Please try again.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
          }
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24),
                      const Text(
                        'Add New Customer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (widget.isAgencyView) ...[
                    _buildLabel('Assign To Salesman', isMandatory: true),
                    if (_isLoadingSalesmen)
                      const Padding(padding: EdgeInsets.all(8.0), child: Center(child: CircularProgressIndicator()))
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedSalesmanId,
                        isExpanded: true,
                        hint: const Text('Select Salesman'),
                        items: _availableSalesmen.map((s) {
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.name} (${s.role})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedSalesmanId = val);
                        },
                         decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                  ],

                  _buildLabel('Customer Name', isMandatory: true),
                  _buildTextFormField(
                    _nameController,
                    'Enter name',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter customer name';
                      }
                      if (value.trim().length > 20) {
                        return 'Name must be at most 20 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Phone Number', isMandatory: true),
                  _buildTextFormField(
                    _phoneController,
                    'Enter 10 digit number',
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
                  const SizedBox(height: 16),
                  _buildLabel('Address', isMandatory: true),
                  _buildTextFormField(
                    _addressController,
                    'Enter address',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter address';
                      }
                      if (value.trim().length > 40) {
                        return 'Address must be at most 40 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Zone (Area)', isMandatory: true),
                  LayoutBuilder(
                    builder: (context, constraints) => RawAutocomplete<String>(
                      textEditingController: _zoneController,
                      focusNode: _zoneFocusNode,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                      final Set<String> combinedZones = {..._agencyZones};
                      for (var c in widget.bloc.state.customers) {
                        if (c.zone.isNotEmpty) combinedZones.add(c.zone.trim());
                      }
                      final suggestions = combinedZones.toList()..sort();

                      if (textEditingValue.text.isEmpty) {
                        return suggestions;
                      }
                        return suggestions.where((String option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        _zoneController.text = selection;
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return _buildTextFormField(
                          controller,
                          'Enter zone/area (e.g. Zone A)',
                          focusNode: focusNode,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter customer zone';
                            }
                            return null;
                          },
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: 200, maxWidth: constraints.maxWidth),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return InkWell(
                                    onTap: () => onSelected(option),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      child: Text(option[0].toUpperCase() + option.substring(1)),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Security Deposit (₹)', isMandatory: true),
                  _buildTextFormField(
                    _depositController,
                    'Enter deposit amount',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter security deposit';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null) {
                        return 'Please enter a valid amount';
                      }
                      if (amount > 100000) {
                        return 'Deposit cannot exceed ₹1,00,000';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Payment Mode', isMandatory: true),
                  DropdownButtonFormField<String>(
                    value: _paymentMode,
                    hint: const Text('Select Payment Mode'),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: ['Cash', 'Online', 'UPI'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _paymentMode = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select payment mode';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // First, unfocus any active text field
                          FocusScope.of(context).unfocus();
                          // Also clear primary focus to be sure
                          FocusManager.instance.primaryFocus?.unfocus();

                          // Give the keyboard a moment to start dismissing
                          await Future.delayed(const Duration(milliseconds: 100));

                          if (!mounted) return;

                          if (_selectedSalesmanId == null) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a salesman')));
                            return;
                          }

                          // Data collection
                          final name = _nameController.text.trim();
                          final phone = _phoneController.text.trim();
                          final address = _addressController.text.trim();
                          final zone = _zoneController.text.trim();
                          final deposit = double.parse(_depositController.text.trim());

                          // Quota Check
                          final targetSalesman = widget.isAgencyView
                              ? _availableSalesmen.firstWhere((s) => s.id == _selectedSalesmanId, orElse: () => widget.currentUser)
                              : widget.currentUser;

                          if (targetSalesman.customerCount >= targetSalesman.maxCustomers) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Limit Reached'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Insufficient customer quota for ${targetSalesman.name}.'),
                                    const SizedBox(height: 8),
                                    Text('Current Count: ${targetSalesman.customerCount}'),
                                    Text('Maximum Allowed: ${targetSalesman.maxCustomers}'),
                                    const Divider(height: 24),
                                    const Text(
                                      'Please contact support to upgrade your quota.',
                                      style: TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D1117),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Contact Support'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          showDialog(
                            context: context,
                            builder: (confirmContext) => AlertDialog(
                              title: const Text('Confirm Addition'),
                              content: Text('Are you sure you want to add "$name" as a new customer?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(confirmContext),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();
                                    FocusManager.instance.primaryFocus?.unfocus();
                                    setState(() {
                                      _isSubmitting = true;
                                    });
                                    Navigator.pop(confirmContext);
                                    widget.bloc.add(AddCustomer(
                                      agencyId: widget.currentUser.agencyId,
                                      salesmanId: _selectedSalesmanId!,
                                      name: name,
                                      phone: phone,
                                      address: address,
                                      zone: zone,
                                      securityDeposit: deposit,
                                      paymentMode: _paymentMode!,
                                    ));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D1117),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add Customer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool isMandatory = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black,
          ),
          children: [
            if (isMandatory)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
