import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Create optimized launcher icon and splash assets from original nammalvar.jpeg', () async {
    final rawBytes = File('assets/images/nammalvar.jpeg').readAsBytesSync();
    final codec = await ui.instantiateImageCodec(rawBytes);
    final frame = await codec.getNextFrame();
    final originalImg = frame.image;

    final origW = originalImg.width.toDouble();
    final origH = originalImg.height.toDouble();

    // =========================================================================
    // 1. LAUNCHER FOREGROUND (1024 x 1024)
    // Safe area diameter: 66% = ~675px.
    // We scale so full head, forehead, eyes, beard, green shawl fit inside safe circle.
    // =========================================================================
    Uint8List launcherBytes;
    {
      const canvasSize = 1024.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, canvasSize, canvasSize));

      final targetW = 600.0;
      final targetH = targetW * (origH / origW); // ~703px

      final destX = (canvasSize - targetW) / 2.0; // 212
      final destY = 190.0; // shifted slightly down so head top is well below circle boundary

      final paint = Paint()..filterQuality = FilterQuality.high;
      canvas.drawImageRect(
        originalImg,
        Rect.fromLTWH(0, 0, origW, origH),
        Rect.fromLTWH(destX, destY, targetW, targetH),
        paint,
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      launcherBytes = byteData!.buffer.asUint8List();
      File('assets/images/nammalvar_launcher_fg.png').writeAsBytesSync(launcherBytes);
    }

    // =========================================================================
    // 2. SPLASH IMAGE (for center of splash screen and Android 12+)
    // 800 x 800 square, full face, forehead, beard, shawl visible, shifted slightly lower.
    // =========================================================================
    Uint8List splashBytes;
    {
      const splashCanvasW = 800.0;
      const splashCanvasH = 800.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, splashCanvasW, splashCanvasH));

      final targetW = 540.0;
      final targetH = targetW * (origH / origW); // ~633px

      final destX = (splashCanvasW - targetW) / 2.0; // 130
      final destY = 90.0; // shifted slightly lower

      final paint = Paint()..filterQuality = FilterQuality.high;
      canvas.drawImageRect(
        originalImg,
        Rect.fromLTWH(0, 0, origW, origH),
        Rect.fromLTWH(destX, destY, targetW, targetH),
        paint,
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(splashCanvasW.toInt(), splashCanvasH.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      splashBytes = byteData!.buffer.asUint8List();
      File('assets/images/nammalvar_splash_img.png').writeAsBytesSync(splashBytes);
    }

    // =========================================================================
    // 3. 1x1 Pure White Background PNG (to ensure white background everywhere)
    // =========================================================================
    Uint8List whiteBgBytes;
    {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 16, 16));
      canvas.drawColor(Colors.white, BlendMode.src);
      final picture = recorder.endRecording();
      final img = await picture.toImage(16, 16);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      whiteBgBytes = byteData!.buffer.asUint8List();
    }

    // =========================================================================
    // 4. DEPLOY TO ALL ANDROID DRAWABLE DIRS
    // =========================================================================
    final resDir = Directory('android/app/src/main/res');
    if (resDir.existsSync()) {
      for (final entity in resDir.listSync()) {
        if (entity is Directory) {
          final dirName = entity.path.split(Platform.pathSeparator).last;
          if (dirName.startsWith('drawable')) {
            // Write background.png as pure white
            File('${entity.path}/background.png').writeAsBytesSync(whiteBgBytes);

            // Write splash.png
            File('${entity.path}/splash.png').writeAsBytesSync(splashBytes);

            // If v31, write android12splash.png
            if (dirName.contains('v31')) {
              File('${entity.path}/android12splash.png').writeAsBytesSync(splashBytes);
            }
          }
        }
      }
    }

    expect(File('assets/images/nammalvar_launcher_fg.png').existsSync(), isTrue);
    expect(File('assets/images/nammalvar_splash_img.png').existsSync(), isTrue);
  });
}
