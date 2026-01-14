part of 'seo_bloc.dart';

abstract class SeoEvent extends Equatable {
  const SeoEvent();

  @override
  List<Object> get props => [];
}

class UpdateSeoData extends SeoEvent {
  final String title;
  final String description;

  const UpdateSeoData({required this.title, required this.description});

  @override
  List<Object> get props => [title, description];
}

class UpdateSeoForPath extends SeoEvent {
  final String path;

  const UpdateSeoForPath(this.path);

  @override
  List<Object> get props => [path];
}
