import 'package:street_core/core/widgets/drawer/my_drawer.dart';

import '../../../core/lang/language_selector.dart';
import '../../../core/router/navigation_service.dart';
import '../../competitions/competition_routes.dart';

import '../../../../core/di/injection.dart';
import '../site_config/site_config.dart';
import 'cta_section.dart';
import 'features_section.dart';
import 'footer.dart';
import 'testimonials_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/core/lang/locale_keys.dart';
import 'package:street_core/core/widgets/my_text.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    //---Provee el Cubit de configuración localmente para la landing page
    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.home),
            const SizedBox(width: 8),
            const MyText(LocaleKeys.appTitle,),
          ],
        ),
      ),
      body: BlocProvider<SiteConfigCubit>.value(
        value: getIt<SiteConfigCubit>()..loadLandingTexts(),
        child: RefreshIndicator(
          onRefresh: () async {
            await getIt<SiteConfigCubit>().refreshLandingTexts();
          },
          child: SingleChildScrollView(
            child: Column(
              children: [
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  NavigationService().go(
                    context,
                    CompetitionRoutes.competitionsList,
                  );
                },
                child: MyText(LocaleKeys.competitions, selectable: false),
              ),
              SizedBox(width: 400, child: LanguageSelector()),
              // Image Section
              //---Sección Hero con el banner principal y botones de acción
              //             HeroSection(),

              //---Sección de características del sitio (Clubs, Market, etc)
              FeaturesSection(),
              //---Sección de testimonios de usuarios reales
              TestimonialsSection(),

              //---Sección de llamada a la acción (CTA) final
              CTASection(),
              Footer(),
            ],
          ),
        ),
          ),
      ),
    );
  }
}
