import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_event.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_state.dart';
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';

class EditCustomerDialog extends StatefulWidget {
  final Customer customer;
  final CustomerBloc customerBloc;

  const EditCustomerDialog({
    super.key,
    required this.customer,
    required this.customerBloc,
  });

  @override
  State<EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends State<EditCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _depositController;
  //late TextEditingController _balanceController;
  //late TextEditingController _bottleBalanceController;
  late String? _paymentMode;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _addressController = TextEditingController(text: widget.customer.address);
    _depositController = TextEditingController(text: widget.customer.securityDeposit.toStringAsFixed(0));
    //_balanceController = TextEditingController(text: widget.customer.pendingBalance.toStringAsFixed(0));
    //_bottleBalanceController = TextEditingController(text: widget.customer.bottleBalance.toString());
    _paymentMode = widget.customer.paymentMode; // Use from entity
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _depositController.dispose();
    //_balanceController.dispose();
    //_bottleBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerBloc, CustomerState>(
      bloc: widget.customerBloc,
      listener: (context, state) {
        if (_isSubmitting) {
          if (state.status == CustomerStatus.submitting) {
            HydroFlowLoader.show(context, message: 'Saving Changes...');
          } else if (state.status == CustomerStatus.failure || 
                     (state.status == CustomerStatus.success && state.successMessage != null)) {
            HydroFlowLoader.hide(context);
            if (state.status == CustomerStatus.success) {
              _isSubmitting = false;
              Navigator.of(context).pop(); // Close edit dialog
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
                _buildLabel('Customer Name', isMandatory: true),
                _buildTextFormField(
                  _nameController, 
                  'Enter name',
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
                _buildLabel('Security Deposit (₹)', isMandatory: true),
                _buildTextFormField(
                  _depositController, 
                  '500', 
                  keyboardType: TextInputType.number,
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
             // const SizedBox(height: 16),
             // _buildLabel('Pending Balance (₹)'),
             // _buildTextField(_balanceController, '100', keyboardType: TextInputType.number),
             // const SizedBox(height: 16),
             // _buildLabel('Bottle Balance'),
             // _buildTextField(_bottleBalanceController, '2', keyboardType: TextInputType.number),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final name = _nameController.text.trim();
                            final phone = _phoneController.text.trim();
                            final address = _addressController.text.trim();
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
                                    onPressed: () {
                                      setState(() {
                                        _isSubmitting = true;
                                      });
                                      Navigator.pop(confirmContext); // Close confirmation
                                      final updatedCustomer = Customer(
                                        id: widget.customer.id,
                                        salesmanId: widget.customer.salesmanId,
                                        name: name,
                                        phone: phone,
                                        address: address,
                                        status: widget.customer.status,
                                        securityDeposit: deposit,
                                        pendingBalance: widget.customer.pendingBalance,
                                        bottleBalance: widget.customer.bottleBalance,
                                        isRefunded: widget.customer.isRefunded,
                                        paymentMode: _paymentMode!,
                                        createdAt: widget.customer.createdAt,
                                      );
                                      widget.customerBloc.add(UpdateCustomer(updatedCustomer));
                                      // Navigator.pop(context); // Handled by listener
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
      String? Function(String?)? validator,
    }
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
