import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/providers/events_provider.dart';
import 'package:kanairoxo/models/data_models.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/widgets/glass_card.dart';

class HostEventScreen extends StatefulWidget {
  final Function(Experience)? onEventCreated;

  const HostEventScreen({super.key, this.onEventCreated});

  @override
  State<HostEventScreen> createState() => _HostEventScreenState();
}

class _HostEventScreenState extends State<HostEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late EventsProvider _eventsProvider;

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _shortDescriptionController = TextEditingController();
  final TextEditingController _venueNameController = TextEditingController();
  final TextEditingController _venueAddressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  // Declare with default values at top of state class
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedStartTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _selectedEndTime = const TimeOfDay(hour: 21, minute: 0);

  String? _selectedCategory;
  String? _selectedMood;
  final List<String> _selectedIntents = [];
  bool _isPaidEvent = false;
  bool _isLoadingCategories = false;
  bool _isSubmitting = false;

  final List<String> _moodOptions = ['energetic', 'relaxed', 'learning', 'creative', 'networking', 'adventure'];
  final List<String> _intentOptions = ['friendships', 'networking', 'dating', 'learning', 'community', 'entertainment'];

  @override
  void initState() {
    super.initState();
    _eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    await _eventsProvider.fetchCategories();
    if (mounted) {
      setState(() {
        _isLoadingCategories = false;
        // Pre-select first category if available
        if (_eventsProvider.categories.isNotEmpty) {
          _selectedCategory = _eventsProvider.categories.first.id;
        }
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.textPrimary)),
        child: child!),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      if (mounted) _pickStartTime(context);
    }
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary)),
        child: child!),
    );
    if (picked != null) {
      setState(() {
        _selectedStartTime = picked;
        // Automatically set end time to 3 hours later
        _selectedEndTime = TimeOfDay(hour: (picked.hour + 3) % 24, minute: picked.minute);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category and Mood are required')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedStartTime.hour, _selectedStartTime.minute);
      final end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedEndTime.hour, _selectedEndTime.minute);

      final eventData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'short_description': _shortDescriptionController.text,
        'category': _selectedCategory!,
        'venue_name': _venueNameController.text,
        'venue_address': _venueAddressController.text,
        'latitude': double.tryParse(_latController.text) ?? 0.0,
        'longitude': double.tryParse(_lngController.text) ?? 0.0,
        'start_datetime': start.toIso8601String(),
        'end_datetime': end.toIso8601String(),
        'max_capacity': int.parse(_capacityController.text),
        'pricing_tier': _isPaidEvent ? 'paid' : 'free',
        'base_price': _isPaidEvent ? double.parse(_priceController.text) : 0,
        'primary_mood': _selectedMood!,
        'target_intents': _selectedIntents,
        'visibility': 'public',
      };

      final result = await _eventsProvider.hostEvent(eventData);

      if (result['success']) {
        if (widget.onEventCreated != null) widget.onEventCreated!(result['event']);
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event created successfully!'), backgroundColor: Colors.green));
        }
      } else {
        throw Exception(result['error'] ?? 'Failed to create event');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A), size: 22),
          onPressed: () => Navigator.pop(context)),
        title: Text('Host an Event', style: AppTypography.screenTitle),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Basic Info'),
              const SizedBox(height: 6),
              _buildTextField(_titleController, 'Event Title'),
              const SizedBox(height: 10),
              _buildTextField(_shortDescriptionController, 'Short Description', maxLines: 2),
              const SizedBox(height: 10),
              _buildTextField(_descriptionController, 'Full Description', maxLines: 4),
              
              _buildSectionHeader('Category & Mood'),
              const SizedBox(height: 6),
              if (_isLoadingCategories) 
                const Center(child: CircularProgressIndicator()) 
              else 
                _buildCategoryDropdown(),
              const SizedBox(height: 10),
              _buildMoodDropdown(),
              
              _buildSectionHeader('Logistics'),
              const SizedBox(height: 6),
              _buildTextField(_venueNameController, 'Venue Name'),
              const SizedBox(height: 10),
              _buildTextField(_venueAddressController, 'Venue Address', maxLines: 2),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildTextField(_latController, 'Latitude', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_lngController, 'Longitude', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                ],
              ),
              const SizedBox(height: 10),
              _buildTextField(_capacityController, 'Capacity', keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _buildDatePickerDisplay(),
              
              _buildSectionHeader('Intents'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 0,
                children: _intentOptions.map((intent) {
                  final isSelected = _selectedIntents.contains(intent);
                  return FilterChip(
                    label: Text(intent, style: AppTypography.caption.copyWith(color: isSelected ? Colors.white : AppColors.textPrimary)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedIntents.add(intent);
                        } else {
                          _selectedIntents.remove(intent);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              _buildSectionHeader('Pricing'),
              const SizedBox(height: 6),
              GlassCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Paid Event', style: AppTypography.bodyMedium),
                        Switch(
                          value: _isPaidEvent,
                          onChanged: (val) => setState(() => _isPaidEvent = val),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                    if (_isPaidEvent)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          style: AppTypography.bodyMedium,
                          decoration: _inputDecoration('Ticket Price (KES)').copyWith(
                            prefixText: 'KES ',
                            prefixStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: LiquidGlassButton(
                  size: LiquidButtonSize.xl,
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Text('Create Event', style: AppTypography.buttonText)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(title, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTypography.bodyMedium,
      decoration: _inputDecoration(hint),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildCategoryDropdown() {
    return Consumer<EventsProvider>(
      builder: (context, provider, child) {
        final isValid = provider.categories.any((c) => c.id == _selectedCategory);
        if (!isValid && provider.categories.isNotEmpty) {
          _selectedCategory = provider.categories.first.id;
        }

        return DropdownButtonFormField<String>(
          value: _selectedCategory,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
          decoration: _inputDecoration('Category'),
          items: provider.categories.map((c) => DropdownMenuItem(
            value: c.id, 
            child: Text(c.name, style: AppTypography.bodyMedium)
          )).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v),
          validator: (v) => v == null ? 'Required' : null,
        );
      },
    );
  }

  Widget _buildMoodDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedMood,
      icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
      decoration: _inputDecoration('Mood'),
      items: _moodOptions.map((m) => DropdownMenuItem(value: m, child: Text(m, style: AppTypography.bodyMedium))).toList(),
      onChanged: (v) => setState(() => _selectedMood = v),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildDatePickerDisplay() {
    return GestureDetector(
      onTap: () => _pickDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1)),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: AppTypography.bodyMedium),
              const SizedBox(height: 2),
              Text(
                'Starts at ${_selectedStartTime.format(context)}',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            ]),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}
