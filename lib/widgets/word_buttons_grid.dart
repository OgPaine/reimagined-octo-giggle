import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderables/reorderables.dart';
import '../models/word_model.dart';

class WordButtonsGrid extends StatefulWidget {
  final bool editMode;
  final List<WordModel> words;
  final void Function(String) onSpeak;
  final void Function(int) onDelete;
  final void Function(List<WordModel> reorderedWords)? onReorderComplete;

  const WordButtonsGrid({
    super.key,
    required this.editMode,
    required this.words,
    required this.onSpeak,
    required this.onDelete,
    this.onReorderComplete,
  });

  @override
  State<WordButtonsGrid> createState() => _WordButtonsGridState();
}

class _WordButtonsGridState extends State<WordButtonsGrid> {
  late List<WordModel> _wordList;

  @override
  void initState() {
    super.initState();
    _wordList = List.from(widget.words);
  }

  @override
  void didUpdateWidget(covariant WordButtonsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.words != oldWidget.words) {
      _wordList = List.from(widget.words);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = _calculateButtonSize(MediaQuery.of(context).size.width);

    final wordWidgets = List<Widget>.generate(_wordList.length, (index) {
      final word = _wordList[index];
      return KeyedSubtree(
        key: ValueKey(word.word),
        child: AnimatedWordButton(
          word: word,
          size: buttonSize,
          onSpeak: widget.onSpeak,
          onTapOverride: widget.editMode ? () => _editWordDialog(index) : null,
        ),
      );
    });

    if (widget.editMode) {
      wordWidgets.add(KeyedSubtree(
        key: UniqueKey(),
        child: _buildAddWordButton(buttonSize),
      ));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: widget.editMode
            ? ReorderableWrap(
                spacing: 6,
                runSpacing: 6,
                needsLongPressDraggable: true,
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex < newIndex) newIndex--;
                  setState(() {
                    final item = _wordList.removeAt(oldIndex);
                    _wordList.insert(newIndex, item);
                  });
                  widget.onReorderComplete?.call(List.from(_wordList));
                },
                children: wordWidgets,
              )
            : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: wordWidgets,
              ),
      ),
    );
  }

  double _calculateButtonSize(double maxWidth) {
    const baseWidth = 130.0;
    const spacing = 6.0;
    final count = (maxWidth / (baseWidth + spacing)).floor().clamp(2, 10);
    return (maxWidth - ((count - 1) * spacing)) / count;
  }

  Widget _buildAddWordButton(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: Colors.grey.shade300,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _addWordDialog,
          child: const Center(
            child: Icon(Icons.add, size: 36, color: Colors.black54),
          ),
        ),
      ),
    );
  }

  void _editWordDialog(int index) async {
    final word = _wordList[index];
    final controller = TextEditingController(text: word.word);
    String newImageUrl = word.imageUrl;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Word'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Word'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  setState(() => newImageUrl = picked.path);
                }
              },
              icon: const Icon(Icons.image, color: Colors.white),
              label: const Text('Change Image', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final updated = WordModel(
                word: controller.text.trim(),
                imageUrl: newImageUrl,
                category: word.category,
              );
              setState(() => _wordList[index] = updated);
              widget.onReorderComplete?.call(List.from(_wordList));
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addWordDialog() async {
    final controller = TextEditingController();
    String imageUrl = '';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Word'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Word'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  setState(() => imageUrl = picked.path);
                }
              },
              icon: const Icon(Icons.image, color: Colors.white),
              label: const Text('Select Image', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty && imageUrl.trim().isNotEmpty) {
                final newWord = WordModel(
                  word: controller.text.trim(),
                  imageUrl: imageUrl,
                  category: _wordList.isNotEmpty ? _wordList.first.category : '',
                );
                setState(() => _wordList.add(newWord));
                widget.onReorderComplete?.call(List.from(_wordList));
              }
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class AnimatedWordButton extends StatelessWidget {
  final WordModel word;
  final void Function(String) onSpeak;
  final double size;
  final void Function()? onTapOverride;

  const AnimatedWordButton({
    super.key,
    required this.word,
    required this.onSpeak,
    required this.size,
    this.onTapOverride,
  });

  @override
  Widget build(BuildContext context) {
    const placeholder = 'assets/images/placeholder.png';
    return GestureDetector(
      onTap: () {
        if (onTapOverride != null) {
          onTapOverride!();
        } else {
          onSpeak(word.word);
        }
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: Theme.of(context).primaryColor,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImageWithFallback(word.imageUrl, placeholder, size * 0.66),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  flex: 1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      word.word,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWithFallback(String imageUrl, String fallback, double size) {
    if (imageUrl.trim().isEmpty) {
      return Image.asset(fallback, width: size, height: size, fit: BoxFit.cover);
    }
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(fallback, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return FutureBuilder<bool>(
      future: File(imageUrl).exists().catchError((_) => false),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (snapshot.hasError || !(snapshot.data ?? false)) {
          return Image.asset(fallback, width: size, height: size, fit: BoxFit.cover);
        }
        return Image.file(
          File(imageUrl),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset(fallback, width: size, height: size, fit: BoxFit.cover),
        );
      },
    );
  }
}
