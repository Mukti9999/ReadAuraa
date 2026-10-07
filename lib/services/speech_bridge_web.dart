import 'dart:js_interop';

@JS('readAuraSpeak')
external JSPromise<JSAny?> _readAuraSpeak(
    String text,
    double rate,
    double pitch,
    double volume,
    );

@JS('readAuraStop')
external void _readAuraStop();

@JS('readAuraPause')
external void _readAuraPause();

@JS('readAuraResume')
external void _readAuraResume();

Future<void> readAuraSpeak(
    String text,
    double rate,
    double pitch,
    double volume,
    ) async {
  await _readAuraSpeak(
    text,
    rate,
    pitch,
    volume,
  ).toDart;
}

void readAuraStop() {
  _readAuraStop();
}

void readAuraPause() {
  _readAuraPause();
}

void readAuraResume() {
  _readAuraResume();
}