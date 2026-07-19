import 'package:flutter/material.dart';
import '../../../../domain/models/separator_type.dart';
import '../view_models/dashboard_view_model.dart';

class SeparatorSettingsDialog extends StatelessWidget {
  final DashboardViewModel viewModel;

  const SeparatorSettingsDialog({super.key, required this.viewModel});

  static void show(BuildContext context, DashboardViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF222222),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SeparatorSettingsDialog(viewModel: viewModel);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Separator Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<SeparatorType>(
                initialValue: viewModel.selectedSeparator,
                dropdownColor: const Color(0xFF222222),
                decoration: InputDecoration(
                  labelText: 'Separator Type',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                ),
                items: SeparatorType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.label,
                        style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    viewModel.updateSeparator(val);
                  }
                },
              ),
              if (viewModel.selectedSeparator == SeparatorType.custom) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: viewModel.customSeparatorController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Custom Separator',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'Enter characters (e.g. | or ,)',
                    hintStyle: const TextStyle(color: Colors.white30),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  viewModel.addSeparator();
                  Navigator.pop(context);
                },
                child: const Text('Insert Separator'),
              ),
            ],
          ),
        );
      },
    );
  }
}
