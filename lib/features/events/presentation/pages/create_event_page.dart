import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:snginepro/features/events/application/bloc/events_bloc.dart';
import 'package:snginepro/features/events/application/bloc/events_events.dart';
import 'package:snginepro/features/events/application/bloc/events_states.dart';
import 'package:snginepro/features/events/data/models/event.dart';
import 'package:snginepro/features/events/data/models/event_category.dart';
import 'package:snginepro/features/events/data/services/events_service.dart';
import 'package:snginepro/core/models/country.dart';
import 'package:snginepro/core/models/language.dart';
import 'package:snginepro/core/services/general_data_service.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:intl/intl.dart';

class CreateEventPage extends StatefulWidget {
  final Event? event; // Optional: for editing existing event

  const CreateEventPage({super.key, this.event});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _privacy = 'public';
  bool _isOnline = false;
  
  // Dropdowns data
  List<EventCategory> _categories = [];
  List<Country> _countries = [];
  List<Language> _languages = [];
  
  EventCategory? _selectedCategory;
  Country? _selectedCountry;
  Language? _selectedLanguage;
  
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final apiClient = context.read<ApiClient>();
      final eventsService = EventsService(apiClient);
      final generalDataService = GeneralDataService(apiClient);

      final results = await Future.wait([
        eventsService.getEventCategories(),
        generalDataService.getCountries(),
        generalDataService.getLanguages(),
      ]);

