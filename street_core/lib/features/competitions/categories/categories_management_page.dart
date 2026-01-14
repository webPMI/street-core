// lib/presentation/dashboard/competitions/categories/categories_management_page.dart

import 'package:go_router/go_router.dart';
import 'package:street_core/core/lang/locale_keys.dart';

import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/widgets/my_text.dart';
import '../../../core/widgets/help_guide/bloc/guide_cubit.dart';
import '../../../core/widgets/help_guide/widgets/guide_overlay.dart';
import './bloc/competition_category_cubit.dart';
import './bloc/competition_category_state.dart';
import './widgets/category_card.dart';
import './widgets/category_form_dialog.dart';
import '../models/competition_category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoriesManagementPage extends StatefulWidget {
  const CategoriesManagementPage({
    super.key,
    required this.competitionId,
    required this.competitionName,
    this.isOrganizer = false,
  });
  final String competitionId;
  final String competitionName;
  final bool isOrganizer;

  @override
  State<CategoriesManagementPage> createState() =>
      _CategoriesManagementPageState();
}

class _CategoriesManagementPageState extends State<CategoriesManagementPage> {
  @override
  void initState() {
    super.initState();
    _loadCategories();

    // Load guide for categories page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GuideCubit>().loadGuideForRoute('/competitions/categories');
    });
  }

  void _loadCategories() {
    context.read<CompetitionCategoryCubit>().fetchCategories(
          widget.competitionId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.category),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MyText(LocaleKeys.categories),
                Text(
                  widget.competitionName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          BlocConsumer<CompetitionCategoryCubit, CompetitionCategoryState>(
            listener: (context, state) {
              if (state is CategoryActionSuccess) {
                SnackBarHelper.showSuccess(context, state.message);
              } else if (state is CategoryError) {
                SnackBarHelper.showError(context, state.message);
              }
            },
            builder: (context, state) {
              if (state is CategoriesLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CategoriesLoaded) {
                if (state.categories.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadCategories(),
                  child: widget.isOrganizer
                      ? _buildReorderableList(state.categories)
                      : _buildList(state.categories),
                );
              }

              return const SizedBox.shrink();
            },
          ),

          // Help guide widgets
          const AutoGuide(),
          const GuideOverlay(),
        ],
      ),
      floatingActionButton: widget.isOrganizer
          ? FloatingActionButton.extended(
              onPressed: _showCategoryDialog,
              icon: const Icon(Icons.add),
              label: const MyText(LocaleKeys.addCategory),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const MyText(
            LocaleKeys.noCategoriesYet,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          if (widget.isOrganizer) ...[
            const SizedBox(height: 8),
            const MyText(
              LocaleKeys.tapAddToCreateCategory,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList(List<CompetitionCategory> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return CategoryCard(
          category: categories[index],
          isOrganizer: widget.isOrganizer,
          onTap: () => _navigateToCategoryDetail(categories[index]),
          onEdit: widget.isOrganizer
              ? () => _showCategoryDialog(categories[index])
              : null,
          onDelete: widget.isOrganizer
              ? () => _confirmDelete(categories[index])
              : null,
        );
      },
    );
  }

  Widget _buildReorderableList(List<CompetitionCategory> categories) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }

        final items = List<CompetitionCategory>.from(categories);
        final item = items.removeAt(oldIndex);
        items.insert(newIndex, item);

        context.read<CompetitionCategoryCubit>().reorderCategories(
              widget.competitionId,
              items,
            );
      },
      itemBuilder: (context, index) {
        return Dismissible(
          key: ValueKey(categories[index].id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return _showDeleteConfirmation(categories[index]);
          },
          onDismissed: (direction) {
            context.read<CompetitionCategoryCubit>().deleteCategory(
                  widget.competitionId,
                  categories[index].id,
                );
          },
          child: CategoryCard(
            category: categories[index],
            isOrganizer: widget.isOrganizer,
            onTap: () => _navigateToCategoryDetail(categories[index]),
            onEdit: () => _showCategoryDialog(categories[index]),
            showReorderHandle: true,
          ),
        );
      },
    );
  }

  void _showCategoryDialog([CompetitionCategory? category]) {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        competitionId: widget.competitionId,
        category: category,
      ),
    );
  }

  void _navigateToCategoryDetail(CompetitionCategory category) {
    context.push('/category/${category.id}');
  }

  Future<void> _confirmDelete(CompetitionCategory category) async {
    final confirmed = await _showDeleteConfirmation(category);
    if ((confirmed ?? false) && mounted) {
      context.read<CompetitionCategoryCubit>().deleteCategory(
            widget.competitionId,
            category.id,
          );
    }
  }

  Future<bool?> _showDeleteConfirmation(CompetitionCategory category) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const MyText(LocaleKeys.confirmDelete),
        content: MyText(
          LocaleKeys.confirmDeleteCategory,
          args: {'name': category.name},
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const MyText(LocaleKeys.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const MyText(LocaleKeys.delete),
          ),
        ],
      ),
    );
  }
}
