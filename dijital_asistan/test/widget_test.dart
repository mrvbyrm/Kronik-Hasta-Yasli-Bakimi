import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dijital_asistan/main.dart'; // buradaki `MyApp` tanımına göre uyarlamalısın

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Uygulamayı oluştur ve çerçeveyi tetikle
    await tester.pumpWidget(MyApp());

    // Başlangıç değeri 0 olmalı
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // '+' ikonuna tıkla
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Sayacın 1 olması beklenir
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
