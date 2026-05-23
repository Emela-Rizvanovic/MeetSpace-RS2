import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/amenity_category.dart';
import '../providers/auth_provider.dart';
import '../utils/validators.dart';

import '../widgets/admin_styles.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/amenity_categories_section.dart';

class AmenityCategoriesDialog
    extends StatefulWidget {
  const AmenityCategoriesDialog({
    super.key,
  });

  @override
  State<AmenityCategoriesDialog>
      createState() =>
          _AmenityCategoriesDialogState();
}

class _AmenityCategoriesDialogState
    extends State<
        AmenityCategoriesDialog> {

  List<AmenityCategory>
      _categories = [];

  bool _isLoadingCategories =
      false;

  String _categorySearch = "";

  int _categoryPage = 0;

  final int _categoryPageSize =
      3;

  int _categoryTotalPages = 1;

  @override
  void initState() {
    super.initState();

    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor:
          AdminStyles.bgColor,

      insetPadding:
          const EdgeInsets.all(40),

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
                24),
      ),

      child: SizedBox(
        width: 1000,
        height: 650,

       child: Padding(
  padding:
      const EdgeInsets.all(30),

  child: Column(
    children: [

      Expanded(
        child:
            AmenityCategoriesSection(
          categories:
              _categories,

          isLoading:
              _isLoadingCategories,

          currentPage:
              _categoryPage,

          totalPages:
              _categoryTotalPages,

          onSearch: (value) {
            setState(() {
              _categorySearch =
                  value;

              _categoryPage = 0;
            });

            _loadCategories();
          },

          onAdd: () async {
            await _showCategoryDialog();
          },

          onEdit:
              (category) async {
            await _showCategoryDialog(
              category:
                  category,
            );
          },

          onDelete:
              (category) async {
            await _deleteCategory(
              category,
            );
          },

          onPrevious:
              _categoryPage > 0
                  ? () {
                      setState(() {
                        _categoryPage--;
                      });

                      _loadCategories();
                    }
                  : null,

          onNext:
              _categoryPage <
                      _categoryTotalPages -
                          1
                  ? () {
                      setState(() {
                        _categoryPage++;
                      });

                      _loadCategories();
                    }
                  : null,

          onPageSelected:
              (page) {
            setState(() {
              _categoryPage =
                  page;
            });

            _loadCategories();
          },
        ),
      ),

      const SizedBox(height: 20),

      SizedBox(
        width: 150,

        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },

          style:
              AdminStyles.primaryButton,

          child:
              const Text("Close"),
        ),
      ),
    ],
  ),
),
      ),
    );
  }

  Future<void>
      _showCategoryDialog({
    AmenityCategory? category,
  }) async {

    final formKey =
        GlobalKey<FormState>();

    final controller =
        TextEditingController(
      text: category?.name ?? "",
    );

    final result =
        await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor:
              AdminStyles.cardColor,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
                    20),
          ),

          title: Text(
            category == null
                ? "Add category"
                : "Edit category",

            style:
                const TextStyle(
              color: Colors.white,
            ),
          ),

          content: SizedBox(
            width: 400,

            child: Form(
              key: formKey,

              child: TextFormField(
                controller:
                    controller,

                autovalidateMode:
                    AutovalidateMode
                        .onUserInteraction,

                validator:
                    (value) =>
                        Validators
                            .required(
                  value,
                  "Category name",
                ),

                style:
                    const TextStyle(
                  color:
                      Colors.white,
                ),

                decoration:
                    AdminStyles
                        .inputDecoration(
                  "Category name",
                ),
              ),
            ),
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                    context);
              },

              style: AdminStyles
                  .cancelButton,

              child: const Text(
                  "Cancel"),
            ),

            ElevatedButton(
              onPressed:
                  () async {

                if (!formKey
                    .currentState!
                    .validate()) {
                  return;
                }

                try {
                  final auth =
                      context.read<
                          AuthProvider>();

                  final body = {
                    "name":
                        controller
                            .text,
                  };

                  if (category ==
                      null) {

                    await auth
                        .amenityCategoryService
                        .insert(
                            body);

                  } else {

                    await auth
                        .amenityCategoryService
                        .update(
                      category.id,
                      body,
                    );
                  }

                  Navigator.pop(
                    context,
                    true,
                  );

              } catch (_) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Action failed")),
  );
}
              },

              style: AdminStyles
                  .primaryButton,

              child:
                  const Text(
                      "Save"),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(
                context)
            .showSnackBar(
          SnackBar(
            content: Text(
              category == null
                  ? "Category added successfully"
                  : "Category updated successfully",
            ),

            backgroundColor:
                Colors.green,
          ),
        );
      }
    }
  }

  Future<void>
      _deleteCategory(
    AmenityCategory category,
  ) async {

    final confirmed =
        await showDialog<bool>(
      context: context,

      builder: (_) {
        return ConfirmDeleteDialog(
          title:
              "Delete category",

          message:
              "Are you sure you want to delete ${category.name}?",
        );
      },
    );

    if (confirmed == true) {
      try {
        final auth =
            context.read<
                AuthProvider>();

        await auth
            .amenityCategoryService
            .delete(
          category.id,
        );

        await _loadCategories();

        if (mounted) {
          ScaffoldMessenger.of(
                  context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                "Category deleted successfully",
              ),

              backgroundColor:
                  Colors.red,
            ),
          );
        }

      } catch (e) {

        ScaffoldMessenger.of(
                context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Cannot delete category because it is in use.",
            ),

            backgroundColor:
                Colors.orange,
          ),
        );
      }
    }
  }

  Future<void>
      _loadCategories() async {

    try {
      setState(() {
        _isLoadingCategories =
            true;
      });

      final auth =
          context.read<
              AuthProvider>();

      final result =
          await auth
              .amenityCategoryService
              .getPaged(
        page: _categoryPage,

        pageSize:
            _categoryPageSize,

        name:
            _categorySearch,
      );

      final items =
          result["items"]
              as List;

      setState(() {
        _categories = items
            .map(
              (e) =>
                  AmenityCategory
                      .fromJson(
                          e),
            )
            .toList();

        _categoryTotalPages =
            result["totalPages"] ??
                1;

        _isLoadingCategories =
            false;
      });

    } catch (e) {

      setState(() {
        _isLoadingCategories =
            false;
      });
    }
  }
}