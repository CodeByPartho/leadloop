import 'models.dart';
import 'validation.dart';

/// Duplicate-lead prevention. Two leads are the same person when they
/// share a phone number (digits only, so formatting differences do not
/// hide a match), or when name and source both match ignoring case and
/// surrounding spaces. Name-only matches are NOT flagged: two
/// different people can share a name.
Lead? findDuplicate(
  List<Lead> existing, {
  required String name,
  String? phone,
  String? source,
}) {
  final digits = normalizePhoneDigits(phone);
  final cleanName = name.trim().toLowerCase();
  final cleanSource = (source ?? '').trim().toLowerCase();
  for (final lead in existing) {
    if (digits.isNotEmpty &&
        normalizePhoneDigits(lead.phone) == digits) {
      return lead;
    }
    if (cleanSource.isNotEmpty &&
        lead.name.trim().toLowerCase() == cleanName &&
        (lead.source ?? '').trim().toLowerCase() == cleanSource) {
      return lead;
    }
  }
  return null;
}
