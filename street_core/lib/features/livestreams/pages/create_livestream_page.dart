// lib/features/livestreams/pages/create_livestream_page.dart

import 'package:flutter/material.dart';
import 'package:street_core/core/services/api_service.dart';
import 'package:street_core/core/theme/app_spacing.dart';
import 'package:street_core/core/helpers/snackbar_helper.dart';
import 'package:street_core/core/lang/context_tr.dart';
import 'package:street_core/core/lang/locale_keys.dart';
import 'package:street_core/core/widgets/my_text.dart';
import 'package:street_core/features/livestreams/services/livestream_service.dart';

/// Page for creating a new livestream
class CreateLiveStreamPage extends StatefulWidget {
  const CreateLiveStreamPage({super.key});

  @override
  State<CreateLiveStreamPage> createState() => _CreateLiveStreamPageState();
}

class _CreateLiveStreamPageState extends State<CreateLiveStreamPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _recordingEnabled = false;
  bool _isScheduled = false;
  DateTime? _scheduledTime;
  bool _isCreating = false;

  late LiveStreamService _service;

  @override
  void initState() {
    super.initState();
    // TODO: Get from DI
    _service = LiveStreamService(ApiService());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText(LocaleKeys.createLivestream),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(AppSpacing.md),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: context.tr(LocaleKeys.livestreamTitle),
                hintText: context.tr(LocaleKeys.enterLivestreamTitle),
                prefixIcon: const Icon(Icons.title),
              ),
              maxLength: 100,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr(LocaleKeys.errorRequiredField);
                }
                if (value.trim().length < 3) {
                  return context.tr(LocaleKeys.minLength, args: {'min': '3'});
                }
                return null;
              },
            ),

            SizedBox(height: AppSpacing.md),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: context.tr(LocaleKeys.livestreamDescription),
                hintText: context.tr(LocaleKeys.enterLivestreamDescription),
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 500,
            ),

            SizedBox(height: AppSpacing.md),

            // Tags field
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: context.tr(LocaleKeys.tagsSeparatedByCommas),
                hintText: context.tr(LocaleKeys.tagsExample),
                prefixIcon: const Icon(Icons.tag),
              ),
            ),

            SizedBox(height: AppSpacing.md),

            // Recording option
            SwitchListTile(
              title: MyText(LocaleKeys.enableRecording, selectable: false),
              subtitle: MyText(LocaleKeys.recordingDescription, selectable: false),
              value: _recordingEnabled,
              onChanged: (value) {
                setState(() => _recordingEnabled = value);
              },
            ),

            // Schedule option
            SwitchListTile(
              title: MyText(LocaleKeys.scheduleLivestream, selectable: false),
              subtitle: MyText(LocaleKeys.scheduleDescription, selectable: false),
              value: _isScheduled,
              onChanged: (value) {
                setState(() {
                  _isScheduled = value;
                  if (!value) _scheduledTime = null;
                });
              },
            ),

            // Scheduled time picker
            if (_isScheduled) ...[
              SizedBox(height: AppSpacing.sm),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _scheduledTime != null
                      ? context.tr(LocaleKeys.scheduledFor, args: {'time': _formatDate(_scheduledTime!)})
                      : context.tr(LocaleKeys.selectDateAndTime),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickScheduledTime,
              ),
            ],

            SizedBox(height: AppSpacing.xl),

            // Submit button
            ElevatedButton(
              onPressed: _isCreating ? null : _createStream,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : MyText(
                      _isScheduled ? LocaleKeys.scheduleLivestream : LocaleKeys.createLivestream,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),

            SizedBox(height: AppSpacing.md),

            // Info text
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: AppSpacing.sm),
                        MyText(
                          LocaleKeys.info,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    MyText(
                      LocaleKeys.livestreamInfoPoints,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickScheduledTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledTime ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _scheduledTime ?? now.add(const Duration(hours: 1)),
      ),
    );

    if (time == null) return;

    setState(() {
      _scheduledTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _createStream() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isScheduled && _scheduledTime == null) {
      SnackBarHelper.showWarning(context, LocaleKeys.selectDateAndTime);
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Parse tags
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Create stream
      final stream = await _service.createLiveStream(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        scheduledTime: _scheduledTime,
        recordingEnabled: _recordingEnabled,
        tags: tags,
      );

      if (!mounted) return;

      // Navigate to stream page
      Navigator.pushReplacementNamed(
        context,
        '/livestreams/host',
        arguments: stream.id,
      );
    } catch (e) {
      if (!mounted) return;

      SnackBarHelper.showBackendError(
        context,
        fallbackMessage: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) {
      return context.tr(LocaleKeys.scheduledTodayAt, args: {'time': TimeOfDay.fromDateTime(date).format(context)});
    } else if (diff.inDays == 1) {
      return context.tr(LocaleKeys.scheduledTomorrowAt, args: {'time': TimeOfDay.fromDateTime(date).format(context)});
    } else {
      return context.tr(LocaleKeys.scheduledAt, args: {
        'date': '${date.day}/${date.month}/${date.year}',
        'time': TimeOfDay.fromDateTime(date).format(context)
      });
    }
  }
}
