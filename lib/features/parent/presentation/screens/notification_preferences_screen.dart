import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';

/// Notification Preferences — lets parents control push and email notifications.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _newStoryNotifications = true;
  bool _streakReminders = true;
  bool _weeklyReportEmail = false;
  bool _quietHoursEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 21, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _isLoading = false);
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('parents')
          .doc(uid)
          .collection('settings')
          .doc('notifications')
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _newStoryNotifications = data['newStoryNotifications'] as bool? ?? true;
          _streakReminders = data['streakReminders'] as bool? ?? true;
          _weeklyReportEmail = data['weeklyReportEmail'] as bool? ?? false;
          _quietHoursEnabled = data['quietHoursEnabled'] as bool? ?? false;
        });
      }
    } catch (_) {
      // Use defaults
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('parents')
          .doc(uid)
          .collection('settings')
          .doc('notifications')
          .set({
        'newStoryNotifications': _newStoryNotifications,
        'streakReminders': _streakReminders,
        'weeklyReportEmail': _weeklyReportEmail,
        'quietHoursEnabled': _quietHoursEnabled,
        'quietHoursStart':
            '${_quietStart.hour}:${_quietStart.minute.toString().padLeft(2, '0')}',
        'quietHoursEnd':
            '${_quietEnd.hour}:${_quietEnd.minute.toString().padLeft(2, '0')}',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved'),
            backgroundColor: TaleColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save preferences. Try again.'),
            backgroundColor: TaleColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF2E2720),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2E2720)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePreferences,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: TaleColors.terracotta,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _SectionLabel('Push Notifications'),
                SwitchListTile(
                  title: const Text(
                    'New Stories',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Get notified when new stories are published',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                  ),
                  value: _newStoryNotifications,
                  activeColor: TaleColors.terracotta,
                  onChanged: (v) =>
                      setState(() => _newStoryNotifications = v),
                ),
                SwitchListTile(
                  title: const Text(
                    'Reading Streak Reminders',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Daily reminder to keep your child\'s streak alive',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                  ),
                  value: _streakReminders,
                  activeColor: TaleColors.terracotta,
                  onChanged: (v) => setState(() => _streakReminders = v),
                ),
                _SectionLabel('Email'),
                SwitchListTile(
                  title: const Text(
                    'Weekly Reading Report',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Get a weekly summary of your child\'s reading',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                  ),
                  value: _weeklyReportEmail,
                  activeColor: TaleColors.terracotta,
                  onChanged: (v) => setState(() => _weeklyReportEmail = v),
                ),
                _SectionLabel('Quiet Hours'),
                SwitchListTile(
                  title: const Text(
                    'Enable Quiet Hours',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Suppress all notifications during this window',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                  ),
                  value: _quietHoursEnabled,
                  activeColor: TaleColors.terracotta,
                  onChanged: (v) => setState(() => _quietHoursEnabled = v),
                ),
                if (_quietHoursEnabled) ...[
                  ListTile(
                    title: const Text(
                      'Quiet From',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 15),
                    ),
                    trailing: Text(
                      _quietStart.format(context),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: TaleColors.terracotta,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _quietStart,
                      );
                      if (t != null && mounted) {
                        setState(() => _quietStart = t);
                      }
                    },
                  ),
                  ListTile(
                    title: const Text(
                      'Quiet Until',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 15),
                    ),
                    trailing: Text(
                      _quietEnd.format(context),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: TaleColors.terracotta,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _quietEnd,
                      );
                      if (t != null && mounted) {
                        setState(() => _quietEnd = t);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8C7B64),
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
