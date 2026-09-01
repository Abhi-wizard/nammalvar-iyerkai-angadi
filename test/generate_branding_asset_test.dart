import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Verify splash branding asset exists and has valid PNG signature', () {
    final file = File('assets/images/nammalvar_branding.png');
    expect(file.existsSync(), isTrue);
    final bytes = file.readAsBytesSync();
    expect(bytes.length, greaterThan(1000));
    // Verify PNG header: 0x89, 0x50, 0x4E, 0x47
    expect(bytes[0], 0x89);
    expect(bytes[1], 0x50);
    expect(bytes[2], 0x4E);
    expect(bytes[3], 0x47);
  });
}
