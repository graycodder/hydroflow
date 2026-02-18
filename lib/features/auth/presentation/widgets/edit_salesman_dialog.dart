import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';

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
  late TextEditingController _usernameController;
  final _passwordController = TextEditingController(); // Empty by default
  late TextEditingController _zoneController;
  late TextEditingController _quotaController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.salesman.name);
    _phoneController = TextEditingController(text: widget.salesman.phoneNumber);
    _usernameController = TextEditingController(text: widget.salesman.username);
    _zoneController = TextEditingController(text: widget.salesman.zone);
    _quotaController = TextEditingController(text: widget.salesman.maxCustomers.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _zoneController.dispose();
    _quotaController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final updatedSalesman = widget.salesman.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        zone: _zoneController.text.trim(),
        maxCustomers: int.tryParse(_quotaController.text) ?? widget.salesman.maxCustomers,
        password: _passwordController.text.trim().isNotEmpty 
            ? _passwordController.text.trim() 
            : widget.salesman.password, 
      );

      Navigator.pop(context, updatedSalesman);
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
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  helperText: 'Cannot be changed',
                  enabled: false, 
                  filled: true,
                ),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  helperText: 'Leave blank to keep current password',
                ),
                obscureText: true,
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Min 6 chars';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _zoneController,
                decoration: const InputDecoration(labelText: 'Zone (Optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quotaController,
                decoration: InputDecoration(
                  labelText: 'Customer Quota',
                  helperText: 'Max customers allowed for this salesman. Pool Limit: ${widget.maxAgencyCustomers}. Already used by others: $otherAllocated. Remaining: $remainingForThisUser',
                  helperMaxLines: 3,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final qty = int.tryParse(value);
                  if (qty == null) return 'Enter a valid number';
                  
                  if (qty > remainingForThisUser) {
                    return 'Exceeds Agency Limit ($remainingForThisUser remaining)';
                  }
                  return null;
                },
              ),
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
          onPressed: _submit,
          child: const Text('Update'),
        ),
      ],
    );
  }
}
