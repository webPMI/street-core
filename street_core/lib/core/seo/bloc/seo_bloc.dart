import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'seo_event.dart';
part 'seo_state.dart';

class SeoBloc extends Bloc<SeoEvent, SeoState> {
  SeoBloc() : super(const SeoState()) {
    on<UpdateSeoData>(_onUpdateSeoData);
    on<UpdateSeoForPath>(_onUpdateSeoForPath);
  }

  static final Map<String, Map<String, String>> _seoData = {
    '/': {
      'title': 'Street-Core - Home',
      'description': 'Welcome to Street-Core, the ultimate platform for street sports and culture.',
    },
    '/login': {
      'title': 'Login - Street-Core',
      'description': 'Login to your Street-Core account.',
    },
    '/register': {
      'title': 'Register - Street-Core',
      'description': 'Create a new account on Street-Core.',
    },
    // Add other static routes here
  };

  void _onUpdateSeoData(UpdateSeoData event, Emitter<SeoState> emit) {
    emit(state.copyWith(title: event.title, description: event.description));
  }

  void _onUpdateSeoForPath(UpdateSeoForPath event, Emitter<SeoState> emit) {
    final metadata = _seoData[event.path] ??
        {
          'title': 'Street-Core',
          'description': 'The ultimate platform for street sports and culture.',
        };
    emit(state.copyWith(title: metadata['title'], description: metadata['description']));
  }
}
