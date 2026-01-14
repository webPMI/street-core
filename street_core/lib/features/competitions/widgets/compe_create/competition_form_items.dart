import '../../../../core/helpers/validators.dart';
import '../../../../core/lang/locale_keys.dart';
import '../../../../core/widgets/form/form_item_config.dart';
import '../../../../core/widgets/my_text.dart';
import 'package:flutter/material.dart';

/// Section header widget for form organization
Widget _sectionHeader(String title, IconData icon) {
  return Builder(
    builder: (context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              MyText(
                title,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          Divider(),
        ],
      ),
    ),
  );
}

/// Competition form items configuration
/// Organized in sections for better UX
List<FormItemConfig> competitionFormItems = [
  // ============================================================================
  // SECTION 1: BASIC INFORMATION (Required)
  // ============================================================================
  FormItemConfig.custom(
    id: 'section_basic',
    label: '',
    customWidget: _sectionHeader(LocaleKeys.basicInfo, Icons.info_outline),
  ),
  FormItemConfig(
    id: 'title',
    label: LocaleKeys.title,
    type: FormFieldType.text,
    hintText: LocaleKeys.competitionTitle,
    isRequired: true,
    validator: requiredValidator,
    icon: Icons.emoji_events,
    maxLength: 255, // Backend: max=255
  ),
  FormItemConfig(
    id: 'description',
    label: LocaleKeys.description,
    type: FormFieldType.textarea,
    hintText: LocaleKeys.description,
    isRequired: true,
    validator: MinLengthValidator(10),
    maxLines: 6,
    icon: Icons.description,
    maxLength: 2000, // Backend: max=2000
  ),
  FormItemConfig(
    id: 'discipline',
    label: LocaleKeys.discipline,
    type: FormFieldType.dropdown,
    hintText: LocaleKeys.selectDiscipline,
    isRequired: true,
    options: [
      LocaleKeys.motocross,
      LocaleKeys.enduro,
      LocaleKeys.trial,
      LocaleKeys.supermoto,
      LocaleKeys.roadRacing,
      LocaleKeys.dirtTrack,
      LocaleKeys.freestyle,
      LocaleKeys.skateboarding,
      LocaleKeys.bmx,
      LocaleKeys.scooter,
      LocaleKeys.other,
    ],
    icon: Icons.sports_motorsports,
  ),
  FormItemConfig(
    id: 'format',
    label: LocaleKeys.format,
    type: FormFieldType.dropdown,
    hintText: LocaleKeys.selectFormat,
    isRequired: true,
    options: const [
      'championship',
      'tournament',
      'single_race', // Backend: oneof=championship,tournament,single_race,time_trial,endurance,knockout
      'time_trial',
      'endurance',
      'knockout',
    ],
    icon: Icons.format_list_bulleted,
  ),
  FormItemConfig(
    id: 'competitionType',
    label: LocaleKeys.competitionType,
    type: FormFieldType.dropdown,
    hintText: LocaleKeys.selectCompetitionType,
    isRequired: true,
    options: const ['individual', 'team', 'both'],
    defaultValue: 'individual',
    icon: Icons.people_outline,
  ),
  FormItemConfig(
    id: 'category',
    label: LocaleKeys.categoryClass,
    type: FormFieldType.text,
    hintText: LocaleKeys.categoryClassHint,
    isRequired: false, // Backend: optional
    icon: Icons.sports,
    maxLength: 50,
  ),

  // ============================================================================
  // SECTION 2: DATE & TIME
  // ============================================================================
  FormItemConfig.custom(
    id: 'section_dates',
    label: '',
    customWidget: _sectionHeader(LocaleKeys.dates, Icons.calendar_today),
  ),
  FormItemConfig(
    id: 'startDate',
    label: LocaleKeys.startDateLabel,
    type: FormFieldType.datetime,
    hintText: LocaleKeys.startDateLabel,
    isRequired: true,
    icon: Icons.event_available,
  ),
  FormItemConfig(
    id: 'endDate',
    label: LocaleKeys.endDateLabel,
    type: FormFieldType.datetime,
    hintText: LocaleKeys.endDateLabel,
    isRequired: true,
    icon: Icons.event_busy,
  ),
  FormItemConfig(
    id: 'registrationDeadline',
    label: LocaleKeys.registrationDeadlineLabel,
    type: FormFieldType.datetime,
    hintText: LocaleKeys.registrationDeadlineLabel,
    icon: Icons.alarm,
  ),

  // ============================================================================
  // SECTION 3: LOCATION
  // ============================================================================
  FormItemConfig.custom(
    id: 'section_location',
    label: '',
    customWidget: _sectionHeader(LocaleKeys.location, Icons.place),
  ),
  FormItemConfig(
    id: 'venue',
    label: LocaleKeys.venue,
    type: FormFieldType.text,
    hintText: LocaleKeys.venueName,
    isRequired: false, // Backend: optional
    icon: Icons.stadium,
  ),
  FormItemConfig(
    id: 'city',
    label: LocaleKeys.city,
    type: FormFieldType.text,
    hintText: LocaleKeys.city,
    icon: Icons.location_city,
  ),
  FormItemConfig(
    id: 'country',
    label: LocaleKeys.country,
    type: FormFieldType.text,
    hintText: LocaleKeys.country,
    icon: Icons.public,
  ),

  // ============================================================================
  // SECTION 4: PARTICIPANTS & REGISTRATION
  // ============================================================================
  FormItemConfig.custom(
    id: 'section_participants',
    label: '',
    customWidget: _sectionHeader(LocaleKeys.participants, Icons.people),
  ),
  FormItemConfig(
    id: 'maxParticipants',
    label: LocaleKeys.maxParticipants,
    type: FormFieldType.number,
    hintText: LocaleKeys.maxParticipants,
    isRequired: false, // Backend: optional
    defaultValue: 50,
    icon: Icons.people,
  ),
  FormItemConfig(
    id: 'minParticipants',
    label: LocaleKeys.minParticipants,
    type: FormFieldType.number,
    hintText: LocaleKeys.minParticipants,
    defaultValue: 1,
    icon: Icons.people_outline,
  ),
  FormItemConfig(
    id: 'requiresApproval',
    label: LocaleKeys.requiresApproval,
    type: FormFieldType.checkbox,
    hintText: LocaleKeys.requiresApprovalHint,
    defaultValue: false,
    icon: Icons.verified_user,
  ),
  FormItemConfig(
    id: 'entryFee',
    label: LocaleKeys.entryFee,
    type: FormFieldType.number,
    hintText: LocaleKeys.entryFee,
    defaultValue: 0,
    icon: Icons.attach_money,
  ),
  FormItemConfig(
    id: 'currency',
    label: LocaleKeys.currency,
    type: FormFieldType.dropdown,
    hintText: LocaleKeys.selectCurrency,
    options: const ['EUR', 'USD', 'GBP', 'MXN', 'ARS', 'CLP'],
    defaultValue: 'EUR',
    icon: Icons.monetization_on,
  ),

  // ============================================================================
  // SECTION 5: MEDIA (Optional)
  // ============================================================================
  FormItemConfig.custom(
    id: 'section_media',
    label: '',
    customWidget: _sectionHeader(LocaleKeys.mediaImageSelect, Icons.image),
  ),
  FormItemConfig(
    id: 'bannerUrl',
    label: LocaleKeys.competitionBanner,
    type: FormFieldType.image,
    hintText: LocaleKeys.bannerImage,
    icon: Icons.image,
  ),

  // ============================================================================
  // SECTION 6: SCORING
  // ============================================================================
  FormItemConfig.custom(
    id: 'section_scoring',
    label: '',
    customWidget: _sectionHeader(LocaleKeys.scoringSystem, Icons.scoreboard),
  ),
  FormItemConfig(
    id: 'scoringType',
    label: LocaleKeys.scoringSystem,
    type: FormFieldType.dropdown,
    hintText: LocaleKeys.selectScoringType,
    isRequired: true,
    options: const [
      'points',
      'time',
      'average',
      'sum',
      'weighted_average',
    ],
    defaultValue: 'points',
    icon: Icons.scoreboard,
  ),
  FormItemConfig(
    id: 'maxScore',
    label: LocaleKeys.totalScore,
    type: FormFieldType.number,
    hintText: LocaleKeys.maxScoreHint,
    isRequired: true,
    defaultValue: 100,
    icon: Icons.trending_up,
  ),
  FormItemConfig(
    id: 'totalRounds',
    label: LocaleKeys.rounds,
    type: FormFieldType.number,
    hintText: LocaleKeys.totalRoundsHint,
    defaultValue: 1,
    icon: Icons.repeat,
  ),

  // ============================================================================
  // SECTION 7: RULES (Optional)
  // ============================================================================
  FormItemConfig.custom(
    id: 'section_rules',
    label: '',
    customWidget: _sectionHeader(LocaleKeys.rules, Icons.rule),
  ),
  FormItemConfig(
    id: 'rules',
    label: LocaleKeys.rules,
    type: FormFieldType.textarea,
    hintText: LocaleKeys.competitionRulesHint,
    maxLines: 6,
    icon: Icons.rule,
    maxLength: 2000,
  ),
];
