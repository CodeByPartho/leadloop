# LeadLoop

A follow-up app for tiny teams and solo sellers. Most sales are lost because nobody followed up, not because the offer was bad. LeadLoop makes the follow-up the system: every lead gets a day 1, day 3 and day 7 nudge, then a weekly check-in, until it is won or lost.

Built with Flutter and Supabase. Real accounts, real database, real reminders on the phone. No demo mode.

There is no web demo. LeadLoop is an Android app, install the APK below.

## Download the APK

Download the APK from the [v0.2.0 release](https://github.com/CodeByPartho/leadloop/releases) on GitHub.

## Run it

```bash
flutter pub get
flutter run
```

Supabase setup and Android notification notes are in docs-android-setup.md, and the database schema is in schema.sql.

## What it does

- Add a lead in seconds: name, WhatsApp number, where they came from, deal value
- Duplicate warning: saving a lead with a phone number or a name and source that already exists asks first, so the same person is not added twice
- Phone and deal value are validated in the form (a number that is too short or a value that is not positive is rejected with a plain message)
- Search finds leads by name, phone number or source, and the list sorts by next due date, newest first, or highest value
- Pipeline strip on the leads list: counts per stage, open pipeline value per currency, and win rate over decided leads
- Follow-up ladder restarts from every contact: after you talk to a lead, the next nudge is day 1 after that contact, then day 3 and day 7. Earlier versions counted from creation only
- Snooze a follow-up by 1 or 3 days, and edit a lead's details from its page
- Due Today screen shows exactly who needs a follow-up and which payments are due
- One tap opens WhatsApp with the follow-up message already written for that stage (day 1 is gentle, day 7 is a polite last call)
- Reminder notifications at 9:30 AM on every due day, scheduled on the device
- Payment tracking per lead: amount, due date, overdue flags, mark paid
- Payments report: outstanding, overdue, received this month and due this month, each total kept per currency (currencies are never added together)
- CSV export for leads and payments: copies a spreadsheet-ready CSV to the clipboard, no account or server needed
- Timeline on every lead: messages sent, calls, notes, status changes, payments
- Every user only sees their own leads. Row-level security enforces it in the database, not just in the app

## Stack

- Flutter (Android first)
- Supabase: Postgres, email auth, row-level security
- flutter_local_notifications for the on-device reminder ladder

## Status

v0.2.0. Auth, leads, the follow-up ladder, WhatsApp actions, payments and notifications are in, plus the v0.2.0 additions listed above. Schema lives in schema.sql. No schema change was needed for v0.2.0: every new feature uses columns that already exist. Android notification receivers and desugaring notes are in docs-android-setup.md.

Live Supabase check: the live project could not be reached from the build machine, so the live database and sign-in were not verified for this release. The code uses the real Supabase project and anon key only, with row-level security in schema.sql. Apply schema.sql in the Supabase dashboard if it has not been applied yet, and verify sign-in from a device that can reach the project.
