import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'dart:math';

class ExcelHelper {
  // --- مولد المعرفات السحري (لحل مشكلة Not-Null Constraint) ---
  static String _generateUuid() {
    final random = Random();
    const hexDigits = "0123456789abcdef";
    String uuid = "";
    for (int i = 0; i < 36; i++) {
      if (i == 8 || i == 13 || i == 18 || i == 23) {
        uuid += "-";
      } else if (i == 14) {
        uuid += "4";
      } else if (i == 19) {
        uuid += hexDigits[(random.nextInt(16) & 0x3) | 0x8];
      } else {
        uuid += hexDigits[random.nextInt(16)];
      }
    }
    return uuid;
  }

  static List<Map<String, dynamic>> parseStudentsExcel(Uint8List bytes) {
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> students = [];

    var table = excel.tables.keys.first;
    var sheet = excel.tables[table]!;

    // نتجاوز الصف الأول (لأنه مخصص لعناوين الأعمدة)
    for (var i = 1; i < sheet.rows.length; i++) {
      var row = sheet.rows[i];
      
      // إذا كان الصف فارغ أو الاسم غير موجود، نتجاوزه
      if (row.isEmpty || row[0]?.value == null) continue;

      students.add({
        'id': _generateUuid(), // <--- الحقنة السحرية التي ستحل الخطأ
        'name': row[0]?.value?.toString().trim() ?? 'بدون اسم',
        'email': row[1]?.value?.toString().trim() ?? '',
        'student_id': row[2]?.value?.toString().trim() ?? '',
        'department': row[3]?.value?.toString().trim() ?? '',
        'year': int.tryParse(row[4]?.value?.toString() ?? '1') ?? 1,
        'role': 'student',
      });
    }
    return students;
  }
}