import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../models/profile_model.dart';
import '../../../../core/utils/validators.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _servingSizeController;
  String _unitPreference = 'metric';
  List<HouseholdMember> _householdMembers = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _locationController = TextEditingController();
    _servingSizeController = TextEditingController(text: '4');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _servingSizeController.dispose();
    super.dispose();
  }

  void _loadProfileData(ProfileModel? profile) {
    if (profile != null) {
      _nameController.text = profile.name;
      _emailController.text = profile.email;
      _locationController.text = profile.location ?? '';
      _servingSizeController.text = profile.servingSize.toString();
      _unitPreference = profile.unitPreference;
      _householdMembers = List.from(profile.householdMembers);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user logged in'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      final servingSize = int.tryParse(_servingSizeController.text) ?? 4;

      await ref.read(profileControllerProvider.notifier).updateProfile(
            userId: userId,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            location: _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
            unitPreference: _unitPreference,
            servingSize: servingSize,
            householdMembers: _householdMembers,
          );

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _addHouseholdMember() {
    showDialog(
      context: context,
      builder: (context) => _AddHouseholdMemberDialog(
        onSave: (member) {
          setState(() {
            _householdMembers.add(member);
          });
        },
      ),
    );
  }

  void _editHouseholdMember(int index) {
    final member = _householdMembers[index];
    showDialog(
      context: context,
      builder: (context) => _AddHouseholdMemberDialog(
        initialMember: member,
        onSave: (updatedMember) {
          setState(() {
            _householdMembers[index] = updatedMember;
          });
        },
      ),
    );
  }

  void _removeHouseholdMember(int index) {
    setState(() {
      _householdMembers.removeAt(index);
    });
  }

  Future<void> _createProfileIfNeeded() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final firestoreService = ref.read(firestoreServiceProvider);
    final profileExists = await firestoreService.userProfileExists(userId);

    if (!profileExists) {
      // Get user email from auth
      final authState = ref.read(authStateProvider);
      final email = authState.value?.email ?? '';
      final displayName = authState.value?.displayName ?? email.split('@')[0];

      try {
        await ref.read(profileControllerProvider.notifier).createProfile(
              userId: userId,
              name: displayName,
              email: email,
              location: null,
              unitPreference: 'metric',
              servingSize: 4,
              householdMembers: [],
            );
        // Refresh the profile stream
        ref.invalidate(profileStreamProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create profile: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileStreamProvider);
    final isLoading = ref.watch(profileControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                });
                // Reload profile data
                profileAsync.whenData(_loadProfileData);
              },
              child: const Text('Cancel'),
            ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          // Auto-create profile if it doesn't exist
          if (profile == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _createProfileIfNeeded();
            });
            return const Center(child: CircularProgressIndicator());
          }

          if (profile != null && !_isEditing) {
            _loadProfileData(profile);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text
                                : 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Name Field
                  CustomTextField(
                    label: 'Name',
                    controller: _nameController,
                    enabled: _isEditing,
                    prefixIcon: Icons.person_outline,
                    validator: Validators.validateName,
                  ),

                  const SizedBox(height: 16),

                  // Email Field
                  CustomTextField(
                    label: 'Email',
                    controller: _emailController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: Validators.validateEmail,
                  ),

                  const SizedBox(height: 16),

                  // Location Field
                  CustomTextField(
                    label: 'Location (Optional)',
                    controller: _locationController,
                    enabled: _isEditing,
                    prefixIcon: Icons.location_on_outlined,
                    hint: 'Enter your location',
                  ),

                  const SizedBox(height: 16),

                  // Unit Preference
                  if (_isEditing) ...[
                    const Text(
                      'Unit Preference',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'metric',
                          label: Text('Metric'),
                          icon: Icon(Icons.straighten),
                        ),
                        ButtonSegment(
                          value: 'imperial',
                          label: Text('Imperial'),
                          icon: Icon(Icons.straighten_outlined),
                        ),
                      ],
                      selected: {_unitPreference},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _unitPreference = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.straighten),
                        title: const Text('Unit Preference'),
                        subtitle: Text(
                          _unitPreference == 'metric' ? 'Metric' : 'Imperial',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Serving Size
                  CustomTextField(
                    label: 'Default Serving Size',
                    controller: _servingSizeController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.restaurant_outlined,
                    validator: (value) {
                      if (!_isEditing) return null;
                      final error = Validators.validateInteger(value, 'Serving size');
                      if (error != null) return error;
                      final size = int.tryParse(value ?? '');
                      if (size != null && (size < 1 || size > 20)) {
                        return 'Serving size must be between 1 and 20';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Household Members Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Household Members',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_isEditing)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _addHouseholdMember,
                          color: AppColors.primary,
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (_householdMembers.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No household members added yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._householdMembers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final member = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(member.name[0].toUpperCase()),
                          ),
                          title: Text(member.name),
                          subtitle: Text(
                            [
                              if (member.relationship != null)
                                member.relationship,
                              if (member.age != null) 'Age: ${member.age}',
                            ].join(' • '),
                          ),
                          trailing: _isEditing
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editHouseholdMember(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: AppColors.error,
                                      onPressed: () => _removeHouseholdMember(index),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  // Save Button
                  if (_isEditing)
                    CustomButton(
                      text: 'Save Profile',
                      onPressed: isLoading ? null : _saveProfile,
                      isLoading: isLoading,
                      icon: Icons.save,
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading profile: $error',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Retry',
                onPressed: () {
                  ref.invalidate(profileStreamProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddHouseholdMemberDialog extends StatefulWidget {
  final HouseholdMember? initialMember;
  final Function(HouseholdMember) onSave;

  const _AddHouseholdMemberDialog({
    this.initialMember,
    required this.onSave,
  });

  @override
  State<_AddHouseholdMemberDialog> createState() =>
      _AddHouseholdMemberDialogState();
}

class _AddHouseholdMemberDialogState extends State<_AddHouseholdMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  String? _relationship;

  final List<String> _relationships = [
    'spouse',
    'child',
    'parent',
    'sibling',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialMember?.name ?? '',
    );
    _ageController = TextEditingController(
      text: widget.initialMember?.age?.toString() ?? '',
    );
    _relationship = widget.initialMember?.relationship;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final member = HouseholdMember(
      id: widget.initialMember?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      relationship: _relationship,
      age: _ageController.text.trim().isEmpty
          ? null
          : int.tryParse(_ageController.text.trim()),
    );

    widget.onSave(member);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialMember == null
          ? 'Add Household Member'
          : 'Edit Household Member'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Name',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                validator: Validators.validateName,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _relationship,
                decoration: const InputDecoration(
                  labelText: 'Relationship (Optional)',
                  prefixIcon: Icon(Icons.people_outline),
                ),
                items: _relationships.map((rel) {
                  return DropdownMenuItem(
                    value: rel,
                    child: Text(rel[0].toUpperCase() + rel.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _relationship = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Age (Optional)',
                controller: _ageController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.cake_outlined,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final age = int.tryParse(value);
                    if (age == null) {
                      return 'Please enter a valid age';
                    }
                    if (age < 0 || age > 150) {
                      return 'Age must be between 0 and 150';
                    }
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

