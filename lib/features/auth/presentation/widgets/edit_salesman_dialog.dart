import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';
import 'package:hydroflow/features/auth/domain/repositories/agency_repository.dart';
import 'package:hydroflow/core/service_locator.dart' as di;
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';

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
 // late TextEditingController _zoneController;
  late TextEditingController _quotaController;
  bool _isChecking = false;
  bool _isPasswordVisible = false;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.salesman.name);
    _phoneController = TextEditingController(text: widget.salesman.phoneNumber);
    _phoneController.addListener(_onPhoneChanged);
   // _usernameController = TextEditingController(text: widget.salesman.username);
   // _zoneController = TextEditingController(text: widget.salesman.zone);
    _passwordController = TextEditingController(text: widget.salesman.password);
    _quotaController = TextEditingController(text: widget.salesman.maxCustomers.toString());
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
  //.dispose();
    _quotaController.dispose();
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
      HydroFlowLoader.show(context, message: 'Checking phone number...');

      try {
        final repo = di.sl<AgencyRepository>();
        final phone = _phoneController.text.trim();
        final isUnique = await repo.isPhoneNumberUnique(phone, excludeSalesmanId: widget.salesman.id);

        if (!mounted) return;
        HydroFlowLoader.hide(context);

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
          zone: "",
          maxCustomers: int.tryParse(_quotaController.text) ?? widget.salesman.maxCustomers,
          password: _passwordController.text.trim().isNotEmpty 
              ? _passwordController.text.trim() 
              : widget.salesman.password, 
        );

        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.pop(context, updatedSalesman);
      } catch (e) {
        if (mounted) {
          HydroFlowLoader.hide(context);
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
              // const SizedBox(height: 12),
              // TextFormField(
              //   controller: _zoneController,
              //   inputFormatters: [
              //     FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
              //   ],
              //   decoration: const InputDecoration(labelText: 'Zone (Optional)'),
              // ),
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
                  if (value == null || value.isEmpty) return 'Please enter quota';
                  final qty = int.tryParse(value);
                  if (qty == null || qty < 0) return 'Enter a valid number';
                  
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
          onPressed: _isChecking ? null : _submit,
          child: _isChecking 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Update'),
        ),
      ],
    );
  }
}
