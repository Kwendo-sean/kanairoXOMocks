import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kanairoxo/providers/events_provider.dart';
import 'package:kanairoxo/models/data_models.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/services/api_client.dart';

class HostEventScreen extends StatefulWidget {
  final Function(Experience)? onEventCreated;

  const HostEventScreen({super.key, this.onEventCreated});

  @override
  State<HostEventScreen> createState() => _HostEventScreenState();
}

class _HostEventScreenState extends State<HostEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient apiClient = ApiClient();
  
  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _shortDescriptionController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _moodController = TextEditingController();
  
  // Suggestions state
  List<String> _categorySuggestions = [];
  List<String> _moodSuggestions = [];
  List<String> _intentSuggestions = [];
  bool _showCategorySuggestions = false;
  bool _showMoodSuggestions = false;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedStartTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _selectedEndTime = const TimeOfDay(hour: 21, minute: 0);

  final List<String> _selectedIntents = [];
  bool _isPaidEvent = false;
  bool _isSubmitting = false;
  
  String _ticketType = 'qr'; // qr, letter, photo
  String _fontChoice = 'classic'; // classic, calligraphy, modern
  File? _ticketPhotoFile;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      final response = await apiClient.get('api/v1/events/suggestions/');
      if (mounted) {
        setState(() {
          _categorySuggestions = List<String>.from(response['category_suggestions'] ?? []);
          _moodSuggestions = List<String>.from(response['mood_suggestions'] ?? []);
          _intentSuggestions = List<String>.from(response['intent_suggestions'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categorySuggestions = [
            'Music', 'Art & Culture', 'Food & Drink',
            'Sports & Fitness', 'Networking', 'Education',
            'Wellness', 'Comedy', 'Fashion', 'Tech',
            'Photography', 'Dance', 'Community', 'Outdoors'
          ];
          _moodSuggestions = ['Energetic', 'Relaxed', 'Learning', 'Creative', 'Networking', 'Adventure'];
          _intentSuggestions = ['Friendships', 'Networking', 'Dating', 'Learning', 'Community', 'Entertainment'];
        });
      }
    }
  }

  Future<void> _pickTicketPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _ticketPhotoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    );
    if (picked != null) {
      setState(() {
        _selectedStartTime = picked;
        _selectedEndTime = TimeOfDay(hour: (picked.hour + 3) % 24, minute: picked.minute);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);

    try {
      final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedStartTime.hour, _selectedStartTime.minute);
      final end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedEndTime.hour, _selectedEndTime.minute);

      final eventData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'short_description': _shortDescriptionController.text,
        'category': _categoryController.text,
        'venue_name': _venueController.text,
        'neighborhood': _neighborhoodController.text,
        'address_details': _addressController.text,
        'start_datetime': start.toIso8601String(),
        'end_datetime': end.toIso8601String(),
        'max_capacity': int.tryParse(_capacityController.text) ?? 0,
        'pricing_tier': _isPaidEvent ? 'paid' : 'free',
        'base_price': _isPaidEvent ? double.tryParse(_priceController.text) ?? 0 : 0,
        'primary_mood': _moodController.text,
        'target_intents': _selectedIntents,
        'ticket_type': _ticketType,
        'letter_font': _ticketType == 'letter' ? _fontChoice : null,
      };

      final provider = Provider.of<EventsProvider>(context, listen: false);
      final result = await provider.hostEvent(eventData);

      if (result['success']) {
        if (widget.onEventCreated != null) widget.onEventCreated!(result['event']);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event created successfully'), backgroundColor: Colors.green)
          );
        }
      } else {
        throw Exception(result['error'] ?? 'Failed to create event');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAF7F4);
    final surfaceColor = isDark ? const Color(0xFF1C1612) : Colors.white;
    final textColor = isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A1A1A);
    final mutedColor = isDark ? const Color(0xFF9A8F85) : const Color(0xFFA0A0A0);
    final borderColor = isDark ? const Color(0xFF2E2820) : Colors.grey.shade200;
    final primaryColor = isDark ? const Color(0xFFC0394B) : const Color(0xFF8B1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context)),
        title: Text('Host an Experience', style: AppTypography.screenTitle.copyWith(color: textColor)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Basic Info', textColor: textColor),
              const SizedBox(height: 6),
              _StyledTextField(controller: _titleController, hint: 'Event Title', surfaceColor: surfaceColor, borderColor: borderColor, textColor: textColor, mutedColor: mutedColor, primaryColor: primaryColor),
              const SizedBox(height: 10),
              _StyledTextField(controller: _shortDescriptionController, hint: 'Short Description', maxLines: 2, surfaceColor: surfaceColor, borderColor: borderColor, textColor: textColor, mutedColor: mutedColor, primaryColor: primaryColor),
              const SizedBox(height: 10),
              _StyledTextField(controller: _descriptionController, hint: 'Full Description', maxLines: 4, surfaceColor: surfaceColor, borderColor: borderColor, textColor: textColor, mutedColor: mutedColor, primaryColor: primaryColor),
              
              _SectionHeader(title: 'Category & Mood', textColor: textColor),
              const SizedBox(height: 6),
              _buildCategoryField(surfaceColor, borderColor, textColor, mutedColor, primaryColor),
              const SizedBox(height: 10),
              _buildMoodField(surfaceColor, borderColor, textColor, mutedColor, primaryColor),
              
              _SectionHeader(title: 'Location', textColor: textColor),
              const SizedBox(height: 6),
              _StyledTextField(
                controller: _venueController,
                hint: 'Venue name (e.g. GTC Mall, Alchemist)',
                prefixIcon: Icons.location_on_outlined,
                surfaceColor: surfaceColor, borderColor: borderColor, textColor: textColor, mutedColor: mutedColor, primaryColor: primaryColor),
              const SizedBox(height: 10),
              _StyledTextField(
                controller: _neighborhoodController,
                hint: 'Neighborhood (e.g. Westlands, Karen)',
                prefixIcon: Icons.map_outlined,
                surfaceColor: surfaceColor, borderColor: borderColor, textColor: textColor, mutedColor: mutedColor, primaryColor: primaryColor),
              const SizedBox(height: 10),
              _StyledTextField(
                controller: _addressController,
                hint: 'Address details — optional',
                prefixIcon: Icons.info_outline,
                surfaceColor: surfaceColor, borderColor: borderColor, textColor: textColor, mutedColor: mutedColor, primaryColor: primaryColor),
              
              _SectionHeader(title: 'Logistics', textColor: textColor),
              const SizedBox(height: 6),
              _StyledTextField(controller: _capacityController, hint: 'Capacity', keyboardType: TextInputType.number, surfaceColor: surfaceColor, borderColor: borderColor, textColor: textColor, mutedColor: mutedColor, primaryColor: primaryColor),
              const SizedBox(height: 10),
              _buildDatePickerDisplay(surfaceColor, borderColor, textColor, mutedColor, primaryColor),
              
              _SectionHeader(title: 'Intents', textColor: textColor),
              const SizedBox(height: 6),
              _buildIntentsField(surfaceColor, borderColor, textColor, primaryColor),

              _SectionHeader(title: 'Pricing', textColor: textColor),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Paid Event', style: AppTypography.bodyMedium.copyWith(color: textColor)),
                        Switch(
                          value: _isPaidEvent,
                          onChanged: (val) => setState(() => _isPaidEvent = val),
                          activeColor: primaryColor,
                        ),
                      ],
                    ),
                    if (_isPaidEvent)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _StyledTextField(
                          controller: _priceController,
                          hint: 'Ticket Price (KES)',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.payments_outlined,
                          surfaceColor: surfaceColor, borderColor: borderColor, textColor: textColor, mutedColor: mutedColor, primaryColor: primaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              _SectionHeader(title: 'Ticket Design', textColor: textColor),
              const SizedBox(height: 6),
              Text(
                'Choose how your attendees receive their tickets',
                style: AppTypography.caption.copyWith(color: mutedColor)),
              const SizedBox(height: 12),

              _TicketTypeCard(
                type: 'qr',
                title: 'QR Code',
                subtitle: 'Scannable QR at the venue',
                icon: Icons.qr_code_outlined,
                isSelected: _ticketType == 'qr',
                onTap: () => setState(() => _ticketType = 'qr'),
                primaryColor: primaryColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: textColor, mutedColor: mutedColor),
              
              const SizedBox(height: 8),
              
              _TicketTypeCard(
                type: 'letter',
                title: 'Invitation Letter',
                subtitle: 'Personalised letter generated by KanairoXO',
                icon: Icons.mail_outline,
                isSelected: _ticketType == 'letter',
                onTap: () => setState(() => _ticketType = 'letter'),
                primaryColor: primaryColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: textColor, mutedColor: mutedColor),
              
              const SizedBox(height: 8),
              
              _TicketTypeCard(
                type: 'photo',
                title: 'Custom Photo',
                subtitle: 'Upload your own ticket design',
                icon: Icons.image_outlined,
                isSelected: _ticketType == 'photo',
                onTap: () => setState(() => _ticketType = 'photo'),
                primaryColor: primaryColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: textColor, mutedColor: mutedColor),
              
              if (_ticketType == 'letter') ...[
                const SizedBox(height: 16),
                Text('Letter Font',
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 8),
                Row(children: [
                  _FontOption(
                    fontKey: 'classic',
                    label: 'Classic',
                    preview: 'Abc',
                    fontStyle: FontStyle.normal,
                    isSelected: _fontChoice == 'classic',
                    onTap: () => setState(() => _fontChoice = 'classic'),
                    primaryColor: primaryColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: textColor, mutedColor: mutedColor),
                  const SizedBox(width: 8),
                  _FontOption(
                    fontKey: 'calligraphy',
                    label: 'Calligraphy',
                    preview: 'Abc',
                    fontStyle: FontStyle.italic,
                    isSelected: _fontChoice == 'calligraphy',
                    onTap: () => setState(() => _fontChoice = 'calligraphy'),
                    primaryColor: primaryColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: textColor, mutedColor: mutedColor),
                  const SizedBox(width: 8),
                  _FontOption(
                    fontKey: 'modern',
                    label: 'Modern',
                    preview: 'Abc',
                    fontStyle: FontStyle.normal,
                    isSelected: _fontChoice == 'modern',
                    onTap: () => setState(() => _fontChoice = 'modern'),
                    primaryColor: primaryColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: textColor, mutedColor: mutedColor),
                ]),
              ],
              
              if (_ticketType == 'photo') ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickTicketPhoto,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.2),
                        style: BorderStyle.solid)),
                    child: _ticketPhotoFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_ticketPhotoFile!, fit: BoxFit.cover))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_outlined, color: primaryColor, size: 32),
                            const SizedBox(height: 8),
                            Text('Upload ticket design',
                              style: AppTypography.labelMedium.copyWith(color: primaryColor)),
                          ])))
              ],
              
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

  Widget _buildCategoryField(Color surfaceColor, Color borderColor, Color textColor, Color mutedColor, Color primaryColor) {
    return Column(children: [
      TextField(
        controller: _categoryController,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: 'Event category',
          prefixIcon: Icon(Icons.category_outlined, size: 18, color: mutedColor),
          helperText: 'e.g. Music, Art, Networking, Food & Drink, Sports',
          helperStyle: AppTypography.caption.copyWith(color: mutedColor),
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
          hintStyle: TextStyle(color: mutedColor),
        ),
        onChanged: (val) {
          setState(() => _showCategorySuggestions = val.isNotEmpty);
        }),
      if (_showCategorySuggestions)
        Container(
          height: 40,
          margin: const EdgeInsets.only(top: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: _categorySuggestions.where((s) => s.toLowerCase().contains(_categoryController.text.toLowerCase())).length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (ctx, i) {
              final filtered = _categorySuggestions.where((s) => s.toLowerCase().contains(_categoryController.text.toLowerCase())).toList();
              final suggestion = filtered[i];
              return GestureDetector(
                onTap: () {
                  _categoryController.text = suggestion;
                  setState(() => _showCategorySuggestions = false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: primaryColor.withOpacity(0.2))),
                  child: Text(suggestion, style: AppTypography.caption.copyWith(color: primaryColor))));
            }))
    ]);
  }

  Widget _buildMoodField(Color surfaceColor, Color borderColor, Color textColor, Color mutedColor, Color primaryColor) {
    return Column(children: [
      TextField(
        controller: _moodController,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: 'Event mood',
          prefixIcon: Icon(Icons.mood_outlined, size: 18, color: mutedColor),
          helperText: 'e.g. Energetic, Relaxed, Creative',
          helperStyle: AppTypography.caption.copyWith(color: mutedColor),
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
          hintStyle: TextStyle(color: mutedColor),
        ),
        onChanged: (val) {
          setState(() => _showMoodSuggestions = val.isNotEmpty);
        }),
      if (_showMoodSuggestions)
        Container(
          height: 40,
          margin: const EdgeInsets.only(top: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: _moodSuggestions.where((s) => s.toLowerCase().contains(_moodController.text.toLowerCase())).length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (ctx, i) {
              final filtered = _moodSuggestions.where((s) => s.toLowerCase().contains(_moodController.text.toLowerCase())).toList();
              final suggestion = filtered[i];
              return GestureDetector(
                onTap: () {
                  _moodController.text = suggestion;
                  setState(() => _showMoodSuggestions = false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: primaryColor.withOpacity(0.2))),
                  child: Text(suggestion, style: AppTypography.caption.copyWith(color: primaryColor))));
            }))
    ]);
  }

  Widget _buildIntentsField(Color surfaceColor, Color borderColor, Color textColor, Color primaryColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _intentSuggestions.map((intent) {
        final isSelected = _selectedIntents.contains(intent);
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              _selectedIntents.remove(intent);
            } else {
              _selectedIntents.add(intent);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : surfaceColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: isSelected ? primaryColor : borderColor)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(intent,
                  style: AppTypography.caption.copyWith(color: isSelected ? Colors.white : textColor))])));
      }).toList());
  }

  Widget _buildDatePickerDisplay(Color surfaceColor, Color borderColor, Color textColor, Color mutedColor, Color primaryColor) {
    return GestureDetector(
      onTap: () => _pickDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1)),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 16, color: primaryColor),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: AppTypography.bodyMedium.copyWith(color: textColor)),
              const SizedBox(height: 2),
              Text('Starts at ${_selectedStartTime.format(context)}', style: AppTypography.caption.copyWith(color: mutedColor)),
            ]),
          const Spacer(),
          Icon(Icons.chevron_right, size: 16, color: mutedColor),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color textColor;
  const _SectionHeader({required this.title, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(title, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;
  final Color primaryColor;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixIcon,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTypography.bodyMedium.copyWith(color: textColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: surfaceColor,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: mutedColor) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
        hintStyle: AppTypography.bodyMedium.copyWith(color: mutedColor),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}

class _TicketTypeCard extends StatelessWidget {
  final String type;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;

  const _TicketTypeCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.15) : surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : borderColor,
            width: isSelected ? 1.5 : 1)),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252018) : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: isSelected ? Colors.white : mutedColor)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: isSelected ? primaryColor : textColor)),
              Text(subtitle, style: AppTypography.caption.copyWith(color: mutedColor)),
            ])),
          if (isSelected) Icon(Icons.check_circle, color: primaryColor, size: 20),
        ])),
    );
  }
}

class _FontOption extends StatelessWidget {
  final String fontKey;
  final String label;
  final String preview;
  final FontStyle fontStyle;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;

  const _FontOption({
    required this.fontKey,
    required this.label,
    required this.preview,
    required this.fontStyle,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? primaryColor : borderColor)),
        child: Column(
          children: [
            Text(preview,
              style: TextStyle(
                fontSize: 18,
                fontStyle: fontStyle,
                color: isSelected ? Colors.white : textColor,
                fontFamily: fontKey == 'modern' ? 'DM Sans' : null)),
            const SizedBox(height: 4),
            Text(label,
              style: AppTypography.caption.copyWith(color: isSelected ? Colors.white.withOpacity(0.8) : mutedColor)),
          ]))));
  }
}
