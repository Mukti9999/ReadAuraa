import 'package:flutter_tts/flutter_tts.dart';

final FlutterTts _flutterTts = FlutterTts();

bool _ttsInitialized = false;

Future<void> _initializeTts() async {
  if (_ttsInitialized) {
    return;
  }

  // IMPORTANT:
  // This makes the Future returned by speak()
  // wait until the current speech is actually finished.
  await _flutterTts.awaitSpeakCompletion(true);

  // Give Android a comfortable default language.
  await _flutterTts.setLanguage('en-US');

  _ttsInitialized = true;
}

/// ReadAura mobile speech.
///
/// The audiobook screen sends ReadAura playback speed
/// values such as:
///
/// 0.75x
/// 1.0x
/// 1.25x
/// 1.5x
/// 2.0x
///
/// FlutterTTS uses a different rate scale on Android,
/// so we convert the ReadAura speed to a comfortable
/// Android TTS rate.
Future<void> readAuraSpeak(
    String text,
    double rate,
    double pitch,
    double volume,
    ) async {
  await _initializeTts();

  if (text.trim().isEmpty) {
    return;
  }

  // ------------------------------------------------------------
  // READAURA → ANDROID TTS SPEED
  // ------------------------------------------------------------
  //
  // ReadAura 0.75x → Android ~0.34
  // ReadAura 1.00x → Android ~0.45
  // ReadAura 1.25x → Android ~0.56
  // ReadAura 1.50x → Android ~0.67
  // ReadAura 2.00x → Android ~0.90
  //
  // This prevents the Android voice from becoming
  // extremely fast.
  //
  // More importantly, awaitSpeakCompletion(true)
  // ensures the audiobook does NOT jump to the
  // next chunk before this one has finished.

  final double mobileRate =
  (0.45 * rate).clamp(0.20, 0.90);

  await _flutterTts.setSpeechRate(
    mobileRate,
  );

  await _flutterTts.setPitch(
    pitch.clamp(0.5, 2.0),
  );

  await _flutterTts.setVolume(
    volume.clamp(0.0, 1.0),
  );

  // Speak the COMPLETE chunk and WAIT for it to finish.
  await _flutterTts.speak(
    text,
  );
}

/// Stop current audiobook speech.
Future<void> readAuraStop() async {
  await _flutterTts.stop();
}

/// Pause current audiobook speech.
Future<void> readAuraPause() async {
  await _flutterTts.pause();
}

/// Resume current audiobook speech.
///
/// The audiobook screen handles continuation through
/// its chunk system, so we don't start an empty utterance.
Future<void> readAuraResume() async {
  // Intentionally empty.
}