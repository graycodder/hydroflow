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
  String? _paymentMode;
  String? _selectedSalesmanId;
  List<Salesman> _availableSalesmen = [];
  bool _isLoadingSalesmen = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isAgencyView) {
      _selectedSalesmanId = widget.currentUser.id; // Default to current user
      _fetchSalesmen();
    } else {
      _selectedSalesmanId = widget.currentUser.id;
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
            HydroFlowLoader.show(context, message: 'Adding Customer...');
          } else if (state.status == CustomerStatus.failure ||
              (state.status == CustomerStatus.success && state.successMessage != null)) {
            HydroFlowLoader.hide(context);
            if (state.status == CustomerStatus.success) {
              _isSubmitting = false;
              Navigator.of(context).pop(); // Close add dialog
            } else if (state.status == CustomerStatus.failure) {
              _isSubmitting = false;
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
                  _buildTextFormField(
                    _zoneController,
                    'Enter zone/area (e.g. Zone A)',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter customer zone';
                      }
                      return null;
                    },
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
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (_selectedSalesmanId == null) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a salesman')));
                             return;
                          }

                          final name = _nameController.text.trim();
                          final phone = _phoneController.text.trim();
                          final address = _addressController.text.trim();
                          final zone = _zoneController.text.trim();
                          final deposit = double.parse(_depositController.text.trim());

                          // Quota Check
                          final targetSalesman = widget.isAgencyView 
                              ? _availableSalesmen.firstWhere((s) => s.id == _selectedSalesmanId, orElse: () => widget.currentUser)
                              : widget.currentUser;

                          if (targetSalesman.customerCount >= targetSalesman.maxCustomers && targetSalesman.maxCustomers > 0) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text('Quota reached for ${targetSalesman.name} (${targetSalesman.customerCount}/${targetSalesman.maxCustomers})'))
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
  }) {
    return TextFormField(
      controller: controller,
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
