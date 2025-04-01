import 'package:hive/hive.dart';
import '../models/word_model.dart';

const String wordsBoxName = 'wordsBox';

/// Opens the box when the app starts.
/// You should call this in `main()` before `runApp()`.
Future<void> openWordsBox() async {
  await Hive.openBox<WordModel>(wordsBoxName);
}

/// Adds a new word to Hive.
Future<void> saveWord(WordModel word) async {
  final box = Hive.box<WordModel>(wordsBoxName);
  await box.add(word);
}

/// Deletes a word by its Hive index.
Future<void> deleteWordByIndex(int index) async {
  final box = Hive.box<WordModel>(wordsBoxName);
  await box.deleteAt(index);
}

/// Deletes a specific word by matching its properties (alternative to index-based delete).
Future<void> deleteWord(WordModel wordToDelete) async {
  final box = Hive.box<WordModel>(wordsBoxName);

  // Find matching word index
  final int index = box.values.toList().indexWhere((word) =>
      word.word == wordToDelete.word &&
      word.imageUrl == wordToDelete.imageUrl &&
      word.category == wordToDelete.category);

  if (index != -1) {
    await box.deleteAt(index);
  }
}

/// Returns all words from Hive.
List<WordModel> getAllWords() {
  final box = Hive.box<WordModel>(wordsBoxName);
  return box.values.toList();
}

/// Returns words filtered by category.
List<WordModel> getWordsByCategory(String category) {
  final box = Hive.box<WordModel>(wordsBoxName);
  return box.values.where((word) => word.category == category).toList();
}

/// Deletes all words from Hive (useful for resetting data).
Future<void> deleteAllWords() async {
  final box = Hive.box<WordModel>(wordsBoxName);
  await box.clear();
}
