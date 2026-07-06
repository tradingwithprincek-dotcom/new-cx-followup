import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/notifications/notification_service.dart';
import '../domain/follow_up.dart';
import 'follow_up_providers.dart';

/// Handles both Create and Edit — pass `existing` to edit, omit it to create.
class CreateEditFollowUpScreen extends ConsumerStatefulWidget {
  const CreateEditFollowUpScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    this.existing,
  });

  final String customerId;
  final String customerName;
  final FollowUp? existing;

  @override
  ConsumerState<CreateEditFollowUpScreen> createState() => _CreateEditFollowUpScreenState();
}

class _CreateEditFollowUpScreenState extends ConsumerState<CreateEditFollowUpScreen> {
  late FollowUpType _type;
  late FollowUpPriority _priority;
  late DateTime _reminderDate;
  late TimeOfDay _reminderTime;
  late final TextEditingController _notesController;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type ?? FollowUpType.call;
    _priority = existing?.priority ?? FollowUpPriority.medium;
    final reminderAt = existing?.reminderAt ?? DateTime.now().add(const Duration(hours: 1));
    _reminderDate = DateTime(reminderAt.year, reminderAt.month, reminderAt.day);
    _reminderTime = TimeOfDay(hour: reminderAt.hour, minute: reminderAt.minute);
    _notesController = TextEditingController(text: existing?.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  DateTime get _combinedReminderAt => DateTime(
        _reminderDate.year,
        _reminderDate.month,
        _reminderDate.day,
        _reminderTime.hour,
        _reminderTime.minute,
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _reminderDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(followUpRepositoryProvider);
    try {
      final FollowUp saved;
      if (_isEditing) {
        saved = await repo.update(
          widget.existing!.id,
          type: _type,
          priority: _priority,
          reminderAt: _combinedReminderAt,
          notes: _notesController.text.trim(),
        );
      } else {
        saved = await repo.create(
          customerId: widget.customerId,
          type: _type,
          priority: _priority,
          reminderAt: _combinedReminderAt,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }

      await NotificationService.instance.scheduleFollowUpReminder(
        followUpId: saved.id,
        customerName: widget.customerName,
        typeLabel: followUpTypeLabel(saved.type),
        reminderAt: saved.reminderAt,
      );

      ref.invalidate(followUpListProvider);
      ref.invalidate(followUpDashboardProvider);
      ref.invalidate(customerFollowUpsProvider(widget.customerId));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save follow-up.\n$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Follow-up' : 'Create Follow-up')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('For ${widget.customerName}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          Text('Type', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<FollowUpType>(
            segments: const [
              ButtonSegment(value: FollowUpType.call, icon: Icon(Icons.call_outlined), label: Text('Call')),
              ButtonSegment(
                  value: FollowUpType.whatsapp, icon: Icon(Icons.chat_bubble_outline), label: Text('WhatsApp')),
              ButtonSegment(
                  value: FollowUpType.visit, icon: Icon(Icons.storefront_outlined), label: Text('Visit')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 20),
          Text('Priority', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<FollowUpPriority>(
            segments: const [
              ButtonSegment(value: FollowUpPriority.low, label: Text('Low')),
              ButtonSegment(value: FollowUpPriority.medium, label: Text('Medium')),
              ButtonSegment(value: FollowUpPriority.high, label: Text('High')),
            ],
            selected: {_priority},
            onSelectionChanged: (s) => setState(() => _priority = s.first),
          ),
          const SizedBox(height: 20),
          Text('Reminder', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${_reminderDate.year}-${_reminderDate.month.toString().padLeft(2, '0')}-${_reminderDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time_outlined),
                  label: Text(_reminderTime.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Notes', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'What should you remember for this follow-up?'),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isEditing ? 'Save changes' : 'Create follow-up'),
          ),
        ],
      ),
    );
  }
}
