// lib/presentation/dashboard/competitions/categories/widgets/category_form_dialog.dart

import '../../../../core/widgets/my_button.dart';
import '../../../../core/widgets/my_text.dart';
import '../../../../core/widgets/my_text_form_field.dart';
import '../bloc/competition_category_cubit.dart';
import '../../models/competition_category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryFormDialog extends StatefulWidget { // null for create, non-null for edit

  const CategoryFormDialog({
    super.key,
    required this.competitionId,
    this.category,
  });
  final String competitionId;
  final CompetitionCategory? category;

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _minAgeController;
  late final TextEditingController _maxAgeController;
  late final TextEditingController _maxJudgesController;

  String _selectedSkillLevel = SkillLevel.intermediate;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();

    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _descriptionController = TextEditingController(
      text: category?.description ?? '',
    );
    _minAgeController = TextEditingController(
      text: category?.minAge?.toString() ?? '',
    );
    _maxAgeController = TextEditingController(
      text: category?.maxAge?.toString() ?? '',
    );
    _maxJudgesController = TextEditingController(
      text: category?.maxJudges.toString() ?? '3',
    );

    if (category != null) {
      _selectedSkillLevel = category.skillLevel;
      _isActive = category.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _maxJudgesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Row(
                  children: [
                    Icon(Icons.category, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MyText(
                        isEdit ? 'edit_category' : 'add_category',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name field
                MyTextFormField(
                  controller: _nameController,
                  label: 'category_name',
                  hint: 'enter_category_name',
                  icon: const Icon(Icons.label),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'required_field';
                    }
                    if (value.length < 2) {
                      return 'minimum_2_characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description field
                MyTextFormField(
                  controller: _descriptionController,
                  label: 'category_description',
                  hint: 'enter_description',
                  icon: const Icon(Icons.description),
                  maxLines: 3,
                  maxLength: 500,
                ),
                const SizedBox(height: 16),

                // Skill Level dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedSkillLevel,
                  decoration: InputDecoration(
                    labelText: 'Skill Level',
                    prefixIcon: const Icon(Icons.trending_up),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: SkillLevel.all.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(SkillLevel.getDisplayName(level)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedSkillLevel = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Age Range
                Row(
                  children: [
                    Expanded(
                      child: MyTextFormField(
                        controller: _minAgeController,
                        label: 'min_age',
                        hint: '0',
                        icon: const Icon(Icons.calendar_today),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final age = int.tryParse(value);
                            if (age == null || age < 0 || age > 120) {
                              return 'invalid_age';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MyTextFormField(
                        controller: _maxAgeController,
                        label: 'max_age',
                        hint: '100',
                        icon: const Icon(Icons.calendar_today),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final age = int.tryParse(value);
                            if (age == null || age < 0 || age > 120) {
                              return 'invalid_age';
                            }

                            // Check if max > min
                            final minAge = int.tryParse(_minAgeController.text);
                            if (minAge != null && age < minAge) {
                              return 'max_age_less_than_min';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Max Judges
                MyTextFormField(
                  controller: _maxJudgesController,
                  label: 'max_judges',
                  hint: '3',
                  icon: const Icon(Icons.gavel),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'required_field';
                    }
                    final judges = int.tryParse(value);
                    if (judges == null || judges < 1 || judges > 20) {
                      return 'invalid_max_judges';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Active toggle (only for edit)
                if (isEdit)
                  SwitchListTile(
                    title: const MyText('active'),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    contentPadding: EdgeInsets.zero,
                  ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const MyText('cancel'),
                    ),
                    const SizedBox(width: 12),
                    MyButton(
                      text: isEdit ? 'update' : 'create',
                      onPressed: _handleSubmit,
                      icon: isEdit ? Icons.check : Icons.add,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final categoryData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'skillLevel': _selectedSkillLevel,
      'maxJudges': int.parse(_maxJudgesController.text),
      if (_minAgeController.text.isNotEmpty)
        'minAge': int.parse(_minAgeController.text),
      if (_maxAgeController.text.isNotEmpty)
        'maxAge': int.parse(_maxAgeController.text),
      if (widget.category != null) 'isActive': _isActive,
    };

    if (widget.category != null) {
      // Update existing category
      context.read<CompetitionCategoryCubit>().updateCategory(
        widget.competitionId,
        widget.category!.id,
        categoryData,
      );
    } else {
      // Create new category
      context.read<CompetitionCategoryCubit>().createCategory(
        widget.competitionId,
        categoryData,
      );
    }

    Navigator.pop(context);
  }
}
