import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../ladder.dart';
import '../models.dart';

/// On-device reminder notifications for the follow-up ladder.
/// Scheduled at 09:30 local time on each due day. No server needed.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  static int _idFor(Lead lead, int slot) =>
      (lead.id.hashCode & 0x3fffffff) * 8 + slot;

  /// (Re)schedule the next ladder reminders for a lead at 09:30 local.
  static Future<void> scheduleForLead(Lead lead) async {
    if (!_ready) return;
    await cancelForLead(lead);
    if (lead.isClosed) return;
    final now = DateTime.now();
    final anchor = lead.ladderAnchor;
    final times = Ladder.upcoming(anchor, now, count: 4);
    for (var i = 0; i < times.length; i++) {
      var when = times[i].copyWith(hour: 9, minute: 30, second: 0);
      if (when.isBefore(now)) when = times[i];
      final stage = Ladder.stageFor(anchor, times[i]);
      await _plugin.zonedSchedule(
        _idFor(lead, i),
        'Follow up with ${lead.name}',
        '$stage follow-up is due. One tap opens WhatsApp.',
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'followups',
            'Follow-up reminders',
            channelDescription: 'Day 1 / 3 / 7 lead follow-up reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelForLead(Lead lead) async {
    if (!_ready) return;
    for (var i = 0; i < 4; i++) {
      await _plugin.cancel(_idFor(lead, i));
    }
  }
}
