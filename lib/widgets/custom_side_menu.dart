import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../category_data.dart'; // for updating the global categories map

class CustomSideMenu extends StatefulWidget {
  final double topPadding;
  final List<String> categories;
  final void Function(String category, int index) onCategoryTap;
  final void Function(Map<String, String> word, String targetCategory) onWordDropped;
  final bool editMode;
  final String activeCategory;
  final void Function(List<String> newOrder) onReorderCategories;

  const CustomSideMenu({
    super.key,
    required this.topPadding,
    required this.categories,
    required this.onCategoryTap,
    required this.onWordDropped,
    required this.editMode,
    required this.activeCategory,
    required this.onReorderCategories,
  });

  @override
  State<CustomSideMenu> createState() => _CustomSideMenuState();
}

class _CustomSideMenuState extends State<CustomSideMenu> {
  late List<String> _localCategories;

  @override
  void initState() {
    super.initState();
    _localCategories = List.from(widget.categories);
  }

  @override
  void didUpdateWidget(covariant CustomSideMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories != widget.categories) {
      _localCategories = List.from(widget.categories);
    }
  }

  Future<void> _showEditCategoryDialog(int index) async {
    final controller = TextEditingController(text: _localCategories[index]);

    await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Category"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Category Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: ctx,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Category'),
                  content: const Text('Are you sure you want to delete this category?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (!mounted) return;
              if (confirm == true) {
                final wasActive = (_localCategories[index] == widget.activeCategory);
                _localCategories.removeAt(index);
                widget.onReorderCategories(_localCategories);

                if (_localCategories.isNotEmpty && wasActive) {
                  final newIndex =
                      (index < _localCategories.length) ? index : _localCategories.length - 1;
                  widget.onCategoryTap(_localCategories[newIndex], newIndex);
                }
                // ignore: use_build_context_synchronously
                Navigator.pop(ctx);
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() => _localCategories[index] = newName);
                widget.onReorderCategories(_localCategories);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Category"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "New Category Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newCategory = controller.text.trim();
              if (newCategory.isNotEmpty) {
                setState(() {
                  _localCategories.insert(0, newCategory);
                  categories[newCategory] = [];
                });
                widget.onReorderCategories(_localCategories);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Provider.of<ThemeProvider>(context).primaryColor;

    return Container(
      width: 200,
      padding: EdgeInsets.only(top: widget.topPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget.editMode
          ? _buildReorderableList(primaryColor)
          : _buildRegularList(primaryColor),
    );
  }

  Widget _buildReorderableList(Color primaryColor) {
    return Column(
      children: [
        _buildSectionHeader("Categories", primaryColor),
        TextButton.icon(
          onPressed: _showAddCategoryDialog,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Add Category", style: TextStyle(color: Colors.white)),
        ),
        Expanded(
          child: ReorderableListView.builder(
            primary: false,
            itemCount: _localCategories.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final movedCategory = _localCategories.removeAt(oldIndex);
                _localCategories.insert(newIndex, movedCategory);
              });
              widget.onReorderCategories(_localCategories);
            },
            itemBuilder: (context, index) {
              final category = _localCategories[index];
              final isActive = (category == widget.activeCategory);
              return _ReorderableCategoryItem(
                key: ValueKey(category),
                category: category,
                isActive: isActive,
                primaryColor: primaryColor,
                onTap: () => widget.onCategoryTap(category, index),
                onEdit: () => _showEditCategoryDialog(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRegularList(Color primaryColor) {
    return Scrollbar(
      thumbVisibility: true,
      child: ListView.separated(
        primary: false,
        itemCount: widget.categories.length + 1,
        separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSectionHeader("Categories", primaryColor);
          }
          final category = widget.categories[index - 1];
          final isActive = (category == widget.activeCategory);
          return _HoverableSideMenuItem(
            category: category,
            isActiveCategory: isActive,
            primaryColor: primaryColor,
            onTap: () => widget.onCategoryTap(category, index - 1),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
      ),
    );
  }
}

class _ReorderableCategoryItem extends StatelessWidget {
  final String category;
  final bool isActive;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ReorderableCategoryItem({
    super.key,
    required this.category,
    required this.isActive,
    required this.primaryColor,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: _HoverableSideMenuItem(
        category: category,
        isActiveCategory: isActive,
        primaryColor: primaryColor,
        onTap: onTap,
        onDoubleTap: onEdit,
      ),
    );
  }
}

class _HoverableSideMenuItem extends StatefulWidget {
  final String category;
  final bool isActiveCategory;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  const _HoverableSideMenuItem({
    required this.category,
    required this.isActiveCategory,
    required this.primaryColor,
    required this.onTap,
    this.onDoubleTap,
  });

  @override
  State<_HoverableSideMenuItem> createState() => _HoverableSideMenuItemState();
}

class _HoverableSideMenuItemState extends State<_HoverableSideMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isActiveCategory
        ? widget.primaryColor.withAlpha(51)
        : _isHovered
            ? widget.primaryColor.withAlpha(25)
            : Theme.of(context).colorScheme.surfaceContainer;

    final textColor = widget.isActiveCategory
        ? widget.primaryColor
        : Theme.of(context).colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: (_isHovered || widget.isActiveCategory)
                ? [
                    BoxShadow(
                      color: widget.primaryColor.withAlpha(31),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              widget.category,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontWeight: widget.isActiveCategory ? FontWeight.bold : FontWeight.w500,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
