/// Módulo de traducciones: Ayuda/Guías en español
///
/// Contiene las traducciones para el sistema de ayuda contextual.
const Map<String, String> helpGuideEs = {
  // General
  'help.guide.title': 'Ayuda',
  'help.guide.close': 'Cerrar ayuda',
  'help.guide.dont.show.again': 'No mostrar de nuevo',
  'help.guide.got.it': 'Entendido',
  'help.guide.next': 'Siguiente',
  'help.guide.previous': 'Anterior',
  'help.guide.skip': 'Omitir',
  'help.guide.finish': 'Finalizar',
  'help.guide.step.of': 'Paso {current} de {total}',

  // Competition Create Guide (/competitions/create)
  'help.guide.competition.create.title': 'Consejos para Crear Competiciones',
  'help.guide.competition.create.step1.title': 'Título y Descripción Atractivos',
  'help.guide.competition.create.step1.description':
      'Usa títulos claros y descriptivos. Ejemplo: "Copa Primavera BMX 2026 - Categoría Pro". En la descripción, destaca los premios, el nivel de dificultad y lo que hace única tu competición.',
  'help.guide.competition.create.step2.title': 'Planifica las Fechas con Anticipación',
  'help.guide.competition.create.step2.description':
      'Da al menos 2-3 semanas entre el anuncio y el evento. Esto permite que los atletas se preparen y compartan el evento. Considera fines de semana para mayor asistencia.',
  'help.guide.competition.create.step3.title': 'Estrategia de Precios',
  'help.guide.competition.create.step3.description':
      'Eventos gratuitos atraen más participantes iniciales. Cuotas moderadas (5-15€) filtran a competidores serios. Ofrece descuentos por registro temprano para impulsar inscripciones.',
  'help.guide.competition.create.step4.title': 'El Banner Es Tu Primera Impresión',
  'help.guide.competition.create.step4.description':
      'Usa imágenes de alta calidad (1200x630px mínimo). Incluye el logo del evento, fecha y ubicación visibles. Evita texto ilegible o imágenes genéricas.',
  'help.guide.competition.create.step5.title': 'Reglas Claras = Menos Problemas',
  'help.guide.competition.create.step5.description':
      'Define equipamiento permitido, tiempo de actuación, penalizaciones y proceso de desempate. Las reglas vagas generan conflictos. Incluye política de cancelación y reembolso.',

  // Invite Judges Guide (/competitions/*/judges)
  'help.guide.judges.invite.title': 'Sistema de Jueces Profesional',
  'help.guide.judges.invite.step1.title': 'Cuántos Jueces Necesitas',
  'help.guide.judges.invite.step1.description':
      'Mínimo 3 jueces para eliminar sesgos. Ideal: 5-7 jueces (se descarta la más alta y baja). Competiciones grandes pueden tener jueces por categoría.',
  'help.guide.judges.invite.step2.title': 'Jueces Registrados vs Externos',
  'help.guide.judges.invite.step2.description':
      'Jueces registrados pueden puntuar desde la app en tiempo real. Jueces externos son para invitados sin cuenta. Prioriza jueces registrados para mejor experiencia.',
  'help.guide.judges.invite.step3.title': 'Invitaciones por Email Profesionales',
  'help.guide.judges.invite.step3.description':
      'Incluye detalles del evento, compensación (si aplica), y expectativas. Los jueces reciben link de confirmación. Envía recordatorio 2-3 días antes del evento.',
  'help.guide.judges.invite.step4.title': 'Diversidad en el Panel de Jueces',
  'help.guide.judges.invite.step4.description':
      'Mezcla experiencia: veteranos + jueces jóvenes. Diferentes estilos de puntuación equilibran resultados. Evita conflictos de interés (entrenadores de participantes).',
  'help.guide.judges.invite.step5.title': 'Gestión Durante el Evento',
  'help.guide.judges.invite.step5.description':
      'Verifica que todos los jueces lleguen 30min antes. Haz briefing de criterios. Monitorea la app para asegurar que están puntuando correctamente.',

  // Configure Categories Guide (/competitions/*/categories)
  'help.guide.categories.config.title': 'Diseño de Categorías Efectivo',
  'help.guide.categories.config.step1.title': 'Divide Para No Mezclar Niveles',
  'help.guide.categories.config.step1.description':
      'Principiantes vs Pros = competición desigual. Crea categorías por edad (12-15, 16-18, 18+) y nivel (Rookie, Amateur, Pro). Más categorías = competición más justa.',
  'help.guide.categories.config.step2.title': 'Criterios de Puntuación Objetivos',
  'help.guide.categories.config.step2.description':
      'Define 3-5 criterios máximo: Técnica (40%), Dificultad (30%), Estilo (20%), Ejecución (10%). Pesos diferentes premian lo que importa en cada categoría.',
  'help.guide.categories.config.step3.title': 'Rango de Edad Realista',
  'help.guide.categories.config.step3.description':
      'Evita rangos muy amplios (ej: 10-18). Diferencia de 3-4 años es ideal. Para adultos, usa +18, +30, +40. Verifica documentos de edad si es necesario.',
  'help.guide.categories.config.step4.title': 'Nombres de Categorías Memorables',
  'help.guide.categories.config.step4.description':
      'Evita "Categoría 1, 2, 3". Usa nombres claros: "Juvenil Masculino", "Amateur Femenino", "Pro Open". Los participantes deben identificar rápido dónde compiten.',
  'help.guide.categories.config.step5.title': 'Orden de Competición Estratégico',
  'help.guide.categories.config.step5.description':
      'Empieza con categorías de menores (se cansan rápido). Termina con Pro/Elite (climax del evento). Deja tiempo entre categorías para calentamiento.',

  // Manage Participants Guide (/competitions/*/participants)
  'help.guide.participants.manage.title': 'Gestión Eficiente de Participantes',
  'help.guide.participants.manage.step1.title': 'Aprobación Manual vs Automática',
  'help.guide.participants.manage.step1.description':
      'Aprobación manual: verificas nivel, edad, documentos. Automática: más rápido pero menos control. Eventos competitivos usan manual para asegurar calidad.',
  'help.guide.participants.manage.step2.title': 'Verificación de Documentos',
  'help.guide.participants.manage.step2.description':
      'Para categorías por edad, solicita DNI/pasaporte. Competiciones con premios requieren firma de exención de responsabilidad. Guarda copias digitales.',
  'help.guide.participants.manage.step3.title': 'Comunicación con Participantes',
  'help.guide.participants.manage.step3.description':
      'Envía confirmación inmediata al aprobar. Incluye horario, ubicación exacta, qué traer. Email recordatorio 24h antes con instrucciones de llegada.',
  'help.guide.participants.manage.step4.title': 'Listas de Espera Inteligentes',
  'help.guide.participants.manage.step4.description':
      'Si alcanzas máximo de participantes, activa lista de espera. Notifica automáticamente si alguien cancela. Da 24-48h para confirmar antes de pasar al siguiente.',
  'help.guide.participants.manage.step5.title': 'Check-in el Día del Evento',
  'help.guide.participants.manage.step5.description':
      'Usa esta lista para check-in físico. Marca presentes vs ausentes. Los ausentes liberan cupo para listas de espera en próximos eventos.',

  // Start Competition Guide (/competitions/*)
  'help.guide.competition.start.title': 'Ejecución del Día del Evento',
  'help.guide.competition.start.step1.title': 'Checklist Pre-Inicio (30min antes)',
  'help.guide.competition.start.step1.description':
      'Verifica: ¿Todos los jueces conectados? ¿Participantes confirmados presentes? ¿Categorías en orden correcto? ¿Sistema de puntuación funcionando? Haz prueba rápida.',
  'help.guide.competition.start.step2.title': 'Briefing con Jueces y Atletas',
  'help.guide.competition.start.step2.description':
      'Explica criterios de puntuación a jueces. Aclara dudas. Informa a atletas sobre orden, tiempo permitido, y señales. Todos deben entender las reglas antes de empezar.',
  'help.guide.competition.start.step3.title': 'Monitoreo en Tiempo Real',
  'help.guide.competition.start.step3.description':
      'Observa el panel de gestión constantemente. Detecta jueces que no están puntuando. Verifica que las puntuaciones sean consistentes. Resuelve discrepancias inmediatamente.',
  'help.guide.competition.start.step4.title': 'Manejo de Imprevistos',
  'help.guide.competition.start.step4.description':
      'Lesión de atleta: ten protocolo médico. Juez desconectado: usa puntuación de jueces restantes. Empate: usa criterio de desempate definido en reglas.',
  'help.guide.competition.start.step5.title': 'Publicación de Resultados Oficial',
  'help.guide.competition.start.step5.description':
      'Revisa todas las puntuaciones antes de publicar. Una vez publicado, los cambios generan desconfianza. Anuncia ganadores públicamente. Toma fotos del podio.',

  // Additional utility translations
  'help.guide.available.for.route': 'Ayuda disponible para esta página',
  'help.guide.no.guide.for.route': 'No hay guía disponible para esta página',
};
