// Run with: dart run tool/generate_icon.dart
// Generates a minimal app icon PNG (royal blue background, white H)
// For production, replace with a professionally designed icon

void main() {
  // For a proper icon, use a design tool (Figma, Sketch) to create:
  // - 1024x1024 PNG
  // - Background: #1E3A8A (Royal Blue)
  // - White geometric "H" letter, centered
  // - H dimensions: ~600px tall, ~90px stroke
  //
  // Then run: flutter pub run flutter_launcher_icons
  //
  // This script creates a minimal placeholder.
  print('App Icon Specification:');
  print('  Size: 1024x1024px');
  print('  Background: #1E3A8A (Royal Blue)');
  print('  Foreground: White "H" letter');
  print('  Style: Geometric, modern, minimal');
  print('  Border radius: iOS superellipse (auto)');
  print('  Android: Adaptive icon with royal blue background');
  print('');
  print('Place your designed icon at: assets/icon/app_icon.png');
  print('Place foreground-only at: assets/icon/app_icon_foreground.png');
  print('Then run: dart run flutter_launcher_icons');
}
