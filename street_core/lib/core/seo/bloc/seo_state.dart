part of 'seo_bloc.dart';

class SeoState extends Equatable {
  final String title;
  final String description;

  const SeoState({this.title = '', this.description = ''});

  SeoState copyWith({
    String? title,
    String? description,
  }) {
    return SeoState(
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  @override
  List<Object> get props => [title, description];
}
