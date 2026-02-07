import 'package:flutter/material.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_event.dart';

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
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _depositController;
  //late TextEditingController _balanceController;
  //late TextEditingController _bottleBalanceController;
  //late String _paymentMode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _addressController = TextEditingController(text: widget.customer.address);
    _depositController = TextEditingController(text: widget.customer.securityDeposit.toStringAsFixed(0));
    //_balanceController = TextEditingController(text: widget.customer.pendingBalance.toStringAsFixed(0));
    //_bottleBalanceController = TextEditingController(text: widget.customer.bottleBalance.toString());
    //_paymentMode = 'Cash'; // Default or from entity if available
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
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
              _buildLabel('Customer Name'),
              _buildTextField(_nameController, 'Enter name'),
              const SizedBox(height: 16),
              _buildLabel('Phone Number'),
              _buildTextField(_phoneController, '+91 98765 43212', keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildLabel('Address'),
              _buildTextField(_addressController, 'Enter address'),
              const SizedBox(height: 16),
              _buildLabel('Security Deposit (₹)'),
              _buildTextField(_depositController, '500', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
            //_buildLabel('Payment Mode'),
            //Container(
            //  width: double.infinity,
            //  padding: const EdgeInsets.symmetric(horizontal: 12),
            //  decoration: BoxDecoration(
            //    color: Colors.grey[50],
            //    borderRadius: BorderRadius.circular(8),
            //    border: Border.all(color: Colors.grey.shade200),
            //  ),
            //  child: DropdownButtonHideUnderline(
            //    child: DropdownButton<String>(
            //      value: _paymentMode,
            //      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            //      items: ['Cash', 'Online', 'UPI'].map((String value) {
            //        return DropdownMenuItem<String>(
            //          value: value,
            //          child: Text(value),
            //        );
            //      }).toList(),
            //      onChanged: (newValue) {
            //        setState(() {
            //          _paymentMode = newValue!;
            //        });
            //      },
            //    ),
            //  ),
            //),
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
                        final updatedCustomer = Customer(
                          id: widget.customer.id,
                          salesmanId: widget.customer.salesmanId,
                          name: _nameController.text,
                          phone: _phoneController.text,
                          address: _addressController.text,
                          status: widget.customer.status,
                          securityDeposit: double.tryParse(_depositController.text) ?? 0.0,
                          pendingBalance: widget.customer.pendingBalance,
                          bottleBalance: widget.customer.bottleBalance,
                          isRefunded: widget.customer.isRefunded,
                        );
                        widget.customerBloc.add(UpdateCustomer(updatedCustomer));
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D1117),
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
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0D1117)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
