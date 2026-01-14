import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/core/helpers/snackbar_helper.dart';
import 'package:street_core/core/widgets/form/form_item_config.dart';
import 'package:street_core/core/widgets/my_form.dart';

import '../../../core/di/injection.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/media/media.dart';
import '../../../core/widgets/my_text.dart';
import '../../../data/models/user_model.dart';
import '../../auth/bloc/user_cubit.dart';
import '../../auth/bloc/user_state.dart';
import '../widgets/avatar_upload_widget.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  bool _isUploadingAvatar = false;
  String? _newAvatarUrl;

  @override
  void dispose() {
    super.dispose();
  }

  /// Maneja la selección de avatar y realiza el upload automáticamente
  Future<void> _handleAvatarSelected(File? file) async {
    if (file == null) return;

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final mediaRepo = getIt<MediaUploadRepository>();
      final response = await mediaRepo.uploadAvatar(file);

      // Validate URL before accepting
      if (response.url.isEmpty ||
          !Uri.tryParse(response.url)!.hasAbsolutePath) {
        throw Exception(LocaleKeys.invalidUploadResponse);
      }

      if (mounted) {
        setState(() {
          _newAvatarUrl = response.url;
          _isUploadingAvatar = false;
        });
      }

      // Actualizar el perfil inmediatamente para que el avatar se refleje en toda la app
      if (mounted) {
        // Send both imageUrl and avatarUrl for backend compatibility
        await context.read<UserCubit>().updateProfile({
          'imageUrl': response.url,
          'avatarUrl': response.url,
        });
        // Clear cached image to force reload
        await CachedNetworkImage.evictFromCache(response.url);
        SnackBarHelper.showSuccess(context, LocaleKeys.avatarUploadedSuccessfully);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }

      if (mounted) {
        final errorKey = e.toString().contains(LocaleKeys.invalidUploadResponse)
            ? LocaleKeys.invalidUploadResponse
            : LocaleKeys.errorUploadingAvatar;
        SnackBarHelper.showError(context, errorKey);
      }
    }
  }

  /// Maneja la selección de avatar en web
  Future<void> _handleAvatarSelectedWeb(
    Uint8List? bytes,
    String? filename,
  ) async {
    if (bytes == null) return;

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final mediaRepo = getIt<MediaUploadRepository>();
      // Usar el filename real para mantener la extensión correcta
      final response = await mediaRepo.uploadAvatarWeb(
        bytes,
        filename ?? 'avatar.jpg',
      );

      // Validate URL before accepting
      if (response.url.isEmpty ||
          !Uri.tryParse(response.url)!.hasAbsolutePath) {
        throw Exception(LocaleKeys.invalidUploadResponse);
      }

      if (mounted) {
        setState(() {
          _newAvatarUrl = response.url;
          _isUploadingAvatar = false;
        });
      }

      // Actualizar el perfil inmediatamente para que el avatar se refleje en toda la app
      if (mounted) {
        // Send both imageUrl and avatarUrl for backend compatibility
        await context.read<UserCubit>().updateProfile({
          'imageUrl': response.url,
          'avatarUrl': response.url,
        });
        // Clear cached image to force reload
        await CachedNetworkImage.evictFromCache(response.url);
        SnackBarHelper.showSuccess(context, LocaleKeys.avatarUploadedSuccessfully);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }

      if (mounted) {
        final errorKey = e.toString().contains(LocaleKeys.invalidUploadResponse)
            ? LocaleKeys.invalidUploadResponse
            : LocaleKeys.errorUploadingAvatar;
        SnackBarHelper.showError(context, errorKey);
      }
    }
  }

  void _submitUpdate(Map<String, dynamic> data) {
    // Añadir la URL del nuevo avatar si se subió (both fields for backend compatibility)
    if (_newAvatarUrl != null && _newAvatarUrl!.isNotEmpty) {
      data['imageUrl'] = _newAvatarUrl;
      data['avatarUrl'] = _newAvatarUrl;
    }

    context.read<UserCubit>().updateProfile(data);
  }

  /// Extrae el primer nombre del nombre completo
  String _extractFirstName(UserModel user) {
    // Si hay lastName, intentar removerlo del nombre completo
    if (user.lastName != null && user.lastName!.isNotEmpty) {
      final fullName = user.firstName.toLowerCase();
      final lastName = user.lastName!.toLowerCase();

      if (fullName.endsWith(lastName)) {
        final withoutLast = user.firstName.substring(
          0,
          user.firstName.length - user.lastName!.length,
        );
        return withoutLast.trim();
      }
    }

    // Si no hay lastName o no se pudo extraer, dividir por espacios
    final parts = user.firstName.split(' ');
    if (parts.length > 1) {
      // Tomar todo excepto la última palabra (que probablemente sea el apellido)
      return parts.sublist(0, parts.length - 1).join(' ');
    }

    // Si solo hay una palabra, devolverla
    return user.firstName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MyText(LocaleKeys.editProfile),
      ),
      body: BlocListener<UserCubit, UserState>(
        listener: (context, state) {
          if (state is UserLoaded) {
            final updateStatus = state.updateStatus;

            // Mostrar Snackbar o Modal
            if (updateStatus == UserUpdateStatus.success) {
              SnackBarHelper.showSuccess(
                context,
                LocaleKeys.profileUpdatedSuccessfully,
              );
            } else if (updateStatus == UserUpdateStatus.error) {
              SnackBarHelper.showError(context, LocaleKeys.profileUpdateError);
            }
          }
        },
        child: BlocBuilder<UserCubit, UserState>(
          builder: (context, state) {
            if (state is! UserLoaded) {
              // Debería ser UserLoaded ya que el router protege esta página,
              // pero manejamos el caso por seguridad.
              return const Center(child: CircularProgressIndicator());
            }

            final user = state.user;
            final isLoading = state.updateStatus == UserUpdateStatus.loading;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Avatar Upload Widget
                  AvatarUploadWidget(
                    currentAvatarUrl: _newAvatarUrl ?? user.imageUrl,
                    onImageSelected: _handleAvatarSelected,
                    onImageSelectedWeb: _handleAvatarSelectedWeb,
                    isLoading: _isUploadingAvatar,
                  ),

                  const SizedBox(height: 24),

                  MyText(LocaleKeys.email, fontSize: 14, color: Colors.grey, selectable: false),
                  MyText(user.email, fontSize: 18, selectable: false),

                  const SizedBox(height: 32),
                  MyForm(
                    isLoading: isLoading,

                    formItems: [
                      // Campo 1: Primer Nombre
                      FormItemConfig.text(
                        id: 'firstName',
                        label: LocaleKeys.firstName,
                        defaultValue: _extractFirstName(user),
                      ),
                      // Campo 2: Apellido
                      FormItemConfig.text(
                        id: 'lastName',
                        label: LocaleKeys.lastName,
                        defaultValue: user.lastName ?? '',
                      ),
                      // Campo 3: Apodo/Nickname
                      FormItemConfig.text(
                        id: 'nickName',
                        label: LocaleKeys.nickName,
                        defaultValue: user.nickName ?? '',
                      ),
                      // Campo 4: Género
                      FormItemConfig.dropdown(
                        id: 'gender',
                        label: LocaleKeys.gender,
                        options: const [
                          LocaleKeys.male,
                          LocaleKeys.female,
                          LocaleKeys.other,
                        ],
                        defaultValue: user.gender ?? '',
                        hintText: LocaleKeys.selectGender,
                      ),
                      // Campo 5: Teléfono
                      FormItemConfig.phone(
                        id: 'phone',
                        label: LocaleKeys.phone,
                        defaultValue: user.phone ?? '',
                      ),
                      // Campo 6: Biografía
                      FormItemConfig.text(
                        id: 'bio',
                        label: LocaleKeys.bio,
                        defaultValue: user.bio ?? '',
                        maxLines: 3,
                      ),
                      // Campo 7: Cuenta Privada
                      FormItemConfig.switcher(
                        id: 'isPrivate',
                        label: LocaleKeys.privateAccount,
                        defaultValue: user.isPrivate,
                        hintText: LocaleKeys.privateAccountDescription,
                      ),
                    ],
                    onSubmit: (data) {
                      _submitUpdate(data);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
