import 'package:intl/intl.dart';

class DateService {
  /// يفّرمت التاريخ حسب الفورمات، يقبل DateTime أو String
  static String format(dynamic dateInput, String format) {
    DateTime? date;

    if (dateInput is DateTime) {
      date = dateInput;
    } else if (dateInput is String) {
      // نجرب نحول String لـ DateTime
      try {
        date = DateTime.parse(dateInput);
      } catch (e) {
        // إذا فشل التحويل، نرجع النص كما هو
        return dateInput;
      }
    } else {
      // إذا النوع غير متوقع، نرجع فراغ
      return '';
    }

    try {
      return DateFormat(format).format(date);
    } catch (e) {
      // إذا الفورمات خطأ، نرجع شكل افتراضي
      return DateFormat('dd-MM-yyyy').format(date);
    }
  }
}
