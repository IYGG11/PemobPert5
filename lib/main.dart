import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';

const String nama = 'Masyhuri Yudhistira';
const String nim = '20240801229';

// d = digit terakhir NIM 20240801229 -> d = 9
final int d = int.parse(nim[nim.length - 1]);

final double paddingCard = 16.0 + d; // 16 + 9 = 25
final double roundedCard = 8.0 + d; // 8 + 9 = 17
final double tinggiTombol = 40.0 + d; // 40 + 9 = 49
final double roundedTombol = 4.0 + d; // 4 + 9 = 13

/// Nama Barang wajib diawali inisial nama depan mahasiswa -> 'M'.
final String inisialNama = nama[0].toUpperCase();

/// NIM genap -> 2 angka terakhir, NIM ganjil -> 3 angka terakhir.
/// NIM 20240801229 ganjil (d = 9) -> Kode Barang wajib diawali '229'.
final int jumlahAngkaNim = d.isEven ? 2 : 3;
final String awalanKode = nim.substring(nim.length - jumlahAngkaNim);
const int minDigitKode = 6;

/// Nama collection Firestore tempat data stok barang disimpan.
const String koleksiStokBarang = 'stok_barang';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pencatatan Stok Barang',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const StokBarangPage(),
    );
  }
}

/// Format tanggal sebagai teks dd-MM-yyyy, contoh 16-10-2026.
String formatTanggal(DateTime t) =>
    '${t.day.toString().padLeft(2, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-${t.year}';

class StokBarangPage extends StatefulWidget {
  const StokBarangPage({super.key});

  @override
  State<StokBarangPage> createState() => _StokBarangPageState();
}

