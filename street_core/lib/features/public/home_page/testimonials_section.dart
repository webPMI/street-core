import '../../../core/helpers/responsive/responsive_builder.dart';
import '../../../core/widgets/my_card.dart';
import '../../../core/widgets/my_text.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/site_config/site_config_models.dart';
import '../site_config/site_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Testimonials Section Widget for HomePage
///
/// Displays customer testimonials in a responsive grid.
/// Has its own BlocBuilder for optimized rebuilds.
/// Only renders if testimonials exist in config.
//---Sección de testimonios: Opiniones de usuarios sobre la plataforma
class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SiteConfigCubit, SiteConfigState>(
      // Only rebuild when testimonials change
      buildWhen: (previous, current) {
        final prevTest = previous.landingTexts?.testimonials;
        final currTest = current.landingTexts?.testimonials;
        return prevTest?.length != currTest?.length;
      },
      builder: (context, state) {
        final testimonials = state.landingTexts?.testimonials;

        // Don't render if no testimonials
        if (testimonials == null || testimonials.isEmpty) {
          return const SizedBox.shrink();
        }

        return _TestimonialsContent(testimonials: testimonials);
      },
    );
  }
}

/// Internal content widget for TestimonialsSection
class _TestimonialsContent extends StatelessWidget {
  const _TestimonialsContent({required this.testimonials});
  final List<Testimonial> testimonials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = context.isDesktop;

    return Container(
      padding: EdgeInsets.all(
        context.responsive(mobile: 32, tablet: 48, desktop: 64),
      ),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // Testimonials grid
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: testimonials.take(3).map((testimonial) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _TestimonialCard(testimonial: testimonial),
                      ),
                    );
                  }).toList(),
                )
              else
                Column(
                  children: testimonials.take(3).map((testimonial) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _TestimonialCard(testimonial: testimonial),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual Testimonial Card Widget
/// Displays a single testimonial with avatar, rating, text, name and role
//---Tarjeta individual de testimonio: Avatar, calificación y comentario
class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.testimonial});
  final Testimonial testimonial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MyResponsiveCard(
      elevation: 2,
      // Default responsive padding (16-24), replacing fixed 24
      child: Column(
        children: [
          // Avatar
          UserAvatar(
            size: 40,
            imageUrl: testimonial.avatar,

            fallbackText: testimonial.name,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            textColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),

          // Rating (if available)
          if (testimonial.rating != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Icon(
                  index < testimonial.rating! ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Testimonial text
          MyText(
            testimonial.text ?? '',
            textAlign: TextAlign.center,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),

          // Name and role
          MyText(
            testimonial.name ?? '',
            istitle: true,
           
            textAlign: TextAlign.center,
          ),
          if (testimonial.role != null) ...[
            const SizedBox(height: 4),
            MyText(
              testimonial.role!,
              textAlign: TextAlign.center,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}
