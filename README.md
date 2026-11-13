# LeadLoop

A follow-up app for tiny teams and solo sellers. Most sales are lost because nobody followed up, not because the offer was bad. LeadLoop makes the follow-up the system: every lead gets a day 1, day 3 and day 7 nudge, then a weekly check-in, until it is won or lost.

Built with Flutter and Supabase. Real accounts, real database, real reminders on the phone. No demo mode.

There is no web demo. LeadLoop is an Android app, install the APK below.

## Download the APK

Download the APK from the [v0.1.0 release](https://github.com/CodeByPartho/leadloop/releases) on GitHub.

## Run it

```bash
flutter pub get
flutter run
```

Supabase setup and Android notification notes are in docs-android-setup.md, and the database schema is in schema.sql.

## What it does

- Add a lead in seconds: name, WhatsApp number, where they came from, deal value
- Due Today screen shows exactly who needs a follow-up and which payments are due
- One tap opens WhatsApp with the follow-up message already written for that stage (day 1 is gentle, day 7 is a polite last call)
- Reminder notifications at 9:30 AM on every due day, scheduled on the device
- Payment tracking per lead: amount, due date, overdue flags, mark paid
- Timeline on every lead: messages sent, calls, notes, status changes, payments
- Every user only sees their own leads. Row-level security enforces it in the database, not just in the app

## Stack

- Flutter (Android first)
- Supabase: Postgres, email auth, row-level security
- flutter_local_notifications for the on-device reminder ladder

## Status

v0.1. Auth, leads, the follow-up ladder, WhatsApp actions, payments and notifications are in. Schema lives in schema.sql. Android notification receivers and desugaring notes are in docs-android-setup.md.
