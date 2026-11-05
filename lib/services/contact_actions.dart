import 'package:url_launcher/url_launcher.dart';

import '../models.dart';

/// One-tap contact actions. WhatsApp opens with a prefilled message;
/// full auto-send is not possible without the paid WhatsApp Business
/// API, so the human taps send, which also keeps the account safe.
class ContactActions {
  static String _digits(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');

  static String followUpMessage(Lead lead, {String? businessName}) {
    final first = lead.name.split(' ').first;
    final from = (businessName != null && businessName.isNotEmpty)
        ? ' from $businessName'
        : '';
    switch (lead.stageLabel) {
      case 'Day 1 follow-up':
        return 'Hi $first, this is a quick follow-up$from. Did you get a chance to think about it? Happy to answer any questions.';
      case 'Day 3 follow-up':
        return 'Hi $first, circling back$from. If it helps, I can walk you through exactly what you get and the price, no pressure either way.';
      case 'Day 7 follow-up':
        return 'Hi $first, last follow-up from me$from. If the timing is not right, no problem at all. If you are still interested, I can hold your slot this week.';
      default:
        return 'Hi $first, checking in$from. Still happy to help whenever you are ready.';
    }
  }

  static Future<bool> openWhatsApp(Lead lead, {String? businessName}) async {
    final phone = lead.phone;
    if (phone == null || phone.isEmpty) return false;
    final text = Uri.encodeComponent(followUpMessage(lead, businessName: businessName));
    final uri = Uri.parse('https://wa.me/${_digits(phone)}?text=$text');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> call(Lead lead) async {
    final phone = lead.phone;
    if (phone == null || phone.isEmpty) return false;
    return launchUrl(Uri.parse('tel:+${_digits(phone)}'));
  }
}
