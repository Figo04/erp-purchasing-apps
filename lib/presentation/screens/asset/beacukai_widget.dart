import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Reusable widget untuk input Beacukai
/// Digunakan di form IN, OUT, dan Disposed
class BeacukaiInputFields extends StatelessWidget {
  final TextEditingController beacukaiDocController;
  final TextEditingController beacukaiNoController;
  final TextEditingController beacukaiNoAjuController;
  final DateTime? selectedBeacukaiDate;
  final Function(DateTime?) onDateChanged;
  final bool isRequired;

  const BeacukaiInputFields({
    super.key,
    required this.beacukaiDocController,
    required this.beacukaiNoController,
    required this.beacukaiNoAjuController,
    required this.selectedBeacukaiDate,
    required this.onDateChanged,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Beacukai Doc Type
        TextFormField(
          controller: beacukaiDocController,
          decoration: InputDecoration(
            labelText: 'Beacukai Document Type ${isRequired ? '*' : ''}',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.description),
            hintText: 'e.g., BC 2.3, BC 4.0',
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Beacukai document is required';
                  }
                  return null;
                }
              : null,
        ),
        const SizedBox(height: 16),

        // Beacukai Date
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Beacukai Date ${isRequired ? '*' : ''}',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.calendar_today),
              suffixIcon: selectedBeacukaiDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => onDateChanged(null),
                    )
                  : null,
            ),
            child: Text(
              selectedBeacukaiDate != null
                  ? DateFormat('dd MMM yyyy').format(selectedBeacukaiDate!)
                  : 'Select date',
              style: TextStyle(
                color: selectedBeacukaiDate != null
                    ? Colors.black
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ),
        if (isRequired && selectedBeacukaiDate == null)
          const Padding(
            padding: EdgeInsets.only(left: 12, top: 8),
            child: Text(
              'Beacukai date is required',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),

        // Beacukai No
        TextFormField(
          controller: beacukaiNoController,
          decoration: InputDecoration(
            labelText: 'Beacukai Number ${isRequired ? '*' : ''}',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.confirmation_number),
            hintText: 'e.g., 123456-2024-001',
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Beacukai number is required';
                  }
                  return null;
                }
              : null,
        ),
        const SizedBox(height: 16),

        // Beacukai No Aju (Optional)
        TextFormField(
          controller: beacukaiNoAjuController,
          decoration: const InputDecoration(
            labelText: 'Beacukai No. Aju (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.request_page),
            hintText: 'Nomor pengajuan',
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedBeacukaiDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDateChanged(picked);
    }
  }
}