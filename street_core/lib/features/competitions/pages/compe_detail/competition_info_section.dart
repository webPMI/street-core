/// Widget de Sección de Información de Competición
/// Muestra información detallada sobre una competición.
/// Siguiendo la arquitectura Monolith-by-Features (ADR-005).

import 'package:flutter/material.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/widgets/my_text.dart';
import '../../models/competition.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/images/optimized_image.dart';
import '../../../../core/helpers/responsive/responsive_breakpoints.dart';
import '../../../../core/lang/locale_keys.dart';

class CompetitionInfoSection extends StatelessWidget {
  final Competition competition;

  const CompetitionInfoSection({super.key, required this.competition});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = ResponsiveBreakpoints.getHorizontalPadding(
      screenWidth,
    );
    final verticalPadding = ResponsiveBreakpoints.getVerticalPadding(
      screenWidth,
    );
    final borderRadius = ResponsiveBreakpoints.getBorderRadius(screenWidth);
    final spacing = ResponsiveBreakpoints.getSpacing(screenWidth);
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);

    // Responsive banner height
    final bannerHeight = isMobile ? 180.0 : (screenWidth < 900 ? 220.0 : 260.0);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //-- Competition Title
          MyText(
            competition.title,
            istitle: true,
            fontSize: 20,
            margin: 10,
         
          ),
          _buildInfoRow(Icons.info_outline, LocaleKeys.id, competition.id),

          SizedBox(height: spacing),

          // Banner Image
          if (competition.bannerUrl != null ||
              (competition.imageUrls?.isNotEmpty ?? false))
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: OptimizedImage(
                imageUrl:
                    competition.bannerUrl ??
                    (competition.imageUrls?.isNotEmpty == true
                        ? competition.imageUrls!.first
                        : null),
                height: bannerHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(borderRadius),
                semanticLabel:
                    '${context.tr(LocaleKeys.competitionBanner)} ${competition.title}',
                errorWidget: _buildPlaceholder(
                  context,
                  borderRadius,
                  bannerHeight,
                ),
                placeholder: _buildPlaceholder(
                  context,
                  borderRadius,
                  bannerHeight,
                ),
              ),
            )
          else
            _buildPlaceholder(context, borderRadius, bannerHeight),

          SizedBox(height: spacing),

          // Description
          _buildSection(
            context,
            LocaleKeys.description,
            Icons.description,
            MyText(
              competition.description,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontSize: isMobile ? 14 : 16),
            ),
            isMobile,
          ),

          SizedBox(height: spacing),

          // Schedule & Location
          _buildSection(
            context,
            LocaleKeys.dateAndLocation,
            Icons.event,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.calendar_today,
                  LocaleKeys.start,
                  DateFormat.yMMMMEEEEd().add_Hm().format(
                    competition.startDate,
                  ),
                ),
                SizedBox(height: spacing / 2),
                _buildInfoRow(
                  Icons.event_available,
                  LocaleKeys.end,
                  DateFormat.yMMMMEEEEd().add_Hm().format(competition.endDate),
                ),
                if (competition.venue != null) ...[
                  SizedBox(height: spacing / 2),
                  _buildInfoRow(Icons.place, LocaleKeys.venue, competition.venue!),
                ],
                if (competition.city != null) ...[
                  SizedBox(height: spacing / 2),
                  _buildInfoRow(Icons.location_city, LocaleKeys.city, competition.city!),
                ],
                if (competition.country != null) ...[
                  SizedBox(height: spacing / 2),
                  _buildInfoRow(Icons.flag, LocaleKeys.country, competition.country!),
                ],
              ],
            ),
            isMobile,
          ),

          SizedBox(height: spacing),

          // Registration Info
          _buildSection(
            context,
            LocaleKeys.registration,
            Icons.app_registration,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.people,
                  LocaleKeys.participants,
                  '${competition.currentParticipants} / ${competition.maxParticipants}',
                ),
                if (competition.registrationDeadline != null) ...[
                  SizedBox(height: spacing / 2),
                  _buildInfoRow(
                    Icons.timer,
                    LocaleKeys.deadline,
                    DateFormat.yMMMMd().add_Hm().format(
                      competition.registrationDeadline!,
                    ),
                  ),
                ],
                SizedBox(height: spacing / 2),
                _buildInfoRow(
                  Icons.verified_user,
                  LocaleKeys.requiresApproval,
                  competition.requiresApproval ? LocaleKeys.yes : LocaleKeys.no,
                ),
                if (competition.entryFee != null) ...[
                  SizedBox(height: spacing / 2),
                  _buildInfoRow(
                    Icons.attach_money,
                    LocaleKeys.entryFee,
                    '${competition.entryFee!.toStringAsFixed(2)} ${competition.currency ?? 'USD'}',
                  ),
                ],
              ],
            ),
            isMobile,
          ),

          SizedBox(height: spacing),

          // Competition Details
          _buildSection(
            context,
            LocaleKeys.competitionDetails,
            Icons.info_outline,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (competition.competitionType != null)
                  _buildInfoRow(
                    Icons.category,
                    LocaleKeys.type,
                    competition.competitionType!,
                  ),
                if (competition.format != null) ...[
                  SizedBox(height: spacing / 2),
                  _buildInfoRow(
                    Icons.format_list_bulleted,
                    LocaleKeys.format,
                    competition.format!,
                  ),
                ],
                if (competition.category != null) ...[
                  SizedBox(height: spacing / 2),
                  _buildInfoRow(Icons.label, LocaleKeys.category, competition.category!),
                ],
                if (competition.discipline != null) ...[
                  SizedBox(height: spacing / 2),
                  _buildInfoRow(
                    Icons.emoji_events,
                    LocaleKeys.discipline,
                    competition.discipline!,
                  ),
                ],
                SizedBox(height: spacing / 2),
                _buildInfoRow(
                  Icons.layers,
                  LocaleKeys.rounds,
                  '${competition.totalRounds}',
                ),
              ],
            ),
            isMobile,
          ),

          // Prize Pool (if available)
          if (competition.prizePool != null) ...[
            SizedBox(height: spacing),
            _buildSection(
              context,
              context.tr(LocaleKeys.prizes),
              Icons.emoji_events,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.account_balance_wallet,
                    LocaleKeys.total,
                    '${competition.prizePool!.totalAmount.toStringAsFixed(2)} ${competition.prizePool!.currency}',
                  ),
                  if (competition.prizePool!.firstPlace != null) ...[
                    SizedBox(height: spacing / 2),
                    _buildInfoRow(
                      Icons.looks_one,
                      LocaleKeys.firstPlace,
                      '${competition.prizePool!.firstPlace!.toStringAsFixed(2)} ${competition.prizePool!.currency}',
                    ),
                  ],
                  if (competition.prizePool!.secondPlace != null) ...[
                    SizedBox(height: spacing / 2),
                    _buildInfoRow(
                      Icons.looks_two,
                      LocaleKeys.secondPlace,
                      '${competition.prizePool!.secondPlace!.toStringAsFixed(2)} ${competition.prizePool!.currency}',
                    ),
                  ],
                  if (competition.prizePool!.thirdPlace != null) ...[
                    SizedBox(height: spacing / 2),
                    _buildInfoRow(
                      Icons.looks_3,
                      LocaleKeys.thirdPlace,
                      '${competition.prizePool!.thirdPlace!.toStringAsFixed(2)} ${competition.prizePool!.currency}',
                    ),
                  ],
                ],
              ),
              isMobile,
            ),
          ],

          // Rules (if available)
          if (competition.rules != null) ...[
            SizedBox(height: spacing),
            _buildSection(
              context,
              LocaleKeys.rules,
              Icons.gavel,
              MyText(
                competition.rules!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: isMobile ? 13 : 14),
              ),
              isMobile,
            ),
          ],

          // Requirements (if available)
          if (competition.requirements != null) ...[
            SizedBox(height: spacing),
            _buildSection(
              context,
              LocaleKeys.requirements,
              Icons.checklist,
              MyText(
                competition.requirements!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: isMobile ? 13 : 14),
              ),
              isMobile,
            ),
          ],

          // Organizer Info
          SizedBox(height: spacing),
          _buildSection(
            context,
            LocaleKeys.organizer,
            Icons.account_circle,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.person, LocaleKeys.name, competition.organizerName),
                // normalmente no se guarda el nombre por lo que se deberia obtener el nombre del usuario por su id
                // aqui deberiamos nostrar la foto y el nombre del usuario (quizas datos publicos minimos en una pequeña card)
                //todo
                MyText(competition.organizerId),
                if (competition.clubName != null) ...[
                  SizedBox(height: spacing / 2),
                  _buildInfoRow(Icons.group, LocaleKeys.club, competition.clubName!),
                ],
              ],
            ),
            isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(
    BuildContext context,
    double borderRadius,
    double height,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withAlpha(179),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          Icons.emoji_events,
          size: isMobile ? 60 : 80,
          color: Colors.white.withAlpha(179),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Widget content,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(),
        SizedBox(height: 10),
        Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).focusColor,
              size: isMobile ? 20 : 24,
            ),
            SizedBox(width: isMobile ? 6 : 8),
            Expanded(
              child: MyText(
                title,
             
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : 22,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        content,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: isMobile ? 16 : 18, color: Colors.grey[600]),
            SizedBox(width: isMobile ? 6 : 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: isMobile ? 13 : 14,
                  ),
                  children: [
                    TextSpan(
                      text: '${context.tr(label)}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: value),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
