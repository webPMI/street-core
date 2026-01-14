/// Documentación de Competiciones en Español
///
/// Contiene todas las traducciones para la página de documentación
/// del módulo de competiciones, incluyendo explicaciones de formatos,
/// tipos, roles, sistemas de puntuación y flujos de trabajo.
///
const Map<String, String> competitionsDocsEs = {
  // ============================================================================
  // GENERAL
  // ============================================================================
  'docs.title': 'Documentación de Competiciones',
  'docs.subtitle': 'Guía completa para crear y gestionar competiciones en StreetCore',
  'docs.search.placeholder': 'Buscar en la documentación...',
  'docs.back.to.top': 'Volver arriba',

  // ============================================================================
  // NAVIGATION
  // ============================================================================
  'docs.nav.introduction': 'Introducción',
  'docs.nav.types': 'Tipos de Competición',
  'docs.nav.formats': 'Formatos',
  'docs.nav.roles': 'Roles y Permisos',
  'docs.nav.scoring': 'Sistema de Puntuación',
  'docs.nav.workflow': 'Flujo Completo',
  'docs.nav.faq': 'Preguntas Frecuentes',
  'docs.nav.best.practices': 'Mejores Prácticas',

  // ============================================================================
  // INTRODUCTION
  // ============================================================================
  'docs.intro.title': 'Introducción a Competiciones',
  'docs.intro.subtitle': '¿Qué son y cómo funcionan las competiciones en StreetCore?',

  'docs.intro.what.title': '¿Qué es una competición?',
  'docs.intro.what.content':
      'Una competición en StreetCore es un evento organizado donde los atletas compiten '
      'en diferentes disciplinas de deportes urbanos (inline, BMX, skateboarding, scooter). '
      'Las competiciones pueden ser individuales, por equipos o ambos, y siguen diferentes '
      'formatos según la naturaleza del evento.',

  'docs.intro.key.features.title': 'Características principales',
  'docs.intro.key.features.item1': 'Sistema de puntuación flexible con múltiples criterios',
  'docs.intro.key.features.item2': 'Gestión de participantes con aprobación opcional',
  'docs.intro.key.features.item3': 'Panel de jueces con invitaciones y seguimiento',
  'docs.intro.key.features.item4': 'Categorías personalizables por nivel y edad',
  'docs.intro.key.features.item5': 'Resultados en tiempo real y leaderboards',
  'docs.intro.key.features.item6': 'Livestreaming integrado para transmitir eventos',

  'docs.intro.why.use.title': '¿Por qué usar StreetCore para tus competiciones?',
  'docs.intro.why.use.content':
      'StreetCore centraliza todo el proceso de gestión de competiciones: desde el registro '
      'de participantes, asignación de jueces, puntuación en vivo, hasta la publicación de '
      'resultados. Todo en una plataforma diseñada específicamente para deportes urbanos.',

  // ============================================================================
  // TYPES - TIPOS DE COMPETICIÓN
  // ============================================================================
  'docs.types.title': 'Tipos de Competición',
  'docs.types.subtitle': 'Elige el tipo adecuado según la naturaleza de tu evento',

  // Individual
  'docs.types.individual.title': 'Individual',
  'docs.types.individual.badge': 'Más común',
  'docs.types.individual.description':
      'En este formato, cada atleta compite por su cuenta. Las puntuaciones se asignan '
      'individualmente y el ranking refleja el desempeño personal de cada participante.',
  'docs.types.individual.when.title': 'Cuándo usar:',
  'docs.types.individual.when.item1': 'Competiciones de Street/Park donde cada atleta hace su run',
  'docs.types.individual.when.item2': 'Eventos de Flatland o técnica individual',
  'docs.types.individual.when.item3': 'Time trials o carreras contrarreloj',
  'docs.types.individual.when.item4': 'Campeonatos donde quieres un ganador individual claro',
  'docs.types.individual.example.title': 'Ejemplo práctico:',
  'docs.types.individual.example.content':
      'Un campeonato de inline street donde cada rider tiene 2 minutos para mostrar sus '
      'mejores trucos. Los jueces califican técnica, dificultad y estilo individualmente.',

  // Team
  'docs.types.team.title': 'Equipos',
  'docs.types.team.description':
      'Los atletas compiten como parte de un equipo. Las puntuaciones individuales se '
      'suman o promedian para determinar el ganador por equipo.',
  'docs.types.team.when.title': 'Cuándo usar:',
  'docs.types.team.when.item1': 'Competiciones de clubs o escuelas',
  'docs.types.team.when.item2': 'Eventos por ciudades o regiones',
  'docs.types.team.when.item3': 'Campeonatos donde quieres fomentar el espíritu de equipo',
  'docs.types.team.when.item4': 'Formatos relay o relevos',
  'docs.types.team.example.title': 'Ejemplo práctico:',
  'docs.types.team.example.content':
      'Una competición entre clubs de BMX donde cada club presenta 5 riders. '
      'La suma de las 3 mejores puntuaciones individuales determina el ganador por equipo.',

  // Both
  'docs.types.both.title': 'Ambos (Individual + Equipos)',
  'docs.types.both.badge': 'Recomendado para eventos grandes',
  'docs.types.both.description':
      'Combina los dos formatos: se otorgan premios tanto a nivel individual como por equipo. '
      'Cada atleta compite individualmente pero también contribuye al puntaje de su equipo.',
  'docs.types.both.when.title': 'Cuándo usar:',
  'docs.types.both.when.item1': 'Eventos grandes con múltiples categorías',
  'docs.types.both.when.item2': 'Campeonatos nacionales o internacionales',
  'docs.types.both.when.item3': 'Cuando quieres maximizar la emoción y participación',
  'docs.types.both.when.item4': 'Eventos donde clubs y atletas quieren destacar',
  'docs.types.both.example.title': 'Ejemplo práctico:',
  'docs.types.both.example.content':
      'Un campeonato nacional de scooter con clasificación individual para el podio personal '
      'y clasificación por equipos para el premio al mejor club del país.',

  'docs.types.tip.title': 'Consejo:',
  'docs.types.tip.content':
      'Si es tu primera competición, empieza con formato Individual. Es más simple de gestionar '
      'y los participantes lo entienden mejor. Puedes escalar a formatos más complejos con experiencia.',

  // ============================================================================
  // FORMATS - FORMATOS DE COMPETICIÓN
  // ============================================================================
  'docs.formats.title': 'Formatos de Competición',
  'docs.formats.subtitle': 'Diferentes mecánicas para diferentes tipos de eventos',

  // Championship
  'docs.formats.championship.title': 'Championship (Campeonato)',
  'docs.formats.championship.icon': '🏆',
  'docs.formats.championship.definition':
      'Un campeonato es un evento donde todos los participantes compiten en las mismas condiciones '
      'y el ganador se determina por la mejor puntuación acumulada a lo largo de varias rondas.',
  'docs.formats.championship.mechanics.title': 'Cómo funciona:',
  'docs.formats.championship.mechanics.item1': 'Todos compiten en todas las rondas',
  'docs.formats.championship.mechanics.item2': 'Las puntuaciones se acumulan o se promedian',
  'docs.formats.championship.mechanics.item3': 'Puede incluir: calificación, semifinales y final',
  'docs.formats.championship.mechanics.item4': 'Ganador: quien tenga la mejor puntuación total/promedio',
  'docs.formats.championship.when.title': 'Cuándo usar:',
  'docs.formats.championship.when.item1': 'Competiciones de Street/Park tradicionales',
  'docs.formats.championship.when.item2': 'Cuando quieres que todos tengan las mismas oportunidades',
  'docs.formats.championship.when.item3': 'Eventos de 1 día con múltiples runs',
  'docs.formats.championship.example.title': 'Ejemplo:',
  'docs.formats.championship.example.content':
      'Un campeonato de inline park con 2 rondas calificatorias (se cuenta la mejor), '
      'una semifinal con los top 12, y una final con los top 6. La mejor puntuación en la final gana.',
  'docs.formats.championship.tips.title': 'Tips:',
  'docs.formats.championship.tips.item1': 'Define claramente cuántos runs cuenta cada participante',
  'docs.formats.championship.tips.item2': 'Considera eliminar la puntuación más baja si hay muchas rondas',
  'docs.formats.championship.tips.item3': 'Asegúrate de comunicar si las rondas previas cuentan o no para el final',

  // Tournament
  'docs.formats.tournament.title': 'Tournament (Torneo)',
  'docs.formats.tournament.icon': '⚔️',
  'docs.formats.tournament.definition':
      'Un torneo es una serie de competiciones independientes donde los participantes acumulan '
      'puntos a lo largo de múltiples eventos para determinar un campeón de temporada.',
  'docs.formats.tournament.mechanics.title': 'Cómo funciona:',
  'docs.formats.tournament.mechanics.item1': 'Múltiples competiciones (fechas) en diferentes lugares',
  'docs.formats.tournament.mechanics.item2': 'Sistema de puntos por posición (ej: 1º=25pts, 2º=20pts)',
  'docs.formats.tournament.mechanics.item3': 'Ranking acumulativo a lo largo de la temporada',
  'docs.formats.tournament.mechanics.item4': 'Puede incluir "drops" (descartar peores resultados)',
  'docs.formats.tournament.when.title': 'Cuándo usar:',
  'docs.formats.tournament.when.item1': 'Series de competiciones a lo largo de varios meses',
  'docs.formats.tournament.when.item2': 'Circuitos nacionales o regionales',
  'docs.formats.tournament.when.item3': 'Cuando quieres mantener engagement durante toda una temporada',
  'docs.formats.tournament.example.title': 'Ejemplo:',
  'docs.formats.tournament.example.content':
      'Copa Nacional de BMX Street con 6 fechas en diferentes ciudades. Los riders acumulan puntos '
      'en cada fecha. Al final de la temporada, el campeón es quien más puntos tenga (contando 5 de 6 fechas).',
  'docs.formats.tournament.tips.title': 'Tips:',
  'docs.formats.tournament.tips.item1': 'Define un sistema de puntos claro y transparente',
  'docs.formats.tournament.tips.item2': 'Considera permitir "drops" para que los atletas puedan perderse una fecha',
  'docs.formats.tournament.tips.item3': 'Comunica el calendario completo al inicio de la temporada',

  // Single Race
  'docs.formats.single.race.title': 'Single Race (Carrera Única)',
  'docs.formats.single.race.icon': '🏁',
  'docs.formats.single.race.definition':
      'Una carrera individual donde los participantes compiten simultáneamente en un circuito '
      'y el ganador se determina por quien cruce la meta primero o en el menor tiempo.',
  'docs.formats.single.race.mechanics.title': 'Cómo funciona:',
  'docs.formats.single.race.mechanics.item1': 'Todos inician al mismo tiempo o en heats clasificatorios',
  'docs.formats.single.race.mechanics.item2': 'Ganador: primer lugar o mejor tiempo',
  'docs.formats.single.race.mechanics.item3': 'Puede tener eliminatorias previas si hay muchos participantes',
  'docs.formats.single.race.when.title': 'Cuándo usar:',
  'docs.formats.single.race.when.item1': 'Carreras en circuitos cerrados',
  'docs.formats.single.race.when.item2': 'Downhill o descensos',
  'docs.formats.single.race.when.item3': 'Eventos cortos con alta intensidad',
  'docs.formats.single.race.example.title': 'Ejemplo:',
  'docs.formats.single.race.example.content':
      'Una carrera de inline downhill en una calle cerrada. Los riders bajan de 3 en 3, '
      'se cronometran, y el mejor tiempo gana. Clasificación previa para definir el orden de salida.',
  'docs.formats.single.race.tips.title': 'Tips:',
  'docs.formats.single.race.tips.item1': 'Asegura sistemas de cronometraje precisos',
  'docs.formats.single.race.tips.item2': 'Define claramente las reglas de salidas falsas',
  'docs.formats.single.race.tips.item3': 'Considera heats clasificatorios para gestionar muchos participantes',

  // Time Trial
  'docs.formats.time.trial.title': 'Time Trial (Contrarreloj)',
  'docs.formats.time.trial.icon': '⏱️',
  'docs.formats.time.trial.definition':
      'Los participantes completan el recorrido individualmente (no simultáneamente) y el ganador '
      'es quien logre el mejor tiempo. Es pura velocidad contra el reloj.',
  'docs.formats.time.trial.mechanics.title': 'Cómo funciona:',
  'docs.formats.time.trial.mechanics.item1': 'Cada participante sale individualmente',
  'docs.formats.time.trial.mechanics.item2': 'Se cronometra desde la salida hasta la meta',
  'docs.formats.time.trial.mechanics.item3': 'Sin interferencia directa entre competidores',
  'docs.formats.time.trial.mechanics.item4': 'Ganador: menor tiempo',
  'docs.formats.time.trial.when.title': 'Cuándo usar:',
  'docs.formats.time.trial.when.item1': 'Cuando la pista no permite carreras múltiples simultáneas',
  'docs.formats.time.trial.when.item2': 'Eventos donde la técnica individual importa más que la táctica de carrera',
  'docs.formats.time.trial.when.item3': 'Circuitos técnicos donde contacto físico sería peligroso',
  'docs.formats.time.trial.example.title': 'Ejemplo:',
  'docs.formats.time.trial.example.content':
      'Un circuito técnico de BMX Pump Track. Cada rider hace 2 vueltas cronometradas, '
      'y el mejor de los 2 tiempos es su puntuación oficial. El más rápido gana.',
  'docs.formats.time.trial.tips.title': 'Tips:',
  'docs.formats.time.trial.tips.item1': 'Usa cronómetros electrónicos profesionales',
  'docs.formats.time.trial.tips.item2': 'Define si se permite más de un intento',
  'docs.formats.time.trial.tips.item3': 'Establece penalizaciones claras por faltas técnicas',

  // Endurance
  'docs.formats.endurance.title': 'Endurance (Resistencia)',
  'docs.formats.endurance.icon': '💪',
  'docs.formats.endurance.definition':
      'Competiciones de larga duración donde se premia la resistencia física y mental. '
      'El ganador es quien complete más vueltas, mayor distancia, o mejor rendimiento en tiempo extendido.',
  'docs.formats.endurance.mechanics.title': 'Cómo funciona:',
  'docs.formats.endurance.mechanics.item1': 'Duración fija (ej: 1 hora, 3 horas, 24 horas)',
  'docs.formats.endurance.mechanics.item2': 'Ganador: quien más vueltas/distancia complete',
  'docs.formats.endurance.mechanics.item3': 'Puede ser individual o relevos por equipos',
  'docs.formats.endurance.mechanics.item4': 'Pits/paradas permitidas según reglamento',
  'docs.formats.endurance.when.title': 'Cuándo usar:',
  'docs.formats.endurance.when.item1': 'Eventos especiales de resistencia',
  'docs.formats.endurance.when.item2': 'Maratones o ultra-distancias',
  'docs.formats.endurance.when.item3': 'Cuando quieres probar la resistencia más que velocidad pura',
  'docs.formats.endurance.example.title': 'Ejemplo:',
  'docs.formats.endurance.example.content':
      'Una competición de inline marathon de 42km. Los riders completan el recorrido y el primero '
      'en cruzar la meta gana. También hay premios para top 3 en cada categoría de edad.',
  'docs.formats.endurance.tips.title': 'Tips:',
  'docs.formats.endurance.tips.item1': 'Asegura puntos de hidratación y asistencia médica',
  'docs.formats.endurance.tips.item2': 'Comunica claramente las reglas de equipamiento permitido',
  'docs.formats.endurance.tips.item3': 'Considera categorías por edad y género para mayor inclusividad',

  // Knockout
  'docs.formats.knockout.title': 'Knockout (Eliminatoria)',
  'docs.formats.knockout.icon': '🥊',
  'docs.formats.knockout.definition':
      'Sistema de eliminación directa donde los participantes se enfrentan en duelos o heats. '
      'Los ganadores avanzan, los perdedores quedan eliminados. Es el formato más dramático.',
  'docs.formats.knockout.mechanics.title': 'Cómo funciona:',
  'docs.formats.knockout.mechanics.item1': 'Enfrentamientos directos (1v1, 2v2, etc.)',
  'docs.formats.knockout.mechanics.item2': 'Ganadores avanzan a la siguiente ronda',
  'docs.formats.knockout.mechanics.item3': 'Perdedores quedan eliminados (o van a "repechaje")',
  'docs.formats.knockout.mechanics.item4': 'Final: último enfrentamiento para determinar campeón',
  'docs.formats.knockout.when.title': 'Cuándo usar:',
  'docs.formats.knockout.when.item1': 'Cuando quieres máxima emoción y drama',
  'docs.formats.knockout.when.item2': 'Competiciones de "GAME" o "battles"',
  'docs.formats.knockout.when.item3': 'Eventos con tiempo limitado y muchos participantes',
  'docs.formats.knockout.when.item4': 'Formatos de espectáculo para público',
  'docs.formats.knockout.example.title': 'Ejemplo:',
  'docs.formats.knockout.example.content':
      'Un torneo de BMX Flatland estilo "battle". Los riders se enfrentan de 2 en 2 con runs de '
      '1 minuto. Los jueces eligen un ganador por duelo. Los 16 se convierten en 8, luego 4, semifinales y final.',
  'docs.formats.knockout.tips.title': 'Tips:',
  'docs.formats.knockout.tips.item1': 'Define claramente cómo se decide el ganador de cada duelo',
  'docs.formats.knockout.tips.item2': 'Considera un sistema de "double elimination" para ser más justo',
  'docs.formats.knockout.tips.item3': 'Usa brackets visuales para que los participantes vean el avance',

  'docs.formats.comparison.title': 'Comparación Rápida',
  'docs.formats.comparison.header.format': 'Formato',
  'docs.formats.comparison.header.duration': 'Duración',
  'docs.formats.comparison.header.complexity': 'Complejidad',
  'docs.formats.comparison.header.best.for': 'Mejor para',

  // ============================================================================
  // ROLES - ROLES Y PERMISOS
  // ============================================================================
  'docs.roles.title': 'Roles y Permisos',
  'docs.roles.subtitle': 'Quién hace qué en una competición',

  // Organizer
  'docs.roles.organizer.title': 'Organizador',
  'docs.roles.organizer.icon': '👤',
  'docs.roles.organizer.description':
      'El organizador es quien crea y gestiona la competición. Tiene control total sobre todos '
      'los aspectos del evento y es responsable de su éxito.',
  'docs.roles.organizer.responsibilities.title': 'Responsabilidades:',
  'docs.roles.organizer.responsibilities.item1': 'Crear y configurar la competición (formato, categorías, fechas)',
  'docs.roles.organizer.responsibilities.item2': 'Invitar y gestionar jueces',
  'docs.roles.organizer.responsibilities.item3': 'Aprobar o rechazar participantes (si requiere aprobación)',
  'docs.roles.organizer.responsibilities.item4': 'Configurar criterios de puntuación',
  'docs.roles.organizer.responsibilities.item5': 'Iniciar, pausar y finalizar la competición',
  'docs.roles.organizer.responsibilities.item6': 'Publicar resultados oficiales',
  'docs.roles.organizer.permissions.title': 'Permisos:',
  'docs.roles.organizer.permissions.item1': 'Editar todos los detalles de la competición',
  'docs.roles.organizer.permissions.item2': 'Eliminar la competición',
  'docs.roles.organizer.permissions.item3': 'Ver todas las puntuaciones (incluso antes de publicar)',
  'docs.roles.organizer.permissions.item4': 'Modificar o corregir puntuaciones (con historial)',
  'docs.roles.organizer.permissions.item5': 'Acceso completo al panel de gestión',
  'docs.roles.organizer.best.practices.title': 'Mejores prácticas:',
  'docs.roles.organizer.best.practices.item1': 'Configura todo con anticipación (al menos 1 semana antes)',
  'docs.roles.organizer.best.practices.item2': 'Comunica claramente el reglamento a participantes y jueces',
  'docs.roles.organizer.best.practices.item3': 'Haz una reunión de jueces antes de iniciar',
  'docs.roles.organizer.best.practices.item4': 'Ten un plan B para problemas técnicos',
  'docs.roles.organizer.best.practices.item5': 'Publica resultados rápidamente después del evento',

  // Speaker (Controller)
  'docs.roles.speaker.title': 'Speaker (Controlador en Vivo)',
  'docs.roles.speaker.icon': '🎤',
  'docs.roles.speaker.description':
      'El speaker es quien controla el flujo de la competición en tiempo real durante el evento. '
      'Es como el "maestro de ceremonias" técnico del evento.',
  'docs.roles.speaker.responsibilities.title': 'Responsabilidades:',
  'docs.roles.speaker.responsibilities.item1': 'Gestionar el orden de participación (heats)',
  'docs.roles.speaker.responsibilities.item2': 'Anunciar a los atletas que están por competir',
  'docs.roles.speaker.responsibilities.item3': 'Controlar el inicio y fin de cada heat/run',
  'docs.roles.speaker.responsibilities.item4': 'Coordinar con jueces para asegurar que todos califiquen',
  'docs.roles.speaker.responsibilities.item5': 'Gestionar emergencias o ajustes en tiempo real',
  'docs.roles.speaker.permissions.title': 'Permisos:',
  'docs.roles.speaker.permissions.item1': 'Ver dashboard de speaker en vivo',
  'docs.roles.speaker.permissions.item2': 'Avanzar o retroceder heats',
  'docs.roles.speaker.permissions.item3': 'Ver qué jueces han calificado cada run',
  'docs.roles.speaker.permissions.item4': 'Emitir alertas a jueces',
  'docs.roles.speaker.permissions.item5': 'Ver leaderboard en tiempo real',
  'docs.roles.speaker.best.practices.title': 'Mejores prácticas:',
  'docs.roles.speaker.best.practices.item1': 'Llega temprano y verifica que todo funcione',
  'docs.roles.speaker.best.practices.item2': 'Ten una lista impresa de backup por si falla la tecnología',
  'docs.roles.speaker.best.practices.item3': 'Comunícate constantemente con jueces (walkie-talkie o señas)',
  'docs.roles.speaker.best.practices.item4': 'Anuncia claramente quién está compitiendo y quién sigue',
  'docs.roles.speaker.best.practices.item5': 'Mantén el ritmo del evento (evita tiempos muertos)',

  // Judge
  'docs.roles.judge.title': 'Juez',
  'docs.roles.judge.icon': '⚖️',
  'docs.roles.judge.description':
      'Los jueces son quienes califican el desempeño de los atletas según los criterios establecidos. '
      'Son fundamentales para la credibilidad del evento.',
  'docs.roles.judge.responsibilities.title': 'Responsabilidades:',
  'docs.roles.judge.responsibilities.item1': 'Calificar cada atleta según los criterios establecidos',
  'docs.roles.judge.responsibilities.item2': 'Ser imparcial y consistente en sus puntuaciones',
  'docs.roles.judge.responsibilities.item3': 'Estar presente y atento durante toda la competición',
  'docs.roles.judge.responsibilities.item4': 'Comunicar cualquier problema al organizador/speaker',
  'docs.roles.judge.responsibilities.item5': 'Respetar los tiempos de puntuación',
  'docs.roles.judge.permissions.title': 'Permisos:',
  'docs.roles.judge.permissions.item1': 'Acceder al panel de puntuación de juez',
  'docs.roles.judge.permissions.item2': 'Ver la lista de atletas y heats',
  'docs.roles.judge.permissions.item3': 'Ingresar y modificar sus propias puntuaciones',
  'docs.roles.judge.permissions.item4': 'Ver los criterios de evaluación',
  'docs.roles.judge.permissions.item5': 'NO pueden ver puntuaciones de otros jueces (para evitar sesgos)',
  'docs.roles.judge.best.practices.title': 'Mejores prácticas:',
  'docs.roles.judge.best.practices.item1': 'Lee y comprende los criterios ANTES del evento',
  'docs.roles.judge.best.practices.item2': 'Asiste a la reunión de jueces pre-competición',
  'docs.roles.judge.best.practices.item3': 'Calibra tus puntuaciones con otros jueces en calentamiento',
  'docs.roles.judge.best.practices.item4': 'Sé consistente: mismos criterios para todos los atletas',
  'docs.roles.judge.best.practices.item5': 'Usa todo el rango de puntuación (no solo 7-9)',
  'docs.roles.judge.requirements.title': 'Requisitos típicos:',
  'docs.roles.judge.requirements.item1': 'Mínimo 3 jueces por categoría (recomendado 5)',
  'docs.roles.judge.requirements.item2': 'Experiencia en la disciplina',
  'docs.roles.judge.requirements.item3': 'Disponibilidad durante todo el evento',
  'docs.roles.judge.requirements.item4': 'Dispositivo con conexión a internet',

  // Participant
  'docs.roles.participant.title': 'Participante',
  'docs.roles.participant.icon': '🏃',
  'docs.roles.participant.description':
      'Los participantes son los atletas que compiten en el evento. Pueden ser riders, bikers, '
      'skaters o scooterers según la disciplina.',
  'docs.roles.participant.responsibilities.title': 'Responsabilidades:',
  'docs.roles.participant.responsibilities.item1': 'Registrarse antes de la fecha límite',
  'docs.roles.participant.responsibilities.item2': 'Presentar documentación requerida (si aplica)',
  'docs.roles.participant.responsibilities.item3': 'Estar presente en el check-in el día del evento',
  'docs.roles.participant.responsibilities.item4': 'Competir en su turno asignado',
  'docs.roles.participant.responsibilities.item5': 'Respetar el reglamento y decisiones de jueces',
  'docs.roles.participant.permissions.title': 'Permisos:',
  'docs.roles.participant.permissions.item1': 'Ver detalles completos de la competición',
  'docs.roles.participant.permissions.item2': 'Registrarse o cancelar registro (según fechas)',
  'docs.roles.participant.permissions.item3': 'Ver su propio horario y categoría',
  'docs.roles.participant.permissions.item4': 'Ver el leaderboard (si está público)',
  'docs.roles.participant.permissions.item5': 'Ver sus propias puntuaciones detalladas',
  'docs.roles.participant.best.practices.title': 'Mejores prácticas:',
  'docs.roles.participant.best.practices.item1': 'Lee el reglamento completo antes de registrarte',
  'docs.roles.participant.best.practices.item2': 'Llega temprano para check-in y calentamiento',
  'docs.roles.participant.best.practices.item3': 'Verifica el equipamiento requerido',
  'docs.roles.participant.best.practices.item4': 'Respeta a jueces, organizadores y otros competidores',
  'docs.roles.participant.best.practices.item5': 'Si tienes dudas, pregunta ANTES de competir',

  // ============================================================================
  // SCORING - SISTEMA DE PUNTUACIÓN
  // ============================================================================
  'docs.scoring.title': 'Sistema de Puntuación',
  'docs.scoring.subtitle': 'Cómo configurar y entender la evaluación de atletas',

  'docs.scoring.overview.title': 'Visión General',
  'docs.scoring.overview.content':
      'El sistema de puntuación de StreetCore es flexible y permite diferentes métodos de evaluación '
      'según el tipo de competición. Cada método tiene sus propias reglas de cálculo y es ideal para '
      'diferentes escenarios.',

  // Points
  'docs.scoring.points.title': 'Points (Puntos)',
  'docs.scoring.points.icon': '💯',
  'docs.scoring.points.definition':
      'El método más tradicional. Los jueces asignan una puntuación numérica basada en criterios '
      'específicos. Es el sistema estándar para deportes de estilo y técnica.',
  'docs.scoring.points.how.title': 'Cómo funciona:',
  'docs.scoring.points.how.item1': 'Defines un rango (ej: 0-100, 0-10)',
  'docs.scoring.points.how.item2': 'Defines criterios de evaluación con pesos (ej: técnica 40%, estilo 30%, dificultad 30%)',
  'docs.scoring.points.how.item3': 'Cada juez califica según estos criterios',
  'docs.scoring.points.how.item4': 'Las puntuaciones se promedian entre jueces',
  'docs.scoring.points.how.item5': 'Opcionalmente se elimina la más alta y más baja',
  'docs.scoring.points.when.title': 'Cuándo usar:',
  'docs.scoring.points.when.item1': 'Street, park, flatland, y disciplinas de estilo',
  'docs.scoring.points.when.item2': 'Cuando evalúas aspectos subjetivos',
  'docs.scoring.points.when.item3': 'Competiciones tipo "show" o "demo"',
  'docs.scoring.points.criteria.title': 'Criterios típicos:',
  'docs.scoring.points.criteria.item1': 'Técnica: ejecución y precisión de trucos',
  'docs.scoring.points.criteria.item2': 'Dificultad: complejidad de los trucos',
  'docs.scoring.points.criteria.item3': 'Estilo: fluidez y originalidad',
  'docs.scoring.points.criteria.item4': 'Variedad: diversidad de trucos',
  'docs.scoring.points.criteria.item5': 'Uso del espacio: aprovechamiento del área',
  'docs.scoring.points.example.title': 'Ejemplo:',
  'docs.scoring.points.example.content':
      'Un rider hace su run de 2 minutos. 5 jueces califican de 0-100. Las puntuaciones son: '
      '85, 88, 92, 87, 86. Se elimina la más alta (92) y la más baja (85). '
      'Promedio de 88, 87, 86 = 87.0 puntos.',
  'docs.scoring.points.config.title': 'Configuración recomendada:',
  'docs.scoring.points.config.item1': 'Rango: 0-100 (permite más granularidad)',
  'docs.scoring.points.config.item2': 'Mínimo 3 jueces, ideal 5',
  'docs.scoring.points.config.item3': 'Elimina mayor y menor si hay 5+ jueces',
  'docs.scoring.points.config.item4': 'Define 3-5 criterios con pesos claros',

  // Time
  'docs.scoring.time.title': 'Time (Tiempo)',
  'docs.scoring.time.icon': '⏱️',
  'docs.scoring.time.definition':
      'El ganador se determina por tiempo. Más rápido = mejor. Simple, objetivo y sin subjetividad.',
  'docs.scoring.time.how.title': 'Cómo funciona:',
  'docs.scoring.time.how.item1': 'Se cronometra a cada participante',
  'docs.scoring.time.how.item2': 'El menor tiempo gana',
  'docs.scoring.time.how.item3': 'Pueden existir penalizaciones por faltas (tiempo añadido)',
  'docs.scoring.time.how.item4': 'No se requieren jueces (solo cronometraje)',
  'docs.scoring.time.when.title': 'Cuándo usar:',
  'docs.scoring.time.when.item1': 'Carreras y time trials',
  'docs.scoring.time.when.item2': 'Cuando la velocidad es el objetivo principal',
  'docs.scoring.time.when.item3': 'Competiciones donde la objetividad es crítica',
  'docs.scoring.time.example.title': 'Ejemplo:',
  'docs.scoring.time.example.content':
      'Un circuito de downhill. Los riders bajan uno por uno y se cronometran. '
      'Rider A: 1:23.45, Rider B: 1:22.10, Rider C: 1:24.00. Rider B gana.',
  'docs.scoring.time.config.title': 'Configuración recomendada:',
  'docs.scoring.time.config.item1': 'Sistema de cronometraje electrónico',
  'docs.scoring.time.config.item2': 'Define penalizaciones por faltas (ej: +5s por salto de puerta)',
  'docs.scoring.time.config.item3': 'Permite múltiples intentos y cuenta el mejor',
  'docs.scoring.time.config.item4': 'Backup manual por si falla el cronómetro',

  // Average
  'docs.scoring.average.title': 'Average (Promedio)',
  'docs.scoring.average.icon': '📊',
  'docs.scoring.average.definition':
      'Se promedian las puntuaciones de múltiples runs o rondas. Premia la consistencia más que un run perfecto.',
  'docs.scoring.average.how.title': 'Cómo funciona:',
  'docs.scoring.average.how.item1': 'Cada run recibe una puntuación',
  'docs.scoring.average.how.item2': 'Se calcula el promedio de todos los runs',
  'docs.scoring.average.how.item3': 'Ganador: mayor promedio',
  'docs.scoring.average.how.item4': 'Opcionalmente puedes eliminar el peor run',
  'docs.scoring.average.when.title': 'Cuándo usar:',
  'docs.scoring.average.when.item1': 'Cuando quieres premiar consistencia',
  'docs.scoring.average.when.item2': 'Competiciones con múltiples runs',
  'docs.scoring.average.when.item3': 'Cuando un "fluke" (golpe de suerte) no debería ganar',
  'docs.scoring.average.example.title': 'Ejemplo:',
  'docs.scoring.average.example.content':
      'Competición con 3 runs. Rider A: 80, 85, 90 (promedio 85). '
      'Rider B: 95, 70, 75 (promedio 80). Rider A gana por consistencia.',
  'docs.scoring.average.config.title': 'Configuración recomendada:',
  'docs.scoring.average.config.item1': 'Mínimo 2 runs, ideal 3',
  'docs.scoring.average.config.item2': 'Considera "drop lowest" si hay 3+ runs',
  'docs.scoring.average.config.item3': 'Comunica claramente que todos los runs cuentan',

  // Sum
  'docs.scoring.sum.title': 'Sum (Suma)',
  'docs.scoring.sum.icon': '➕',
  'docs.scoring.sum.definition':
      'Se suman las puntuaciones de todas las rondas. Premia el rendimiento acumulativo total.',
  'docs.scoring.sum.how.title': 'Cómo funciona:',
  'docs.scoring.sum.how.item1': 'Cada run/ronda recibe una puntuación',
  'docs.scoring.sum.how.item2': 'Se suman todas las puntuaciones',
  'docs.scoring.sum.how.item3': 'Ganador: mayor suma total',
  'docs.scoring.sum.how.item4': 'Similar a average pero escala con número de rondas',
  'docs.scoring.sum.when.title': 'Cuándo usar:',
  'docs.scoring.sum.when.item1': 'Torneos multi-fecha',
  'docs.scoring.sum.when.item2': 'Cuando quieres que cada run aporte al total',
  'docs.scoring.sum.when.item3': 'Sistemas de puntos por posición',
  'docs.scoring.sum.example.title': 'Ejemplo:',
  'docs.scoring.sum.example.content':
      'Torneo con 4 fechas. Sistema: 1º=25pts, 2º=20pts, 3º=16pts. '
      'Rider A termina: 1º, 3º, 2º, 1º = 25+16+20+25 = 86pts. Total suma decide campeón.',
  'docs.scoring.sum.config.title': 'Configuración recomendada:',
  'docs.scoring.sum.config.item1': 'Define claramente la escala de puntos',
  'docs.scoring.sum.config.item2': 'Considera "drops" (descartar peores resultados)',
  'docs.scoring.sum.config.item3': 'Útil para rankings de temporada',

  // Weighted Average
  'docs.scoring.weighted.title': 'Weighted Average (Promedio Ponderado)',
  'docs.scoring.weighted.icon': '⚖️',
  'docs.scoring.weighted.definition':
      'Similar al promedio, pero algunas rondas valen más que otras. Ideal cuando la final es más importante.',
  'docs.scoring.weighted.how.title': 'Cómo funciona:',
  'docs.scoring.weighted.how.item1': 'Cada ronda tiene un peso/multiplicador',
  'docs.scoring.weighted.how.item2': 'Puntuaciones se multiplican por su peso',
  'docs.scoring.weighted.how.item3': 'Se calcula promedio ponderado',
  'docs.scoring.weighted.how.item4': 'Ganador: mayor promedio ponderado',
  'docs.scoring.weighted.when.title': 'Cuándo usar:',
  'docs.scoring.weighted.when.item1': 'Cuando la final vale más que calificación',
  'docs.scoring.weighted.when.item2': 'Torneos donde fechas importantes valen más',
  'docs.scoring.weighted.when.item3': 'Sistemas complejos de ranking',
  'docs.scoring.weighted.example.title': 'Ejemplo:',
  'docs.scoring.weighted.example.content':
      'Competición: Calificación (peso 0.3), Semifinal (peso 0.3), Final (peso 0.4). '
      'Rider A: 80 en quali, 85 en semi, 90 en final. '
      'Puntaje: (80×0.3)+(85×0.3)+(90×0.4) = 85.5',
  'docs.scoring.weighted.config.title': 'Configuración recomendada:',
  'docs.scoring.weighted.config.item1': 'Define pesos ANTES del evento',
  'docs.scoring.weighted.config.item2': 'Comunica claramente qué rondas valen más',
  'docs.scoring.weighted.config.item3': 'Final típicamente peso 0.4-0.5',

  'docs.scoring.drops.title': 'Drop Scores (Eliminar Puntuaciones)',
  'docs.scoring.drops.content':
      'Puedes configurar que se elimine la puntuación más alta y/o más baja de cada juez. '
      'Esto reduce el impacto de puntuaciones extremas y hace el sistema más justo.',
  'docs.scoring.drops.when': 'Recomendado cuando tienes 5 o más jueces.',

  'docs.scoring.criteria.title': 'Configuración de Criterios',
  'docs.scoring.criteria.subtitle': 'Cómo definir qué se evalúa',
  'docs.scoring.criteria.content':
      'Los criterios son los aspectos específicos que los jueces evalúan. Cada criterio tiene un nombre, '
      'descripción y peso. El peso determina cuánto contribuye al puntaje final.',
  'docs.scoring.criteria.example.title': 'Ejemplo de configuración:',
  'docs.scoring.criteria.example.item1': 'Técnica (40%): Ejecución limpia de trucos',
  'docs.scoring.criteria.example.item2': 'Dificultad (30%): Complejidad de trucos',
  'docs.scoring.criteria.example.item3': 'Estilo (20%): Originalidad y fluidez',
  'docs.scoring.criteria.example.item4': 'Uso del área (10%): Aprovechamiento del espacio',

  // ============================================================================
  // WORKFLOW - FLUJO COMPLETO
  // ============================================================================
  'docs.workflow.title': 'Flujo Completo de una Competición',
  'docs.workflow.subtitle': 'Desde la creación hasta los resultados finales',

  // Phase 1: Planning
  'docs.workflow.phase1.title': 'Fase 1: Planificación',
  'docs.workflow.phase1.subtitle': '2-4 semanas antes del evento',
  'docs.workflow.phase1.step1.title': '1. Crear la competición',
  'docs.workflow.phase1.step1.content':
      'Define todos los detalles básicos: nombre, fecha, lugar, formato, disciplina, tipo. '
      'Sube imágenes atractivas y escribe una descripción clara.',
  'docs.workflow.phase1.step2.title': '2. Configurar categorías',
  'docs.workflow.phase1.step2.content':
      'Crea las categorías de participación (ej: Principiante, Intermedio, Avanzado, Pro). '
      'Define rangos de edad y nivel de habilidad para cada una.',
  'docs.workflow.phase1.step3.title': '3. Definir criterios de puntuación',
  'docs.workflow.phase1.step3.content':
      'Establece cómo se calificarán los atletas: tipo de scoring (points/time), '
      'criterios específicos y sus pesos.',
  'docs.workflow.phase1.step4.title': '4. Invitar jueces',
  'docs.workflow.phase1.step4.content':
      'Envía invitaciones a jueces experimentados. Asegúrate de tener al menos el mínimo requerido '
      'confirmado antes del evento.',
  'docs.workflow.phase1.step5.title': '5. Abrir inscripciones',
  'docs.workflow.phase1.step5.content':
      'Publica la competición y permite que los atletas se registren. Define si requiere aprobación '
      'o es inscripción abierta.',

  // Phase 2: Pre-Event
  'docs.workflow.phase2.title': 'Fase 2: Pre-Evento',
  'docs.workflow.phase2.subtitle': '1 semana antes del evento',
  'docs.workflow.phase2.step1.title': '1. Revisar inscripciones',
  'docs.workflow.phase2.step1.content':
      'Aprueba o rechaza participantes si tienes aprobación activada. Contacta a los registrados '
      'con detalles finales.',
  'docs.workflow.phase2.step2.title': '2. Confirmar jueces',
  'docs.workflow.phase2.step2.content':
      'Verifica que todos los jueces confirmaron su asistencia. Busca reemplazos si es necesario.',
  'docs.workflow.phase2.step3.title': '3. Comunicar detalles',
  'docs.workflow.phase2.step3.content':
      'Envía información logística a participantes: horarios, check-in, equipamiento requerido, '
      'reglamento detallado.',
  'docs.workflow.phase2.step4.title': '4. Preparar infraestructura',
  'docs.workflow.phase2.step4.content':
      'Asegúrate de tener: buena conexión WiFi, dispositivos para jueces, pantallas para mostrar '
      'resultados en vivo, sistema de sonido.',

  // Phase 3: Event Day
  'docs.workflow.phase3.title': 'Fase 3: Día del Evento',
  'docs.workflow.phase3.subtitle': 'El gran día',
  'docs.workflow.phase3.step1.title': '1. Check-in de participantes',
  'docs.workflow.phase3.step1.content':
      'Registra la llegada de cada participante. Verifica documentación y equipamiento.',
  'docs.workflow.phase3.step2.title': '2. Reunión de jueces',
  'docs.workflow.phase3.step2.content':
      'Realiza una calibración con los jueces. Asegúrate de que todos entienden los criterios '
      'y el proceso de puntuación.',
  'docs.workflow.phase3.step3.title': '3. Iniciar la competición',
  'docs.workflow.phase3.step3.content':
      'Cambia el estado a "Live". Los jueces pueden ahora ingresar puntuaciones. '
      'El speaker controla el flujo de heats.',
  'docs.workflow.phase3.step4.title': '4. Gestión en vivo',
  'docs.workflow.phase3.step4.content':
      'El speaker anuncia atletas, controla heats. Los jueces califican en tiempo real. '
      'Monitorea que todo fluya correctamente.',
  'docs.workflow.phase3.step5.title': '5. Manejo de imprevistos',
  'docs.workflow.phase3.step5.content':
      'Si hay problemas (lesiones, protestas, errores), pausa el heat, resuelve y continúa. '
      'El sistema guarda todo.',

  // Phase 4: Post-Event
  'docs.workflow.phase4.title': 'Fase 4: Post-Evento',
  'docs.workflow.phase4.subtitle': 'Después de la competición',
  'docs.workflow.phase4.step1.title': '1. Revisar resultados',
  'docs.workflow.phase4.step1.content':
      'Verifica que todos los atletas fueron calificados correctamente. '
      'Corrige cualquier error antes de publicar.',
  'docs.workflow.phase4.step2.title': '2. Publicar resultados',
  'docs.workflow.phase4.step2.content':
      'Marca los resultados como "Publicados". Esto hace el leaderboard oficial visible para todos.',
  'docs.workflow.phase4.step3.title': '3. Premiación',
  'docs.workflow.phase4.step3.content':
      'Realiza la ceremonia de premiación. Usa el podio generado automáticamente por el sistema.',
  'docs.workflow.phase4.step4.title': '4. Finalizar evento',
  'docs.workflow.phase4.step4.content':
      'Cambia el estado a "Completed". Sube fotos/videos highlights. Agradece a todos.',
  'docs.workflow.phase4.step5.title': '5. Feedback',
  'docs.workflow.phase4.step5.content':
      'Recopila feedback de participantes y jueces para mejorar futuros eventos.',

  'docs.workflow.timeline.title': 'Timeline sugerida',
  'docs.workflow.timeline.week4': '4 semanas antes: Crear competición + abrir inscripciones',
  'docs.workflow.timeline.week3': '3 semanas antes: Invitar jueces',
  'docs.workflow.timeline.week2': '2 semanas antes: Recordatorio inscripciones',
  'docs.workflow.timeline.week1': '1 semana antes: Cerrar inscripciones + confirmar jueces',
  'docs.workflow.timeline.day1': '1 día antes: Comunicación final a todos',
  'docs.workflow.timeline.day0': 'Día del evento: Check-in + competición + resultados',
  'docs.workflow.timeline.day.after': '1 día después: Publicar highlights y agradecer',

  // ============================================================================
  // FAQ - PREGUNTAS FRECUENTES
  // ============================================================================
  'docs.faq.title': 'Preguntas Frecuentes',
  'docs.faq.subtitle': 'Respuestas a las dudas más comunes',

  'docs.faq.q1.question': '¿Cuántos jueces necesito para mi competición?',
  'docs.faq.q1.answer':
      'El mínimo recomendado es 3 jueces, pero idealmente deberías tener 5. '
      'Con 5 jueces puedes eliminar la puntuación más alta y más baja, haciendo el sistema más justo. '
      'Para eventos grandes, considera tener jueces de respaldo.',

  'docs.faq.q2.question': '¿Puedo cambiar los criterios después de crear la competición?',
  'docs.faq.q2.answer':
      'Sí, puedes modificar criterios ANTES de iniciar la competición. Una vez que cambias '
      'el estado a "Live" y los jueces empiezan a calificar, ya no puedes cambiar criterios '
      'para mantener la integridad de las puntuaciones.',

  'docs.faq.q3.question': '¿Qué pasa si un juez pierde conexión durante la competición?',
  'docs.faq.q3.answer':
      'El sistema tiene modo offline. Las puntuaciones se guardan localmente y se sincronizan '
      'automáticamente cuando la conexión se restablece. El juez puede seguir calificando sin problemas.',

  'docs.faq.q4.question': '¿Puedo tener categorías con diferentes sistemas de puntuación?',
  'docs.faq.q4.answer':
      'Sí, cada categoría puede tener su propio sistema de puntuación. Por ejemplo, puedes tener '
      'la categoría Pro con criterios más estrictos y la categoría Principiante con criterios más simples.',

  'docs.faq.q5.question': '¿Cómo manejo las protestas o correcciones de puntuaciones?',
  'docs.faq.q5.answer':
      'Como organizador, puedes modificar puntuaciones después de que los jueces las ingresen. '
      'Todas las modificaciones quedan registradas en el historial para transparencia. '
      'Establece un tiempo límite para protestas (ej: 15 min después del run).',

  'docs.faq.q6.question': '¿Los resultados se actualizan en tiempo real?',
  'docs.faq.q6.answer':
      'Sí, si activas "Show Live Results", el leaderboard se actualiza automáticamente cada vez '
      'que un juez ingresa una puntuación. Los espectadores y participantes pueden ver los resultados en vivo.',

  'docs.faq.q7.question': '¿Puedo limitar el número de participantes?',
  'docs.faq.q7.answer':
      'Sí, puedes establecer un número máximo de participantes. Una vez alcanzado ese número, '
      'los nuevos registros entran en lista de espera automáticamente.',

  'docs.faq.q8.question': '¿Necesito aprobar manualmente cada participante?',
  'docs.faq.q8.answer':
      'Es opcional. Puedes activar "Requiere Aprobación" si quieres revisar cada registro, '
      'o dejarlo desactivado para inscripciones automáticas. Útil si quieres verificar nivel o edad.',

  'docs.faq.q9.question': '¿Puedo hacer un evento privado/cerrado?',
  'docs.faq.q9.answer':
      'Sí, puedes configurar tu competición como privada. Solo las personas con el link directo '
      'podrán verla y registrarse. No aparecerá en la lista pública de competiciones.',

  'docs.faq.q10.question': '¿Cómo invito a jueces que no están registrados en StreetCore?',
  'docs.faq.q10.answer':
      'Puedes invitar jueces por email. Ellos recibirán un enlace para crear una cuenta o '
      'iniciar sesión y aceptar la invitación. También puedes añadir "jueces externos" que no necesitan cuenta.',

  'docs.faq.q11.question': '¿Qué pasa si un atleta no se presenta?',
  'docs.faq.q11.answer':
      'Puedes marcar al atleta como "No Show" en el sistema. Esto lo excluye del ranking '
      'pero mantiene su registro para estadísticas. También puedes eliminarlo completamente si lo prefieres.',

  'docs.faq.q12.question': '¿Puedo reprogramar una competición?',
  'docs.faq.q12.answer':
      'Sí, puedes cambiar las fechas mientras la competición esté en estado "Upcoming". '
      'Todos los participantes registrados recibirán una notificación automática del cambio.',

  // ============================================================================
  // BEST PRACTICES - MEJORES PRÁCTICAS
  // ============================================================================
  'docs.best.title': 'Mejores Prácticas',
  'docs.best.subtitle': 'Tips para organizar competiciones exitosas',

  'docs.best.preparation.title': 'Preparación',
  'docs.best.preparation.tip1.title': 'Planifica con anticipación',
  'docs.best.preparation.tip1.content':
      'Crea tu competición al menos 4 semanas antes. Esto da tiempo para que los atletas se enteren, '
      'se registren y hagan planes de viaje.',
  'docs.best.preparation.tip2.title': 'Testea todo antes',
  'docs.best.preparation.tip2.content':
      'Un día antes, verifica: conexión WiFi, dispositivos de jueces, sistema de sonido, '
      'pantallas de visualización. Haz un "dry run" si es posible.',
  'docs.best.preparation.tip3.title': 'Ten un plan B',
  'docs.best.preparation.tip3.content':
      'Prepara listas impresas de participantes y jueces. Si falla la tecnología, '
      'puedes continuar manualmente y cargar datos después.',

  'docs.best.communication.title': 'Comunicación',
  'docs.best.communication.tip1.title': 'Sé transparente',
  'docs.best.communication.tip1.content':
      'Publica el reglamento completo, criterios de puntuación y sistema de ranking ANTES '
      'de abrir inscripciones. Sin sorpresas.',
  'docs.best.communication.tip2.title': 'Updates frecuentes',
  'docs.best.communication.tip2.content':
      'Envía recordatorios a participantes: 1 semana antes, 2 días antes y el día anterior. '
      'Incluye información de check-in y horarios.',
  'docs.best.communication.tip3.title': 'Crea un grupo',
  'docs.best.communication.tip3.content':
      'Considera crear un grupo de WhatsApp o Telegram para comunicación rápida el día del evento. '
      'Útil para cambios de último minuto.',

  'docs.best.judges.title': 'Jueces',
  'docs.best.judges.tip1.title': 'Reunión pre-competición',
  'docs.best.judges.tip1.content':
      'Haz una reunión 30 min antes de empezar. Calibren puntuaciones viendo algunos videos juntos. '
      'Asegúrate de que todos entienden igual los criterios.',
  'docs.best.judges.tip2.title': 'Dispositivos dedicados',
  'docs.best.judges.tip2.content':
      'Idealmente, proporciona tablets o dispositivos dedicados para jueces. '
      'Evita que usen sus teléfonos personales (distracciones).',
  'docs.best.judges.tip3.title': 'Apoyo técnico',
  'docs.best.judges.tip3.content':
      'Designa a una persona para ayudar a jueces con problemas técnicos durante el evento. '
      'No dejes que los jueces resuelvan problemas solos.',

  'docs.best.participants.title': 'Participantes',
  'docs.best.participants.tip1.title': 'Check-in organizado',
  'docs.best.participants.tip1.content':
      'Abre el check-in al menos 1 hora antes de empezar. Verifica documentación, '
      'asigna números de dorsal y resuelve dudas de último minuto.',
  'docs.best.participants.tip2.title': 'Calentamiento',
  'docs.best.participants.tip2.content':
      'Permite tiempo de calentamiento antes de empezar la competición oficial. '
      'Los atletas necesitan familiarizarse con el lugar y calentar músculos.',
  'docs.best.participants.tip3.title': 'Comunicación clara',
  'docs.best.participants.tip3.content':
      'Anuncia claramente el orden de participación. Avisa con 2-3 riders de anticipación '
      'para que se preparen. "On deck" y "In the hole" system.',

  'docs.best.execution.title': 'Ejecución',
  'docs.best.execution.tip1.title': 'Mantén el ritmo',
  'docs.best.execution.tip1.content':
      'Evita tiempos muertos. Si un juez tiene problemas, no pares todo el evento. '
      'Continúa y resuelve después. El ritmo mantiene la energía.',
  'docs.best.execution.tip2.title': 'Transparencia en vivo',
  'docs.best.execution.tip2.content':
      'Si es posible, muestra el leaderboard en pantallas grandes. Los atletas y espectadores '
      'quieren ver las puntuaciones en tiempo real. Genera emoción.',
  'docs.best.execution.tip3.title': 'Protocolo de emergencia',
  'docs.best.execution.tip3.content':
      'Ten un plan claro para lesiones: personal médico, kit de primeros auxilios, '
      'números de emergencia. La seguridad es lo primero.',

  'docs.best.after.title': 'Post-Evento',
  'docs.best.after.tip1.title': 'Resultados rápidos',
  'docs.best.after.tip1.content':
      'Publica los resultados oficiales el mismo día si es posible. '
      'Los atletas quieren compartir sus resultados en redes sociales inmediatamente.',
  'docs.best.after.tip2.title': 'Contenido',
  'docs.best.after.tip2.content':
      'Sube fotos y videos del evento. Etiqueta a participantes y sponsors. '
      'El contenido post-evento mantiene el engagement y promociona futuros eventos.',
  'docs.best.after.tip3.title': 'Agradecimiento',
  'docs.best.after.tip3.content':
      'Envía un mensaje de agradecimiento a todos: participantes, jueces, sponsors, staff. '
      'Reconoce el esfuerzo de todos. Construye comunidad.',
  'docs.best.after.tip4.title': 'Feedback',
  'docs.best.after.tip4.content':
      'Solicita feedback honesto. Envía una encuesta simple: ¿qué estuvo bien? '
      '¿qué mejorar? Usa esos datos para hacer tu próximo evento aún mejor.',

  // ============================================================================
  // FOOTER & MISC
  // ============================================================================
  'docs.need.help.title': '¿Necesitas más ayuda?',
  'docs.need.help.content':
      'Si tienes preguntas específicas que no están cubiertas en esta documentación, '
      'no dudes en contactar a nuestro equipo de soporte.',
  'docs.contact.support': 'Contactar Soporte',
  'docs.join.community': 'Únete a la Comunidad',
  'docs.watch.tutorials': 'Ver Tutoriales en Video',

  'docs.updated': 'Última actualización',
  'docs.version': 'Versión de la documentación',
};
