// lib/screens/events/host_event_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:kanairoxo/providers/events_provider.dart';
import 'package:kanairoxo/models/data_models.dart';

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
  final TextEditingController _shortDescriptionController =
      TextEditingController();
  final TextEditingController _venueNameController = TextEditingController();
  final TextEditingController _venueAddressController =
      TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();

  // Form values
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedStartTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _selectedEndTime = const TimeOfDay(hour: 21, minute: 0);
  String? _selectedCategory;
  String? _selectedMood;
  List<String> _selectedIntents = [];
  String _ticketDesignType = 'qr_code';
  bool _isPaidEvent = false;
  double? _latitude;
  double? _longitude;
  bool _isLoadingCategories = false;

  // Ticket design options
  final List<String> _ticketDesignTypes = [
    'qr_code',
    'letter',
    'digital',
    'minimal'
  ];
  final Map<String, String> _designTypeLabels = {
    'qr_code': 'QR Code Ticket',
    'letter': 'Invitation Letter',
    'digital': 'Digital Pass',
    'minimal': 'Minimal Ticket',
  };

  // Mood options
  final List<String> _moodOptions = [
    'energetic',
    'relaxed',
    'learning',
    'creative',
    'networking',
    'adventure',
  ];

  final Map<String, String> _moodLabels = {
    'energetic': 'Energetic & Social',
    'relaxed': 'Relaxed & Casual',
    'learning': 'Learning & Growth',
    'creative': 'Creative & Expressive',
    'networking': 'Networking & Professional',
    'adventure': 'Adventure & Exploration',
  };

  // Intent options
  final List<String> _intentOptions = [
    'friendships',
    'networking',
    'dating',
    'learning',
    'community',
    'entertainment',
  ];

  final Map<String, String> _intentLabels = {
    'friendships': 'Making Friends',
    'networking': 'Professional Networking',
    'dating': 'Romantic Connections',
    'learning': 'Skill Development',
    'community': 'Community Building',
    'entertainment': 'Entertainment & Fun',
  };

  // Form state
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });
    await _eventsProvider.fetchCategories();
    setState(() {
      _isLoadingCategories = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _selectedStartTime : _selectedEndTime,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
        } else {
          _selectedEndTime = picked;
        }
      });
    }
  }

  Widget _buildStaticMap() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Map Preview', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date & Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Date Selection
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(
                '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectDate(context),
            ),

            // Start Time
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Start Time'),
              subtitle: Text(_selectedStartTime.format(context)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectTime(context, true),
            ),

            // End Time
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('End Time'),
              subtitle: Text(_selectedEndTime.format(context)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectTime(context, false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStaticMap(),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'Enter latitude',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                _latitude = double.tryParse(value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: 'Enter longitude',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                _longitude = double.tryParse(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Free/Paid toggle
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Free Event'),
                    selected: !_isPaidEvent,
                    onSelected: (selected) {
                      setState(() {
                        _isPaidEvent = !selected;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Paid Event'),
                    selected: _isPaidEvent,
                    onSelected: (selected) {
                      setState(() {
                        _isPaidEvent = selected;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Price input (if paid)
            if (_isPaidEvent)
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (KES)',
                  hintText: 'Enter ticket price',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketDesignSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ticket Design',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Design type selection
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _ticketDesignTypes.map((type) {
                return ChoiceChip(
                  label: Text(_designTypeLabels[type] ?? type),
                  selected: _ticketDesignType == type,
                  onSelected: (selected) {
                    setState(() {
                      _ticketDesignType = type;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Design preview based on type
            if (_ticketDesignType == 'letter')
              _buildLetterDesignPreview()
            else if (_ticketDesignType == 'qr_code')
              _buildQRCodeDesignPreview()
            else
              _buildGenericDesignPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterDesignPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // KanairoXO Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.event,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re Invited!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join us for a special gathering',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Your name invites you to\n${_titleController.text.isNotEmpty ? _titleController.text : "Your Event Name"}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeDesignPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // QR Code Placeholder
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('QR Code', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan this QR code at the venue for check-in',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGenericDesignPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Text(
          '${_designTypeLabels[_ticketDesignType]} Design',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a mood'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Combine date and time
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedStartTime.hour,
        _selectedStartTime.minute,
      );

      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedEndTime.hour,
        _selectedEndTime.minute,
      );

      // Prepare event data
      final eventData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'short_description': _shortDescriptionController.text,
        'category': _selectedCategory!,
        'venue_name': _venueNameController.text,
        'venue_address': _venueAddressController.text,
        'latitude': _latitude,
        'longitude': _longitude,
        'start_datetime': startDateTime.toIso8601String(),
        'end_datetime': endDateTime.toIso8601String(),
        'max_capacity': int.parse(_capacityController.text),
        'pricing_tier': _isPaidEvent ? 'paid' : 'free',
        'base_price': _isPaidEvent ? double.parse(_priceController.text) : 0,
        'primary_mood': _selectedMood!,
        'target_intents': _selectedIntents,
        'ticket_design_type': _ticketDesignType,
        'visibility': 'public',
      };

      final result = await _eventsProvider.hostEvent(eventData);

      if (result['success']) {
        if (widget.onEventCreated != null) {
          widget.onEventCreated!(result['event']);
        }

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to create event'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error creating event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host an Event'),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _submitForm,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Event Title',
                          hintText: 'Enter event title',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter event title';
                          }
                          if (value.length < 5) {
                            return 'Title must be at least 5 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Short Description
                      TextFormField(
                        controller: _shortDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Short Description',
                          hintText: 'Brief description (max 200 characters)',
                          prefixIcon: Icon(Icons.short_text),
                        ),
                        maxLength: 200,
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a short description';
                          }
                          if (value.length < 20) {
                            return 'Description must be at least 20 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Full Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Full Description',
                          hintText: 'Describe your event in detail',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter event description';
                          }
                          if (value.length < 50) {
                            return 'Description must be at least 50 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Category
                      _isLoadingCategories
                          ? const Center(child: CircularProgressIndicator())
                          : Consumer<EventsProvider>(
                              builder: (context, provider, child) {
                                return DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  decoration: const InputDecoration(
                                    labelText: 'Category',
                                    prefixIcon: Icon(Icons.category),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: provider.categories.map((category) {
                                    return DropdownMenuItem(
                                      value: category.id,
                                      child: Text(category.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a category';
                                    }
                                    return null;
                                  },
                                );
                              },
                            ),

                      const SizedBox(height: 16),

                      // Mood
                      DropdownButtonFormField<String>(
                        value: _selectedMood,
                        decoration: const InputDecoration(
                          labelText: 'Mood',
                          prefixIcon: Icon(Icons.mood),
                          border: OutlineInputBorder(),
                        ),
                        items: _moodOptions.map((mood) {
                          return DropdownMenuItem(
                            value: mood,
                            child: Text(_moodLabels[mood]!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMood = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a mood';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Intents (Multi-select)
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Event Intents',
                          prefixIcon: Icon(Icons.tag),
                          border: OutlineInputBorder(),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _intentOptions.map((intent) {
                            final isSelected =
                                _selectedIntents.contains(intent);
                            return FilterChip(
                              label: Text(_intentLabels[intent]!),
                              selected: isSelected,
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
                      ),

                      const SizedBox(height: 16),

                      // Capacity
                      TextFormField(
                        controller: _capacityController,
                        decoration: const InputDecoration(
                          labelText: 'Maximum Capacity',
                          hintText: 'Enter maximum number of attendees',
                          prefixIcon: Icon(Icons.group),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter capacity';
                          }
                          final capacity = int.tryParse(value);
                          if (capacity == null || capacity < 2) {
                            return 'Capacity must be at least 2';
                          }
                          if (capacity > 1000) {
                            return 'Maximum capacity is 1000';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Date & Time Section
              _buildDateTimeSection(),

              const SizedBox(height: 16),

              // Location Section
              _buildLocationSection(),

              const SizedBox(height: 16),

              // Venue Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Venue Details',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Venue Name
                      TextFormField(
                        controller: _venueNameController,
                        decoration: const InputDecoration(
                          labelText: 'Venue Name',
                          hintText: 'Enter venue name',
                          prefixIcon: Icon(Icons.place),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter venue name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Venue Address
                      TextFormField(
                        controller: _venueAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Venue Address',
                          hintText: 'Enter full address',
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter venue address';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Pricing Section
              _buildPricingSection(),

              const SizedBox(height: 16),

              // Ticket Design Section
              _buildTicketDesignSection(),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 12),
                            Text('Creating Event...'),
                          ],
                        )
                      : const Text('Create Event'),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}