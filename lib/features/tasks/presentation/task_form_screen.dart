import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/colors.dart';
import '../providers/task_provider.dart';

/// Task form screen — create or edit a cron job.
///
/// Modes:
/// - Create (id == null): fresh form, POST to server
/// - Edit (id != null): pre-filled form, PUT to server
///
/// States handled:
/// - Loading (when editing — loading existing job data)
/// - Form idle (ready for input)
/// - Submitting (create/update in progress, button disabled)
/// - Success (navigates back)
/// - Error (shows error banner)
///
/// Edge cases:
/// - Duplicate submission prevention (button disabled while submitting)
/// - Validation: prompt required, schedule required
/// - Long prompt input handled by multi-line field
class TaskFormScreen extends ConsumerStatefulWidget {
  /// Job ID for editing. null means "create new".
  final String? id;

  const TaskFormScreen({super.key, this.id});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _promptController;
  late final TextEditingController _scheduleController;
  late final TextEditingController _nameController;
  late final TextEditingController _modelNameController;
  late final TextEditingController _modelProviderController;
  late final TextEditingController _skillsController;
  late final TextEditingController _deliverController;

  bool _isEditMode = false;
  bool _jobLoaded = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
    _scheduleController = TextEditingController();
    _nameController = TextEditingController();
    _modelNameController = TextEditingController();
    _modelProviderController = TextEditingController();
    _skillsController = TextEditingController();
    _deliverController = TextEditingController();

    _isEditMode = widget.id != null;

    if (_isEditMode) {
      _loadJob();
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scheduleController.dispose();
    _nameController.dispose();
    _modelNameController.dispose();
    _modelProviderController.dispose();
    _skillsController.dispose();
    _deliverController.dispose();
    super.dispose();
  }

