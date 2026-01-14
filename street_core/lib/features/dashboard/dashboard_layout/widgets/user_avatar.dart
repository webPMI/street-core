import 'package:street_core/core/widgets/user_avatar.dart';

import '../../../../core/helpers/responsive/responsive_builder.dart';
import '../../../auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Avatar button that opens the drawer when tapped.
class UserAvatarButton extends StatelessWidget {
  const UserAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final radius = isMobile ? 18.0 : 20.0;

    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        if (state is UserLoaded) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Scaffold.of(context).openDrawer(),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: UserAvatar(
                    size: radius,
                    imageUrl: state.user.imageUrl,
                    fallbackText: state.user.firstName,
                  ),
                ),
              ),
            ),
          );
        }

        // Loading/default state
        return Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            child: CircleAvatar(
              radius: radius,
              child: const Icon(Icons.person, size: 20),
            ),
          ),
        );
      },
    );
  }
}
