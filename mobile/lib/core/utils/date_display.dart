import 'package:intl/intl.dart';

class DateDisplay {
  DateDisplay._();

  static final _in = DateFormat('yyyy-MM-dd');
  static final _out = DateFormat('dd/MM/yyyy');

  static String formatPurchaseDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      return _out.format(_in.parse(raw.split('T').first));
    } catch (_) {
      return raw;
    }
  }
}
