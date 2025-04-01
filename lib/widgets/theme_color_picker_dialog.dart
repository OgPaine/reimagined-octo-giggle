// lib/widgets/theme_color_picker_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class ThemeColorPickerDialog extends StatelessWidget {
  const ThemeColorPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final predefinedColors = [
      Colors.red,
      Colors.pink,
      Colors.deepOrange,
      Colors.lightGreen,
      Colors.green,
      Colors.teal,
      Colors.cyan,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ];

    return AlertDialog(
      title: const Text('Select Theme Color'),
      content: SingleChildScrollView(
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: predefinedColors.map((color) {
            // Using toARGB32() instead of .value for comparison
            final isSelected = color.toARGB32() == themeProvider.primaryColor.toARGB32();

            return GestureDetector(
              onTap: () {
                themeProvider.updatePrimaryColor(color);
                Navigator.of(context).pop(); // Close after selection
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.black, width: 3)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}