  /// Load existing job data for edit mode.
  void _loadJob() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final asyncJob = ref.read(taskDetailProvider(widget.id!));
      asyncJob.whenData((job) {
        if (job != null && mounted) {
          setState(() {
            _promptController.text = job.prompt;
            _scheduleController.text = job.schedule;
            _nameController.text = job.name ?? '';
            _modelNameController.text = job.modelName ?? '';
            _modelProviderController.text = job.modelProvider ?? '';
            _skillsController.text = job.skills.join(', ');
            _deliverController.text = job.deliver ?? '';
            _jobLoaded = true;
          });
        }
      });
    });
  }

  // ─── Validation ───

  String? _validatePrompt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Prompt is required.';
    }
    if (value.trim().length < 3) {
      return 'Prompt must be at least 3 characters.';
    }
    return null;
  }

  String? _validateSchedule(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Schedule is required.';
    }

    // Simple cron validation: 5 space-separated fields.
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length != 5) {
      return 'Schedule must be a valid cron expression (5 fields). Examples:\n'
          '- */30 * * * * (every 30 min)\n'
          '- 0 9 * * * (daily at 9 AM)\n'
          '- 0 */2 * * * (every 2 hours)';
    }

    return null;
  }

  // ─── Submit ───

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();

    final prompt = _promptController.text.trim();
    final schedule = _scheduleController.text.trim();
    final name = _nameController.text.trim();
    final modelName = _modelNameController.text.trim();
    final modelProvider = _modelProviderController.text.trim();
    final skillsRaw = _skillsController.text.trim();
    final deliver = _deliverController.text.trim();

    final skills = skillsRaw.isNotEmpty
        ? skillsRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    final notifier = ref.read(taskListProvider.notifier);
    bool success;

    if (_isEditMode) {
      success = await notifier.updateJob(
        id: widget.id!,
        prompt: prompt,
        schedule: schedule,
        name: name.isNotEmpty ? name : null,
        modelName: modelName.isNotEmpty ? modelName : null,
        modelProvider: modelProvider.isNotEmpty ? modelProvider : null,
        skills: skills.isNotEmpty ? skills : null,
        deliver: deliver.isNotEmpty ? deliver : null,
      );
    } else {
      success = await notifier.createJob(
        prompt: prompt,
        schedule: schedule,
        name: name.isNotEmpty ? name : null,
        modelName: modelName.isNotEmpty ? modelName : null,
        modelProvider: modelProvider.isNotEmpty ? modelProvider : null,
        skills: skills.isNotEmpty ? skills : null,
        deliver: deliver.isNotEmpty ? deliver : null,
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Job updated successfully.' : 'Job created successfully.'),
            backgroundColor: HermesColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Failed to update job.' : 'Failed to create job.'),
            backgroundColor: HermesColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ─── Common Schedule Presets ───

  static const List<({String label, String cron})> _presets = [
    (label: 'Every 30 minutes', cron: '*/30 * * * *'),
    (label: 'Every hour', cron: '0 * * * *'),
    (label: 'Daily at 9 AM', cron: '0 9 * * *'),
    (label: 'Daily at midnight', cron: '0 0 * * *'),
    (label: 'Every 2 hours', cron: '0 */2 * * *'),
    (label: 'Weekly (Mon 9 AM)', cron: '0 9 * * 1'),
  ];

  void _applyPreset(String cron) {
    _scheduleController.text = cron;
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show loading while fetching edit data.
    if (_isEditMode && !_jobLoaded && widget.id != null) {
      final asyncJob = ref.watch(taskDetailProvider(widget.id!));
      if (asyncJob.isLoading) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: HermesColors.textPrimary,
              onPressed: () => context.pop(),
            ),
          ),
          body: const Center(
            child: CircularProgressIndicator(color: HermesColors.cyan),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: HermesColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditMode ? AppStrings.editJob : AppStrings.createJob,
          style: theme.textTheme.titleMedium?.copyWith(
            color: HermesColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Name ───
              _buildLabeledField(
                theme: theme,
                label: 'Job Name (optional)',
                hint: 'e.g., Daily briefing',
                controller: _nameController,
                icon: Icons.label_outline,
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: 16),

              // ─── Prompt ───
              _buildLabeledField(
                theme: theme,
                label: '${AppStrings.prompt} *',
                hint: 'What should this cron job do?',
                controller: _promptController,
                icon: Icons.article_outlined,
                maxLines: 4,
                validator: _validatePrompt,
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: 16),

              // ─── Schedule ───
              _buildLabeledField(
                theme: theme,
                label: '${AppStrings.schedule} (cron) *',
                hint: 'e.g., 0 9 * * *',
                controller: _scheduleController,
                icon: Icons.schedule,
                validator: _validateSchedule,
                enabled: !_isSubmitting,
              ),

              // ─── Presets ───
              const SizedBox(height: 8),
              _buildPresetChips(theme),

              const SizedBox(height: 16),

              // ─── Model Name ───
              _buildLabeledField(
                theme: theme,
                label: 'Model (optional)',
                hint: 'e.g., deepseek-v4-pro',
                controller: _modelNameController,
                icon: Icons.smart_toy_outlined,
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: 16),

              // ─── Model Provider ───
              _buildLabeledField(
                theme: theme,
                label: 'Model Provider (optional)',
                hint: 'e.g., deepseek',
                controller: _modelProviderController,
                icon: Icons.cloud_outlined,
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: 16),

              // ─── Skills ───
              _buildLabeledField(
                theme: theme,
                label: 'Skills (comma-separated, optional)',
                hint: 'e.g., hermes-agent, code-review',
                controller: _skillsController,
                icon: Icons.extension_outlined,
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: 16),

              // ─── Deliver ───
              _buildLabeledField(
                theme: theme,
                label: '${AppStrings.deliverTarget} (optional)',
                hint: 'e.g., telegram, origin',
                controller: _deliverController,
                icon: Icons.send_outlined,
                enabled: !_isSubmitting,
              ),

              const SizedBox(height: 32),

              // ─── Error (if any) ───
              _buildFormError(theme),

              // ─── Submit Button ───
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: HermesColors.dark,
                          ),
                        )
                      : Icon(_isEditMode ? Icons.save : Icons.add),
                  label: Text(
                    _isSubmitting
                        ? (_isEditMode ? 'Updating...' : 'Creating...')
                        : (_isEditMode ? AppStrings.save : AppStrings.createJob),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: HermesColors.cyan,
                    foregroundColor: HermesColors.dark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Labeled Field Builder ───

  Widget _buildLabeledField({
    required ThemeData theme,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: HermesColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          minLines: maxLines > 1 ? 3 : 1,
          keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.text,
          autocorrect: false,
          style: TextStyle(color: HermesColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: HermesColors.textDisabled),
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: maxLines > 1 ? 80 : 0),
              child: Icon(icon, color: HermesColors.cyan),
            ),
            filled: true,
            fillColor: HermesColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: HermesColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: HermesColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: HermesColors.cyan, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: HermesColors.error),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // ─── Preset Chips ───

  Widget _buildPresetChips(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _presets.map((preset) {
        return ActionChip(
          label: Text(
            preset.label,
            style: const TextStyle(fontSize: 12),
          ),
          onPressed: _isSubmitting ? null : () => _applyPreset(preset.cron),
          backgroundColor: HermesColors.surface,
          side: BorderSide(
            color: _scheduleController.text == preset.cron
                ? HermesColors.cyan
                : HermesColors.border,
          ),
          labelStyle: TextStyle(
            color: _scheduleController.text == preset.cron
                ? HermesColors.cyan
                : HermesColors.textSecondary,
          ),
        );
      }).toList(),
    );
  }

  // ─── Form Error Banner ───

  Widget _buildFormError(ThemeData theme) {
    final state = ref.watch(taskListProvider);
    if (state.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: HermesColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: HermesColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline,
                  size: 16, color: HermesColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: HermesColors.error,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
