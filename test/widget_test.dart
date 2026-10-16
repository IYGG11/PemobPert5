import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pertemuan4pemob/main.dart';

// Firestore hanya dipanggil setelah validasi lolos, jadi test validasi di bawah
// tidak membutuhkan Firebase.
void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  TextField textFieldOf(WidgetTester tester, String label) => tester.widget(
    find.descendant(of: field(label), matching: find.byType(TextField)),
  );

  // Layar tinggi supaya seluruh form (5 field + pesan error) muat tanpa scroll.
  Future<void> bukaApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyApp());
  }

  Future<void> tekanSimpan(WidgetTester tester) async {
    await tester.tap(find.text('Simpan Barang'));
    await tester.pump();
  }

  test('Aturan diturunkan dari nama dan NIM', () {
    expect(inisialNama, 'M');
    expect(jumlahAngkaNim, 3); // NIM 20240801229 ganjil
    expect(awalanKode, '229');
  });

  testWidgets('Form punya 5 field dan keyboard numerik', (
    WidgetTester tester,
  ) async {
    await bukaApp(tester);

    for (final String label in [
      'Nama Barang',
      'Tanggal Masuk Barang',
      'Tanggal Keluar Barang',
      'Kode Barang',
      'Jumlah Stok',
    ]) {
      expect(field(label), findsOneWidget, reason: label);
    }
    expect(find.text('Simpan Barang'), findsOneWidget);

    expect(
      textFieldOf(tester, 'Kode Barang').keyboardType,
      TextInputType.number,
    );
    expect(
      textFieldOf(tester, 'Jumlah Stok').keyboardType,
      TextInputType.number,
    );
    expect(textFieldOf(tester, 'Tanggal Masuk Barang').readOnly, isTrue);
  });

  testWidgets('Semua field wajib diisi', (WidgetTester tester) async {
    await bukaApp(tester);
    await tekanSimpan(tester);

    expect(find.text('Nama Barang wajib diisi'), findsOneWidget);
    expect(find.text('Tanggal Masuk Barang wajib diisi'), findsOneWidget);
    expect(find.text('Tanggal Keluar Barang wajib diisi'), findsOneWidget);
    expect(find.text('Kode Barang wajib diisi'), findsOneWidget);
    expect(find.text('Jumlah Stok wajib diisi'), findsOneWidget);
  });

  testWidgets('Nama diawali M, kode min 6 angka diawali 229, stok >= 0', (
    WidgetTester tester,
  ) async {
    await bukaApp(tester);

    await tester.enterText(field('Nama Barang'), 'Pulpen');
    await tester.enterText(field('Kode Barang'), '22901');
    await tester.enterText(field('Jumlah Stok'), '-3');
    await tekanSimpan(tester);

    expect(
      find.text('Nama Barang harus diawali huruf M (inisial nama depan)'),
      findsOneWidget,
    );
    expect(find.text('Kode Barang minimal 6 angka'), findsOneWidget);
    expect(find.text('Jumlah Stok tidak boleh negatif'), findsOneWidget);

    await tester.enterText(field('Nama Barang'), 'mouse');
    await tester.enterText(field('Kode Barang'), '123456');
    await tester.enterText(field('Jumlah Stok'), 'abc');
    await tekanSimpan(tester);

    expect(find.textContaining('Nama Barang harus diawali'), findsNothing);
    expect(
      find.text('Kode Barang harus diawali 229 (3 angka terakhir NIM)'),
      findsOneWidget,
    );
    expect(
      find.text('Jumlah Stok harus berupa bilangan bulat'),
      findsOneWidget,
    );

    await tester.enterText(field('Kode Barang'), '229.01');
    await tekanSimpan(tester);
    expect(find.text('Kode Barang harus berupa angka bulat'), findsOneWidget);

    await tester.enterText(field('Kode Barang'), '229001');
    await tekanSimpan(tester);
    expect(find.textContaining('Kode Barang harus'), findsNothing);
    expect(find.textContaining('Kode Barang minimal'), findsNothing);
  });

  testWidgets('Tanggal diisi lewat date picker sebagai teks', (
    WidgetTester tester,
  ) async {
    await bukaApp(tester);

    await tester.tap(field('Tanggal Masuk Barang'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Tanggal Masuk'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final String hariIni = formatTanggal(DateTime.now());
    expect(
      find.descendant(
        of: field('Tanggal Masuk Barang'),
        matching: find.text(hariIni),
      ),
      findsOneWidget,
    );
  });
}