      setState(() {
        _categories = results[0] as List<EventCategory>;
        _countries = results[1] as List<Country>;
        _languages = results[2] as List<Language>;

        if (_languages.isNotEmpty) {

        }
        if (_countries.isNotEmpty) {

        }
        
        // Set defaults first
        if (_categories.isNotEmpty) _selectedCategory = _categories.first;
        if (_countries.isNotEmpty) _selectedCountry = _countries.first;
        if (_languages.isNotEmpty) _selectedLanguage = _languages.first;

        _isLoadingData = false;
        
        // Load event data after dropdown data is loaded
        if (widget.event != null) {
          _loadEventData();
        }
      });
    } catch (e) {

      setState(() => _isLoadingData = false);
    }
  }

  void _loadEventData() {
    final event = widget.event!;
    _titleController.text = event.eventTitle;
    _locationController.text = event.eventLocation ?? '';
    _descriptionController.text = event.eventDescription ?? '';
    _startDate = event.eventStartDate;
    _endDate = event.eventEndDate;
    _privacy = event.eventPrivacy;
    _isOnline = event.eventIsOnline;
    
    // Set selected category if available
    if (event.categoryId != null && _categories.isNotEmpty) {
      _selectedCategory = _categories.firstWhereOrNull(
        (c) => c.categoryId == event.categoryId,
      ) ?? _selectedCategory;
    }
    
    // Set selected country if available
    if (event.countryId != null && _countries.isNotEmpty) {
      _selectedCountry = _countries.firstWhereOrNull(
        (c) => c.countryId == event.countryId,
      ) ?? _selectedCountry;
    }
    
    // Set selected language if available
    if (event.languageId != null && _languages.isNotEmpty) {
      _selectedLanguage = _languages.firstWhereOrNull(
        (l) => l.languageId == event.languageId,
      ) ?? _selectedLanguage;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final theme = Get.theme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.event == null ? 'create_event'.tr : 'edit_event'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocListener<EventsBloc, EventsState>(
        listener: (context, state) {
          if (state is EventCreated || state is EventUpdated) {
            setState(() {
              _isLoading = false;
            });
            Get.snackbar(
              'success'.tr,
              state is EventCreated
                  ? state.message
                  : (state as EventUpdated).message,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            Navigator.pop(context, true); // Return true to refresh list
          } else if (state is EventsError) {
            setState(() {
              _isLoading = false;
            });
            Get.snackbar(
              'error'.tr,
              state.message,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          } else if (state is EventsLoading) {
            setState(() {
              _isLoading = true;
            });
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Event Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'event_title'.tr,
                  hintText: 'Enter event title',
                  prefixIcon: const Icon(Iconsax.edit),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'event_name_required'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Event Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'event_location'.tr,
                  hintText: 'Enter event location',
                  prefixIcon: const Icon(Iconsax.location),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                ),
                validator: (value) {
                  if (!_isOnline && (value == null || value.isEmpty)) {
                    return 'event_location_required'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Event Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'event_description'.tr,
                  hintText: 'Enter event description',
                  prefixIcon: const Icon(Iconsax.document_text),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),

              // Loading indicator or dropdowns
              if (_isLoadingData)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                // Category Dropdown
                if (_categories.isNotEmpty)
                  DropdownButtonFormField<EventCategory>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'category'.tr,
                      prefixIcon: const Icon(Iconsax.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.categoryName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                  ),
                const SizedBox(height: 16),

                // Country Dropdown
                if (_countries.isNotEmpty)
                  DropdownButtonFormField<Country>(
                    value: _selectedCountry,
                    decoration: InputDecoration(
                      labelText: 'country'.tr,
                      prefixIcon: const Icon(Iconsax.global),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                    ),
                    items: _countries.map((country) {
                      return DropdownMenuItem(
                        value: country,
                        child: Text(country.countryName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCountry = value);
                    },
                  ),
                const SizedBox(height: 16),

                // Language Dropdown
                if (_languages.isNotEmpty)
                  DropdownButtonFormField<Language>(
                    value: _selectedLanguage,
                    decoration: InputDecoration(
                      labelText: 'language'.tr,
                      prefixIcon: const Icon(Iconsax.translate),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                    ),
                    items: _languages.map((language) {
                      return DropdownMenuItem(
                        value: language,
                        child: Text(language.languageName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedLanguage = value);
                    },
                  ),
              ],
              const SizedBox(height: 16),

              // Start Date
              _buildDateField(
                label: 'start_date'.tr,
                value: _startDate,
                onTap: () => _selectDateTime(isStart: true),
              ),
              const SizedBox(height: 16),

              // End Date
              _buildDateField(
                label: 'end_date'.tr,
                value: _endDate,
                onTap: () => _selectDateTime(isStart: false),
              ),
              const SizedBox(height: 16),

              // Online Event Toggle
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text('online_event'.tr),
                  subtitle: Text('this_event_held_online'.tr),
                  value: _isOnline,
                  onChanged: (value) {
                    setState(() {
                      _isOnline = value;
                    });
                  },
                  secondary: Icon(
                    _isOnline ? Iconsax.video : Iconsax.people,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Privacy Selector
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.shield_tick,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'event_privacy'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<String>(
                      title: Text('privacy_public'.tr),
                      subtitle: Text('everyone_can_see'.tr),
                      value: 'public',
                      groupValue: _privacy,
                      onChanged: (value) {
                        setState(() {
                          _privacy = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('privacy_private'.tr),
                      subtitle: Text('Invite only'),
                      value: 'closed',
                      groupValue: _privacy,
                      onChanged: (value) {
                        setState(() {
                          _privacy = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.event == null
                              ? 'create_event'.tr
                              : 'save'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final isDark = Get.isDarkMode;

    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Iconsax.calendar),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
        ),
        child: Text(
          value != null
              ? DateFormat('EEEE, MMM dd, yyyy • hh:mm a').format(value)
              : 'Select date and time',
          style: TextStyle(
            color: value != null ? null : Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateTime({required bool isStart}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart
          ? _startDate ?? DateTime.now()
          : _endDate ?? _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStart) {
            _startDate = selectedDateTime;
            // Auto-adjust end date if needed
            if (_endDate == null || _endDate!.isBefore(selectedDateTime)) {
              _endDate = selectedDateTime.add(const Duration(hours: 2));
            }
          } else {
            _endDate = selectedDateTime;
          }
        });
      }
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null) {
      Get.snackbar(
        'error'.tr,
        'event_start_date_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_endDate == null) {
      Get.snackbar(
        'error'.tr,
        'event_end_date_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      Get.snackbar(
        'error'.tr,
        'End date must be after start date',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (widget.event == null) {
      // Create new event
      context.read<EventsBloc>().add(
            CreateEventEvent(
              title: _titleController.text.trim(),
              location: _locationController.text.trim(),
              description: _descriptionController.text.trim(),
              categoryId: _selectedCategory?.categoryId ?? 1,
              startDate: _formatDateForApi(_startDate!),
              endDate: _formatDateForApi(_endDate!),
              privacy: _privacy,
              isOnline: _isOnline,
              country: _selectedCountry?.countryId != null 
                  ? int.tryParse(_selectedCountry!.countryId) 
                  : null,
              language: _selectedLanguage?.languageId != null
                  ? int.tryParse(_selectedLanguage!.languageId)
                  : null,
            ),
          );
    } else {
      // Update existing event
      context.read<EventsBloc>().add(
            UpdateEventEvent(
              eventId: widget.event!.eventId,
              title: _titleController.text.trim(),
              location: _locationController.text.trim(),
              description: _descriptionController.text.trim(),
              categoryId: _selectedCategory?.categoryId,
              startDate: _formatDateForApi(_startDate!),
              endDate: _formatDateForApi(_endDate!),
              privacy: _privacy,
              isOnline: _isOnline,
              country: _selectedCountry?.countryId != null 
                  ? int.tryParse(_selectedCountry!.countryId) 
                  : null,
              language: _selectedLanguage?.languageId != null
                  ? int.tryParse(_selectedLanguage!.languageId)
                  : null,
            ),
          );
    }
  }

  /// Format date for API (MySQL format: YYYY-MM-DD HH:MM:SS)
  String _formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
  }
}
