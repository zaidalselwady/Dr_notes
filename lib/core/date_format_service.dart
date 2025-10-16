import 'package:intl/intl.dart';

class DateService {
  /// يفّرمت التاريخ حسب الفورمات، يقبل DateTime أو String
  // static String format(dynamic dateInput, String format) {
  //   DateTime? date;
  //   if (dateInput is DateTime) {
  //     date = dateInput;
  //   } else if (dateInput is String) {
  //     // نجرب نحول String لـ DateTime
  //     try {
  //       date = DateTime.parse(dateInput);
  //     } catch (e) {
  //       // إذا فشل التحويل، نرجع النص كما هو
  //       return dateInput;
  //     }
  //   } else {
  //     // إذا النوع غير متوقع، نرجع فراغ
  //     return '';
  //   }
  //   try {
  //     return DateFormat(format).format(date);
  //   } catch (e) {
  //     // إذا الفورمات خطأ، نرجع شكل افتراضي
  //     return DateFormat('dd-MM-yyyy').format(date);
  //   }
  // }

  static String format(dynamic dateInput, String format) {
    DateTime? date;

    if (dateInput is DateTime) {
      date = dateInput;
    } else if (dateInput is String) {
      // نجرب نحول String لـ DateTime بصيغ محتملة
      final formats = [
        'd/M/yyyy',
        'dd/MM/yyyy',
        'd-M-yyyy',
        'dd-MM-yyyy',
        'yyyy-MM-dd',
        'yyyy/MM/dd',
        'dd/MM/yyyy HH:mm:ss',
        'dd-MM-yyyy HH:mm:ss',
        'yyyy-MM-dd HH:mm:ss',
        'yyyy/MM/dd HH:mm:ss',
      ];
      for (var f in formats) {
        try {
          date = DateFormat(f).parseStrict(dateInput);
          break; // إذا نجح، نكسر اللوب
        } catch (_) {
          continue;
        }
      }
      if (date == null) {
        return dateInput; // إذا ما قدرنا نقرأ النص، نرجع النص كما هو
      }
    } else {
      return '';
    }

    try {
      return DateFormat(format).format(date);
    } catch (_) {
      return DateFormat('dd-MM-yyyy').format(date);
    }
  }
}