class _StokBarangPageState extends State<StokBarangPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _masukController = TextEditingController();
  final TextEditingController _keluarController = TextEditingController();
  final TextEditingController _kodeController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();

  DateTime? _tanggalMasuk;
  DateTime? _tanggalKeluar;
  bool _menyimpan = false;

  @override
  void dispose() {
    _namaController.dispose();
    _masukController.dispose();
    _keluarController.dispose();
    _kodeController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  String? _validasiNama(String? value) {
    final String namaBarang = value?.trim() ?? '';
    if (namaBarang.isEmpty) {
      return 'Nama Barang wajib diisi';
    }
    if (namaBarang[0].toUpperCase() != inisialNama) {
      return 'Nama Barang harus diawali huruf $inisialNama '
          '(inisial nama depan)';
    }
    return null;
  }

  String? _validasiTanggal(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi';
    }
    return null;
  }

  String? _validasiKode(String? value) {
    final String kode = value?.trim() ?? '';
    if (kode.isEmpty) {
      return 'Kode Barang wajib diisi';
    }
    if (!RegExp(r'^\d+$').hasMatch(kode)) {
      return 'Kode Barang harus berupa angka bulat';
    }
    if (kode.length < minDigitKode) {
      return 'Kode Barang minimal $minDigitKode angka';
    }
    if (!kode.startsWith(awalanKode)) {
      return 'Kode Barang harus diawali $awalanKode '
          '($jumlahAngkaNim angka terakhir NIM)';
    }
    if (int.tryParse(kode) == null) {
      return 'Kode Barang terlalu panjang';
    }
    return null;
  }

  String? _validasiStok(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Jumlah Stok wajib diisi';
    }
    final int? stok = int.tryParse(value.trim());
    if (stok == null) {
      return 'Jumlah Stok harus berupa bilangan bulat';
    }
    if (stok < 0) {
      return 'Jumlah Stok tidak boleh negatif';
    }
    return null;
  }

  /// Tanggal dipilih lewat date picker lalu ditulis ke field sebagai teks.
  /// Tanggal keluar tidak bisa lebih awal dari tanggal masuk.
  Future<void> _pilihTanggal({required bool masuk}) async {
    final DateTime batasAwal = masuk
        ? DateTime(2000)
        : (_tanggalMasuk ?? DateTime(2000));
    final DateTime sekarang = DateTime.now();
    final DateTime? terpilih = masuk ? _tanggalMasuk : _tanggalKeluar;

    final DateTime? hasil = await showDatePicker(
      context: context,
      initialDate:
          terpilih ?? (sekarang.isBefore(batasAwal) ? batasAwal : sekarang),
      firstDate: batasAwal,
      lastDate: DateTime(2100),
      helpText: masuk ? 'Pilih Tanggal Masuk' : 'Pilih Tanggal Keluar',
    );
    if (hasil == null) return;

    setState(() {
      if (masuk) {
        _tanggalMasuk = hasil;
        _masukController.text = formatTanggal(hasil);
        if (_tanggalKeluar != null && _tanggalKeluar!.isBefore(hasil)) {
          _tanggalKeluar = null;
          _keluarController.clear();
        }
      } else {
        _tanggalKeluar = hasil;
        _keluarController.text = formatTanggal(hasil);
      }
    });
  }

  Future<void> _simpanBarang() async {
    if (_menyimpan) return;

    // Tutup keyboard dulu supaya pesan error / notifikasi tidak tertutup.
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Color warnaError = Theme.of(context).colorScheme.error;

    // Data diambil dari input pengguna; kode & stok dikonversi String -> int
    // agar tersimpan sebagai Number di Firestore.
    final Map<String, dynamic> dataBarang = {
      'nama_barang': _namaController.text.trim(),
      'tanggal_masuk': _masukController.text.trim(),
      'tanggal_keluar': _keluarController.text.trim(),
      'kode_barang': int.parse(_kodeController.text.trim()),
      'jumlah_stok': int.parse(_stokController.text.trim()),
      'waktu': FieldValue.serverTimestamp(),
    };

    setState(() => _menyimpan = true);

    try {
      await FirebaseFirestore.instance
          .collection(koleksiStokBarang)
          .add(dataBarang);

      // Cukup kosongkan controller. Jangan panggil _formKey.currentState.reset():
      // reset() mengembalikan nilai FormField ke teks lama sehingga validasi
      // "wajib diisi" bisa lolos padahal field terlihat kosong.
      _namaController.clear();
      _masukController.clear();
      _keluarController.clear();
      _kodeController.clear();
      _stokController.clear();
      _tanggalMasuk = null;
      _tanggalKeluar = null;

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Data barang berhasil disimpan'),
            backgroundColor: Colors.green.shade700,
          ),
        );
    } on FirebaseException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan data: ${e.message ?? e.code}'),
            backgroundColor: warnaError,
          ),
        );
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan data: $e'),
            backgroundColor: warnaError,
          ),
        );
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pencatatan Stok Barang')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(roundedCard),
            ),
            child: Padding(
              padding: EdgeInsets.all(paddingCard),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Input Data Barang', style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('$nama · $nim', style: textTheme.bodySmall),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _namaController,
                      decoration: InputDecoration(
                        labelText: 'Nama Barang',
                        hintText: 'Contoh: Mouse Wireless',
                        helperText:
                            'Diawali huruf $inisialNama (inisial nama depan)',
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: _validasiNama,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _masukController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Masuk Barang',
                        hintText: 'Pilih tanggal',
                        prefixIcon: Icon(Icons.login),
                        suffixIcon: Icon(Icons.calendar_month),
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () => _pilihTanggal(masuk: true),
                      validator: (v) =>
                          _validasiTanggal(v, 'Tanggal Masuk Barang'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _keluarController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Keluar Barang',
                        hintText: 'Pilih tanggal',
                        prefixIcon: Icon(Icons.logout),
                        suffixIcon: Icon(Icons.calendar_month),
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () => _pilihTanggal(masuk: false),
                      validator: (v) =>
                          _validasiTanggal(v, 'Tanggal Keluar Barang'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _kodeController,
                      decoration: InputDecoration(
                        labelText: 'Kode Barang',
                        hintText: 'Contoh: ${awalanKode}001',
                        helperText:
                            'Min. $minDigitKode angka, diawali '
                            '$awalanKode ($jumlahAngkaNim angka terakhir NIM)',
                        prefixIcon: const Icon(Icons.qr_code),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: _validasiKode,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stokController,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Stok',
                        hintText: 'Contoh: 25',
                        prefixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      validator: _validasiStok,
                      onFieldSubmitted: (_) => _simpanBarang(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: tinggiTombol,
                      child: FilledButton.icon(
                        onPressed: _menyimpan ? null : _simpanBarang,
                        icon: _menyimpan
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _menyimpan ? 'Menyimpan...' : 'Simpan Barang',
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(roundedTombol),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
