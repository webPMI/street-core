import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/widgets/my_text.dart';
import '../../../core/router/navigation_service.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../bloc/tournaments_cubit.dart';
import '../bloc/tournaments_state.dart';
import '../models/tournament.dart';

/// Page for creating or editing a tournament
class TournamentFormPage extends StatefulWidget {
  final String? tournamentId; // null = create, non-null = edit
  final Tournament? existingTournament;

  const TournamentFormPage({
    super.key,
    this.tournamentId,
    this.existingTournament,
  });

  @override
  State<TournamentFormPage> createState() => _TournamentFormPageState();
}

class _TournamentFormPageState extends State<TournamentFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _venueController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late TextEditingController _maxParticipantsController;
  late TextEditingController _entryFeeController;
  late TextEditingController _currencyController;

  // Form values
  String _discipline = 'inline';
  String _format = 'series';
  String _scoringSystem = 'points';
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _registrationDeadline;
  int? _countBestOf;
  int? _dropWorst;

  bool _isLoading = false;
  bool get _isEditMode => widget.tournamentId != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingData();
  }

  void _initializeControllers() {
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _venueController = TextEditingController();
    _cityController = TextEditingController();
    _countryController = TextEditingController();
    _maxParticipantsController = TextEditingController(text: '100');
    _entryFeeController = TextEditingController();
    _currencyController = TextEditingController(text: 'USD');
  }

  void _loadExistingData() {
    if (_isEditMode && widget.existingTournament != null) {
      final tournament = widget.existingTournament!;

      _titleController.text = tournament.title;
      _descriptionController.text = tournament.description;
      _discipline = tournament.discipline;
      _format = tournament.format;
      _scoringSystem = tournament.scoringSystem;

      _startDate = tournament.schedule.startDate;
      _endDate = tournament.schedule.endDate;
      _venueController.text = tournament.schedule.venue ?? '';
      _cityController.text = tournament.schedule.city ?? '';
      _countryController.text = tournament.schedule.country ?? '';

      _maxParticipantsController.text =
          tournament.registration.maxParticipants?.toString() ?? '100';
      _registrationDeadline = tournament.registration.registrationDeadline;
      _entryFeeController.text =
          tournament.registration.entryFee?.toString() ?? '';
      _currencyController.text = tournament.registration.currency ?? 'USD';

      _countBestOf = tournament.scoringConfig.countBestOf;
      _dropWorst = tournament.scoringConfig.dropWorst;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _maxParticipantsController.dispose();
    _entryFeeController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  String _getDisciplineKey(String discipline) {
    switch (discipline) {
      case 'inline':
        return LocaleKeys.inline;
      case 'bmx':
        return LocaleKeys.bmx;
      case 'skateboard':
        return LocaleKeys.skateboarding;
      case 'scooter':
        return LocaleKeys.scooter;
      default:
        return discipline;
    }
  }

  String _getFormatKey(String format) {
    switch (format) {
      case 'series':
        return LocaleKeys.tournamentFormatsSeries;
      case 'single':
        return LocaleKeys.tournamentFormatsSingle;
      case 'knockout':
        return LocaleKeys.tournamentFormatsKnockout;
      default:
        return format;
    }
  }

  String _getScoringSystemKey(String system) {
    switch (system) {
      case 'points':
        return LocaleKeys.tournamentScoringPoints;
      case 'time':
        return LocaleKeys.tournamentScoringTime;
      case 'best_result':
        return LocaleKeys.tournamentScoringBestResult;
      default:
        return system;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: MyText(
          _isEditMode
              ? LocaleKeys.tournamentsEdit
              : LocaleKeys.tournamentsCreateNew,

        ),
      ),
      body: BlocListener<TournamentsCubit, TournamentsState>(
        listener: (context, state) {
          if (state is TournamentOperationSuccess) {
            SnackBarHelper.showCustom(context, state.message, type: SnackBarType.success);
            // Navigate back after successful operation
            NavigationService().pop(context);
          } else if (state is TournamentsError) {
            SnackBarHelper.showCustom(context, state.message, type: SnackBarType.error);
          }
        },
        child: BlocBuilder<TournamentsCubit, TournamentsState>(
          builder: (context, state) {
            if (state is TournamentOperationLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(theme),
                    const SizedBox(height: 24),
                    _buildScheduleSection(theme),
                    const SizedBox(height: 24),
                    _buildRegistrationSection(theme),
                    const SizedBox(height: 24),
                    _buildScoringSection(theme),
                    const SizedBox(height: 32),
                    _buildSubmitButton(theme),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          LocaleKeys.basicInfo,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Title
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: context.tr(LocaleKeys.title),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return context.tr(LocaleKeys.errorRequiredField);
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: context.tr(LocaleKeys.description),
            border: const OutlineInputBorder(),
          ),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return context.tr(LocaleKeys.errorRequiredField);
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Discipline
        DropdownButtonFormField<String>(
          value: _discipline,
          decoration: InputDecoration(
            labelText: context.tr(LocaleKeys.discipline),
            border: const OutlineInputBorder(),
          ),
          items: ['inline', 'bmx', 'skateboard', 'scooter']
              .map((discipline) => DropdownMenuItem(
                    value: discipline,
                    child: MyText(_getDisciplineKey(discipline)),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _discipline = value);
            }
          },
        ),
        const SizedBox(height: 16),

        // Format
        DropdownButtonFormField<String>(
          value: _format,
          decoration: InputDecoration(
            labelText: context.tr(LocaleKeys.format),
            border: const OutlineInputBorder(),
          ),
          items: ['series', 'single', 'knockout']
              .map((format) => DropdownMenuItem(
                    value: format,
                    child: MyText(_getFormatKey(format)),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _format = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildScheduleSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          LocaleKeys.tournamentsSchedule,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Start Date
        ListTile(
          title: MyText(LocaleKeys.tournamentsStartDate),
          subtitle: MyText(
            _startDate != null
                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                : context.tr(LocaleKeys.selectDate),
            noTranslation: _startDate != null,
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _startDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (date != null) {
              setState(() => _startDate = date);
            }
          },
        ),

        // End Date
        ListTile(
          title: MyText(LocaleKeys.tournamentsEndDate),
          subtitle: MyText(
            _endDate != null
                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                : context.tr(LocaleKeys.selectDate),
            noTranslation: _endDate != null,
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _endDate ?? _startDate ?? DateTime.now(),
              firstDate: _startDate ?? DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (date != null) {
              setState(() => _endDate = date);
            }
          },
        ),
        const SizedBox(height: 16),

        // Venue
        TextFormField(
          controller: _venueController,
          decoration: InputDecoration(
            labelText: context.tr(LocaleKeys.tournamentsVenue),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // City
        TextFormField(
          controller: _cityController,
          decoration: InputDecoration(
            labelText: context.tr(LocaleKeys.city),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Country
        TextFormField(
          controller: _countryController,
          decoration: InputDecoration(
            labelText: context.tr(LocaleKeys.tournamentsCountry),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          LocaleKeys.tournamentsRegistration,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Max Participants
        TextFormField(
          controller: _maxParticipantsController,
          decoration: InputDecoration(
            labelText: context.tr(LocaleKeys.tournamentsMaxParticipants),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        // Registration Deadline
        ListTile(
          title: MyText(LocaleKeys.tournamentsDeadline),
          subtitle: MyText(
            _registrationDeadline != null
                ? '${_registrationDeadline!.day}/${_registrationDeadline!.month}/${_registrationDeadline!.year}'
                : context.tr(LocaleKeys.selectDate),
            noTranslation: _registrationDeadline != null,
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _registrationDeadline ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: _startDate ?? DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() => _registrationDeadline = date);
            }
          },
        ),
        const SizedBox(height: 16),

        // Entry Fee
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _entryFeeController,
                decoration: InputDecoration(
                  labelText: context.tr(LocaleKeys.tournamentsEntryFee),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _currencyController,
                decoration: InputDecoration(
                  labelText: context.tr(LocaleKeys.currency),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoringSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          LocaleKeys.tournamentsScoringSystem,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Scoring System
        DropdownButtonFormField<String>(
          value: _scoringSystem,
          decoration: InputDecoration(
            labelText: context.tr(LocaleKeys.tournamentsSystem),
            border: const OutlineInputBorder(),
          ),
          items: ['points', 'time', 'best_result']
              .map((system) => DropdownMenuItem(
                    value: system,
                    child: MyText(_getScoringSystemKey(system)),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _scoringSystem = value);
            }
          },
        ),
        const SizedBox(height: 16),

        // Count Best Of
        TextFormField(
          decoration: InputDecoration(
            labelText: context.tr(LocaleKeys.tournamentsCountBest),
            border: const OutlineInputBorder(),
            hintText: context.tr(LocaleKeys.optional),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _countBestOf = int.tryParse(value);
          },
        ),
        const SizedBox(height: 16),

        // Drop Worst
        TextFormField(
          decoration: InputDecoration(
            labelText: context.tr(LocaleKeys.tournamentsDropWorst),
            border: const OutlineInputBorder(),
            hintText: context.tr(LocaleKeys.optional),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _dropWorst = int.tryParse(value);
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator()
            : MyText(
                _isEditMode
                    ? LocaleKeys.tournamentsEdit
                    : LocaleKeys.tournamentsCreateNew,
              ),
      ),
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      SnackBarHelper.showError(context, LocaleKeys.errorSelectDates);
      return;
    }

    setState(() => _isLoading = true);

    final tournamentData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'discipline': _discipline,
      'format': _format,
      'schedule': {
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'venue': _venueController.text.trim(),
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim(),
      },
      'registration': {
        'maxParticipants': int.tryParse(_maxParticipantsController.text),
        'registrationDeadline': _registrationDeadline?.toIso8601String(),
        'entryFee': double.tryParse(_entryFeeController.text),
        'currency': _currencyController.text.trim(),
      },
      'scoringSystem': _scoringSystem,
      'scoringConfig': {
        if (_countBestOf != null) 'countBestOf': _countBestOf,
        if (_dropWorst != null) 'dropWorst': _dropWorst,
      },
    };

    final cubit = context.read<TournamentsCubit>();

    if (_isEditMode) {
      await cubit.updateTournament(widget.tournamentId!, tournamentData);
    } else {
      await cubit.createTournament(tournamentData);
    }

    setState(() => _isLoading = false);
  }
}
