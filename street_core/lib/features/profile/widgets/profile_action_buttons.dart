import 'package:go_router/go_router.dart';

import '../../../core/widgets/my_button.dart';
import 'package:flutter/material.dart';

import '../pages/profile_edit_page.dart';
import '../profile_routes.dart';

/// Profile Action Buttons
/// Displays the row of action buttons (Create Post, Add Story, Edit Profile)
class ProfileActionButtons extends StatelessWidget {
  const ProfileActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: MyButton(
              text: 'create.post',
              onPressed: () => context.push(ProfileRoutes.postCreate),
              icon: Icons.add_photo_alternate,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: MyButton(
              text: 'add.story',
              onPressed: null,
              icon: Icons.auto_stories,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MyButton(
              text: 'edit.profile',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: BottomSheet(
                        elevation: 2,

                        onClosing: () {},
                        builder: (context) {
                          return ProfileEditPage();
                        },
                      ),
                    );
                  },
                );
              },
              icon: Icons.edit,
            ),
          ),
        ],
      ),
    );
  }
}
