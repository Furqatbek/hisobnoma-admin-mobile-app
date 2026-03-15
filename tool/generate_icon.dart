// Run with: dart run tool/generate_icon.dart
// Generates app icon PNG: royal blue background with white geometric "H"

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // Fill background with Royal Blue #1E3A8A
  final royalBlue = img.ColorRgba8(0x1E, 0x3A, 0x8A, 0xFF);
  final white = img.ColorRgba8(0xFF, 0xFF, 0xFF, 0xFF);

  img.fill(image, color: royalBlue);

  // Draw geometric "H" letter
  // H dimensions: centered, ~600px tall, ~90px stroke width
  const strokeWidth = 90;
  const hHeight = 600;
  const hWidth = 420;
  const xStart = (size - hWidth) ~/ 2; // 302
  const yStart = (size - hHeight) ~/ 2; // 212

  // Left vertical bar
  img.fillRect(
    image,
    x1: xStart,
    y1: yStart,
    x2: xStart + strokeWidth,
    y2: yStart + hHeight,
    color: white,
  );

  // Right vertical bar
  img.fillRect(
    image,
    x1: xStart + hWidth - strokeWidth,
    y1: yStart,
    x2: xStart + hWidth,
    y2: yStart + hHeight,
    color: white,
  );

  // Horizontal crossbar (centered vertically)
  final crossbarY = yStart + (hHeight - strokeWidth) ~/ 2;
  img.fillRect(
    image,
    x1: xStart,
    y1: crossbarY,
    x2: xStart + hWidth,
    y2: crossbarY + strokeWidth,
    color: white,
  );

  // Save full icon
  final iconFile = File('assets/icon/app_icon.png');
  iconFile.writeAsBytesSync(img.encodePng(image));
  print('Generated: assets/icon/app_icon.png (${size}x$size)');

  // Generate foreground-only (transparent background with white H)
  final foreground = img.Image(width: size, height: size);
  // Transparent background (default)

  // Left vertical bar
  img.fillRect(
    foreground,
    x1: xStart,
    y1: yStart,
    x2: xStart + strokeWidth,
    y2: yStart + hHeight,
    color: white,
  );

  // Right vertical bar
  img.fillRect(
    foreground,
    x1: xStart + hWidth - strokeWidth,
    y1: yStart,
    x2: xStart + hWidth,
    y2: yStart + hHeight,
    color: white,
  );

  // Horizontal crossbar
  img.fillRect(
    foreground,
    x1: xStart,
    y1: crossbarY,
    x2: xStart + hWidth,
    y2: crossbarY + strokeWidth,
    color: white,
  );

  final fgFile = File('assets/icon/app_icon_foreground.png');
  fgFile.writeAsBytesSync(img.encodePng(foreground));
  print('Generated: assets/icon/app_icon_foreground.png (${size}x$size)');
}
