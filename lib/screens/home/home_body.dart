import 'package:flutter/material.dart';
import '../../category_data.dart';
import '../../models/word_model.dart';
import '../../widgets/custom_side_menu.dart';
import '../../widgets/word_buttons_grid.dart';

class HomeBody extends StatelessWidget {
  final String selectedCategory;
  final bool editMode;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<bool> onEditModeChanged;
  final ValueChanged<String> onSpeak;
  final ValueChanged<int> onDeleteCategory;
  final VoidCallback onPersistCategories;

  const HomeBody({
    super.key,
    required this.selectedCategory,
    required this.editMode,
    required this.onCategoryChanged,
    required this.onEditModeChanged,
    required this.onSpeak,
    required this.onDeleteCategory,
    required this.onPersistCategories,
  });
  @override
  Widget build(BuildContext context) {
    final categoryWords = categories[selectedCategory] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          CustomSideMenu(
            topPadding: MediaQuery.of(context).padding.top,
            categories: categories.keys.toList(),
            onCategoryTap: (category, index) => onCategoryChanged(category),
            onWordDropped: (word, targetCategory) {
              categories[selectedCategory]?.remove(word);
              categories[targetCategory]?.add(word);
              onCategoryChanged(targetCategory);
              onPersistCategories();
            },
            editMode: editMode,
            activeCategory: selectedCategory,
            onReorderCategories: (newOrder) {
              final newCategories = <String, List<Map<String, String>>>{};
              for (final cat in newOrder) {
                if (categories.containsKey(cat)) {
                  newCategories[cat] = categories[cat]!;
                }
              }
              categories
                ..clear()
                ..addAll(newCategories);
              onPersistCategories();
            },
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: WordButtonsGrid(
              editMode: editMode,
              words: categoryWords
                  .map(
                    (e) => WordModel(
                      word: e['word'] ?? '',
                      imageUrl: e['imageUrl'] ?? '',
                      category: selectedCategory,
                    ),
                  )
                  .toList(),
              onSpeak: onSpeak,
              onDelete: (index) {
                categoryWords.removeAt(index);
                onPersistCategories();
              },
              onReorderComplete: (reorderedWords) {
                categories[selectedCategory] = reorderedWords
                    .map((wordModel) => {
                          'word': wordModel.word,
                          'imageUrl': wordModel.imageUrl,
                        })
                    .toList();
                onPersistCategories();
              },
            ),
          ),
        ],
      ),
    );
  }
}
