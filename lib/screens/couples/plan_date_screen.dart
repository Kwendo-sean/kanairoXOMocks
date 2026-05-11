import 'package:flutter/material.dart';
import 'package:kanairoxo/services/date_service.dart';

class PlanDateScreen extends StatefulWidget {
  const PlanDateScreen({super.key});

  @override
  State<PlanDateScreen> createState() => _PlanDateScreenState();
}

class _PlanDateScreenState extends State<PlanDateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan a Date'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text('Date: ${_selectedDate.toLocal()}'.split(' ')[0]),
                  ),
                  TextButton(
                    onPressed: () async {
                      final newDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (newDate != null) {
                        setState(() {
                          _selectedDate = newDate;
                        });
                      }
                    },
                    child: const Text('Select Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    DateService().addDateIdea({
                      'title': _titleController.text,
                      'date': _selectedDate.toIso8601String(),
                      'location': _locationController.text,
                      'description': _descriptionController.text,
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Plan Date'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
