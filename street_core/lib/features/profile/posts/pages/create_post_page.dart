// lib/features/profile/posts/pages/create_post_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/core/widgets/my_button.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/helpers/snackbar_helper.dart';
import '../../../../core/lang/locale_keys.dart';
import '../../../../core/router/navigation_service.dart';
import '../../../../core/widgets/my_text.dart';
import '../../../../core/widgets/my_text_form_field.dart';
import '../bloc/create_post_cubit.dart';
import '../bloc/create_post_state.dart';
import '../widgets/media_upload_section.dart';

/// Página para crear un nuevo post
class CreatePostPage extends StatelessWidget {
  const CreatePostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CreatePostCubit>()..startEditing(),
      child: const _CreatePostView(),
    );
  }
}

class _CreatePostView extends StatefulWidget {
  const _CreatePostView();

  @override
  State<_CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<_CreatePostView> {
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.add_photo_alternate),
            const SizedBox(width: 8),
            const MyText(LocaleKeys.createPost),
          ],
        ),
        actions: [
          BlocBuilder<CreatePostCubit, CreatePostState>(
            builder: (context, state) {
              final canSubmit =
                  state is CreatePostEditing && state.mediaFiles.isNotEmpty;
              return IconButton(
                icon: const Icon(Icons.send),
                onPressed: canSubmit
                    ? () => context.read<CreatePostCubit>().createPost()
                    : null,
                tooltip: 'publish',
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<CreatePostCubit, CreatePostState>(
        listener: (context, state) {
          if (state is CreatePostSuccess) {
            SnackBarHelper.showSuccess(context, 'post.created');
            NavigationService().pop(context, true);
          } else if (state is CreatePostError) {
            SnackBarHelper.showError(context, 'post.creation.error');
          }
        },
        builder: (context, state) {
          if (state is CreatePostUploading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: state.progress),
                  const SizedBox(height: 16),
                  MyText(state.message),
                ],
              ),
            );
          }

          if (state is CreatePostSubmitting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  MyText(LocaleKeys.creatingPost),
                ],
              ),
            );
          }

          if (state is! CreatePostEditing) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Media upload section
                MediaUploadSection(
                  selectedFiles: state.mediaFiles,
                  onFilesSelected: (files) {
                    context.read<CreatePostCubit>().addMediaFiles(
                      files.sublist(state.mediaFiles.length),
                    );
                  },
                  onRemoveFile: (index) {
                    context.read<CreatePostCubit>().removeMediaFile(index);
                  },
                ),

                const SizedBox(height: 24),
                // Caption input
                MyTextFormField(
                  controller: _captionController,
                  label: 'what_are_you_thinking',
                  maxLength: 200,
                  maxLines: 3,
                  onChanged: (value) {
                    context.read<CreatePostCubit>().updateCaption(value);
                  },
                ),

                // Character counter
                const SizedBox(height: 4),
                BlocBuilder<CreatePostCubit, CreatePostState>(
                  builder: (context, state) {
                    if (state is! CreatePostEditing) return const SizedBox();
                    final count = state.caption.length;
                    final remaining = 200 - count;

                    // Color changes based on remaining characters
                    Color getColor() {
                      if (remaining < 5) return Colors.red;
                      if (remaining < 20) return Colors.orange;
                      return Colors.grey;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$count/200',
                            style: TextStyle(
                              fontSize: 12,
                              color: getColor(),
                              fontWeight: remaining < 20 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (remaining < 20) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.warning_rounded,
                              size: 14,
                              color: getColor(),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Visibility selector
                MyText(
                  'visibility',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'public',
                      label: MyText(LocaleKeys.public),
                      icon: const Icon(Icons.public),
                    ),
                    ButtonSegment(
                      value: 'followers',
                      label: MyText(LocaleKeys.followers),
                      icon: const Icon(Icons.people),
                    ),
                    ButtonSegment(
                      value: 'private',
                      label: MyText(LocaleKeys.private),
                      icon: const Icon(Icons.lock),
                    ),
                  ],
                  selected: {state.visibility},
                  onSelectionChanged: (Set<String> selection) {
                    context.read<CreatePostCubit>().updateVisibility(
                      selection.first,
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Hashtags and mentions info
                if (state.hashtags.isNotEmpty || state.mentions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.hashtags.isNotEmpty) ...[
                          MyText(
                            'hashtags',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Wrap(
                            spacing: 8,
                            children: state.hashtags
                                .map(
                                  (tag) => Chip(
                                    label: Text('#$tag'), // User content
                                    backgroundColor: Colors.blue[100],
                                  ),
                                )
                                .toList(),
                          ),
                        ],

                        if (state.mentions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          MyText(
                            'mentions',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Wrap(
                            spacing: 8,
                            children: state.mentions
                                .map(
                                  (mention) => Chip(
                                    label: Text('@$mention'), // User content
                                    backgroundColor: Colors.green[100],
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                BlocBuilder<CreatePostCubit, CreatePostState>(
                  builder: (context, state) {
                    final canSubmit =
                        state is CreatePostEditing &&
                        state.mediaFiles.isNotEmpty;
                    return MyButton(
                      icon: Icons.send,
                      onPressed: canSubmit
                          ? () => context.read<CreatePostCubit>().createPost()
                          : null,
                      text: 'publish',
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
