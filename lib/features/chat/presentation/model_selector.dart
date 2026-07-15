import 'package:flutter/material.dart';

import '../../../models/model_info.dart';

/// Model selector — bottom sheet with available models.
///
/// Displays a list of models from the server. The currently selected model
/// is highlighted. Tapping a model updates the selection and closes the sheet.
class ModelSelector extends StatelessWidget {
 final List<ModelInfo> models;
 final String? selectedModelId;
 final ValueChanged<String> onModelSelected;

 const ModelSelector({
 super.key,
 required this.models,
 required this.selectedModelId,
 required this.onModelSelected,
 });

 /// Show the model selector as a modal bottom sheet.
 static Future<void> show(
 BuildContext context, {
 required List<ModelInfo> models,
 required String? selectedModelId,
 required ValueChanged<String> onModelSelected,
 }) {
 return showModalBottomSheet(
 context: context,
 backgroundColor: Theme.of(context).colorScheme.surface,
 shape: const RoundedRectangleBorder(
 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
 ),
 builder: (_) => ModelSelector(
 models: models,
 selectedModelId: selectedModelId,
 onModelSelected: onModelSelected,
 ),
 );
 }

 @override
 Widget build(BuildContext context) {
 return SafeArea(
 child: Padding(
 padding: EdgeInsets.only(top: 12, bottom: 24),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Handle bar.
 Center(
 child: Container(
 width: 40,
 height: 4,
 decoration: BoxDecoration(
 color: Theme.of(context).colorScheme.outlineVariant,
 borderRadius: BorderRadius.circular(2),
 ),
 ),
 ),
 SizedBox(height: 16),

 // Title.
 Padding(
 padding: EdgeInsets.symmetric(horizontal: 20),
 child: Text(
 'Select Model',
 style: Theme.of(context).textTheme.titleLarge?.copyWith(
 color: Theme.of(context).colorScheme.onSurface,
 ),
 ),
 ),
 SizedBox(height: 8),

 // Model list.
 if (models.isEmpty)
 Padding(
 padding: EdgeInsets.all(20),
 child: Center(
 child: Text(
 'No models available.',
 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
 color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
 ),
 ),
 ),
 )
 else
 Flexible(
 child: ListView.separated(
 shrinkWrap: true,
 padding: EdgeInsets.symmetric(horizontal: 8),
 itemCount: models.length,
 separatorBuilder: (context, index) =>
 Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
 itemBuilder: (context, index) {
 final model = models[index];
 final isSelected = model.id == selectedModelId;

 return ListTile(
 leading: Icon(
   isSelected
       ? Icons.check_circle
       : Icons.circle_outlined,
   color:
       isSelected ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
 size: 20,
 ),
 title: Text(
 model.id,
 style: Theme.of(context).textTheme.bodyLarge?.copyWith(
   color: isSelected
       ? Theme.of(context).colorScheme.secondary
       : Theme.of(context).colorScheme.onSurface,
 fontWeight: isSelected
 ? FontWeight.w600
 : FontWeight.normal,
 ),
 ),
 subtitle: model.ownedBy != null
 ? Text(
 model.ownedBy!,
 style: Theme.of(context)
 .textTheme
 .bodySmall
 ?.copyWith(
 color: Theme.of(context).colorScheme.onSurfaceVariant,
 ),
 )
 : null,
 onTap: () {
 onModelSelected(model.id);
 Navigator.pop(context);
 },
 );
 },
 ),
 ),
 ],
 ),
 ),
 );
 }
}
