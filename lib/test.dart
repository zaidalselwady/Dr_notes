import 'package:flutter/material.dart';

class ColumnExample extends StatelessWidget {
  const ColumnExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Column Example")),
      body: const Column(
        // ✅ mainAxisAlignment: كيف العناصر بتتوزع عمودياً
        mainAxisAlignment: MainAxisAlignment.center,

        // ✅ crossAxisAlignment: كيف العناصر بتتصّف أفقياً
        crossAxisAlignment: CrossAxisAlignment.start,

        // ✅ mainAxisSize: حجم العمود (min = قد المحتوى، max = ياخذ الشاشة كلها)
        mainAxisSize: MainAxisSize.max,

        children: [
          Text("📌 العنصر الأول"),
          Text("📌 العنصر الثاني"),
          Text("📌 العنصر الثالث"),
        ],
      ),
    );
  }
}
