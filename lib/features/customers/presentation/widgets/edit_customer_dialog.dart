import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_event.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_state.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';
import 'package:hydroflow/features/auth/domain/repositories/agency_repository.dart';
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';
import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:hydroflow/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter/services.dart';
import 'package:hydroflow/core/service_locator.dart' as di;
import 'package:firebase_database/firebase_database.dart';

class EditCustomerDialog extends StatefulWidget {
  final Customer customer;
  final Salesman currentUser;
  final CustomerBloc customerBloc;
  final bool isAgencyView;

  const EditCustomerDialog({
    super.key,
    required this.customer,
    required this.currentUser,
    required this.customerBloc,
    this.isAgencyView = false,
  });

  @override
  State<EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends State<EditCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _zoneController;
  late TextEditingController _depositController;
  final _zoneFocusNode = FocusNode();
  late String? _paymentMode;
  String? _selectedSalesmanId;
  List<Salesman> _availableSalesmen = [];
  bool _isLoadingSalesmen = false;
  bool _isSubmitting = false;
  List<String> _agencyZones = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _addressController = TextEditingController(text: widget.customer.address);
    _zoneController = TextEditingController(text: widget.customer.zone);
    _depositController = TextEditingController(text: widget.customer.securityDeposit.toStringAsFixed(0));
    _paymentMode = widget.customer.paymentMode;
    
    _selectedSalesmanId = widget.customer.salesmanId;
    
    if (widget.isAgencyView) {
      _fetchSalesmen();
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
      bloc: widget.customerBloc,
      listener: (context, state) {
        if (_isSubmitting) {
          if (state.status == CustomerStatus.submitting) {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
            HydroFlowLoader.show(context, message: 'Saving Changes...');
          } else if (state.status == CustomerStatus.failure || 
                     (state.status == CustomerStatus.success && state.successMessage != null)) {
            HydroFlowLoader.hide(context);
            if (state.status == CustomerStatus.success) {
              _isSubmitting = false;
              Navigator.of(context, rootNavigator: true).pop(); // Close edit dialog explicitly from root
            } else if (state.status == CustomerStatus.failure) {
              _isSubmitting = false;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Error'),
                  content: Text(state.errorMessage ?? 'Failed to update customer. Please try again.'),
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24),
                    const Column(
                      children: [
                        Text(
                          'Edit Customer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Update customer information',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (widget.isAgencyView) ...[
                    Align(alignment: Alignment.centerLeft, child: _buildLabel('Assign To Salesman', isMandatory: true)),
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
                  '98765 43212', 
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
                _buildLabel('Zone', isMandatory: true),
                LayoutBuilder(
                  builder: (context, constraints) => RawAutocomplete<String>(
                    textEditingController: _zoneController,
                    focusNode: _zoneFocusNode,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final Set<String> combinedZones = {..._agencyZones};
                      for (var c in widget.customerBloc.state.customers) {
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
                        'Enter zone',
                        focusNode: focusNode,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter zone';
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
                  '500', 
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
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  decoration: InputDecoration(
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: ['Cash', 'Online', 'UPI'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _paymentMode = newValue!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select payment mode';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
            
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
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

                            final name = _nameController.text.trim();
                            final phone = _phoneController.text.trim();
                            final address = _addressController.text.trim();
                            final zone = _zoneController.text.trim();
                            final deposit = double.parse(_depositController.text.trim());
                            
                            showDialog(
                              context: context,
                              builder: (confirmContext) => AlertDialog(
                                title: const Text('Confirm Changes'),
                                content: Text('Are you sure you want to update the details for "$name"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(confirmContext),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      FocusScope.of(context).unfocus();
                                      FocusManager.instance.primaryFocus?.unfocus();
                                      setState(() {
                                        _isSubmitting = true;
                                      });
                                      Navigator.pop(confirmContext); // Close confirmation

                                      final updatedCustomer = Customer(
                                        id: widget.customer.id,
                                        agencyId: widget.customer.agencyId,
                                        salesmanId: _selectedSalesmanId ?? widget.customer.salesmanId, // Use new or old
                                        name: name,
                                        phone: phone,
                                        address: address,
                                        status: widget.customer.status,
                                        zone: zone,
                                        securityDeposit: deposit,
                                        paymentMode: _paymentMode!,
                                        bottleBalance:  widget.customer.bottleBalance,
                                        pendingBalance:  widget.customer.pendingBalance,
                                        isRefunded: widget.customer.isRefunded,
                                        createdAt: widget.customer.createdAt,
                                      );
                                      widget.customerBloc.add(UpdateCustomer(updatedCustomer));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[700],
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
                        child: const Text('Save Changes'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Cancel'),
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

  Widget _buildLabel(String text, {bool isMandatory = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
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
      ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller, 
    String hint, 
    {
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
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2962FF)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
