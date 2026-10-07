import 'package:audioplayers/audioplayers.dart';

class MusicTrack {
  final String title;
  final String category;
  final String emoji;
  final String assetPath;

  const MusicTrack({
    required this.title,
    required this.category,
    required this.emoji,
    required this.assetPath,
  });
}

class MusicService {
  // --------------------------------------------------
  // SINGLE SHARED AUDIO PLAYER
  // --------------------------------------------------

  static final AudioPlayer player = AudioPlayer();

  // --------------------------------------------------
  // MUSIC TRACKS
  // --------------------------------------------------

  static const List<MusicTrack> tracks = [
    MusicTrack(
      title: 'Beautiful Dream',
      category: 'Fantasy',
      emoji: '✨',
      assetPath: 'reading_music/beautiful_dream.mp3',
    ),
    MusicTrack(
      title: 'Classical Romance',
      category: 'Romantic',
      emoji: '💗',
      assetPath: 'reading_music/classical_romance.mp3',
    ),
    MusicTrack(
      title: 'Guitar Breeze',
      category: 'Calm',
      emoji: '🌿',
      assetPath: 'reading_music/music_guitar.mp3',
    ),
    MusicTrack(
      title: 'Piano & Rain',
      category: 'Rain',
      emoji: '🌧️',
      assetPath: 'reading_music/piano_and_rain.mp3',
    ),
    MusicTrack(
      title: 'Piano Horror',
      category: 'Mystery',
      emoji: '🕯️',
      assetPath: 'reading_music/piano_horror.mp3',
    ),
    MusicTrack(
      title: 'Piano Reflections',
      category: 'Emotional',
      emoji: '💭',
      assetPath: 'reading_music/piano_reflections.mp3',
    ),
    MusicTrack(
      title: 'Reading Music',
      category: 'Focus',
      emoji: '📖',
      assetPath: 'reading_music/reading_music.mp3',
    ),
    MusicTrack(
      title: 'Soft Music',
      category: 'Sleep',
      emoji: '🌙',
      assetPath: 'reading_music/soft_music.mp3',
    ),
  ];

  // --------------------------------------------------
  // SHARED MUSIC STATE
  // --------------------------------------------------

  static int selectedTrackIndex = 0;

  static double volume = 0.5;

  static bool isPlaying = false;

  static bool _initialized = false;

  // --------------------------------------------------
  // INITIALIZE SERVICE
  // --------------------------------------------------

  static void initialize() {
    if (_initialized) {
      return;
    }

    _initialized = true;

    player.onPlayerComplete.listen((event) {
      playNextTrack();
    });
  }

  // --------------------------------------------------
  // CURRENT TRACK
  // --------------------------------------------------

  static MusicTrack get selectedTrack {
    return tracks[selectedTrackIndex];
  }

  // --------------------------------------------------
  // PLAY TRACK
  // --------------------------------------------------

  static Future<void> playTrack(int index) async {
    try {
      if (index < 0 || index >= tracks.length) {
        return;
      }

      selectedTrackIndex = index;

      final MusicTrack track = tracks[index];

      await player.stop();

      await player.setVolume(volume);

      await player.play(
        AssetSource(track.assetPath),
      );

      isPlaying = true;
    } catch (e) {
      isPlaying = false;

      print('Music Error: $e');
    }
  }

  // --------------------------------------------------
  // PAUSE
  // --------------------------------------------------

  static Future<void> pauseMusic() async {
    try {
      await player.pause();

      isPlaying = false;
    } catch (e) {
      print('Pause Error: $e');
    }
  }

  // --------------------------------------------------
  // RESUME
  // --------------------------------------------------

  static Future<void> resumeMusic() async {
    try {
      await player.resume();

      isPlaying = true;
    } catch (e) {
      print('Resume Error: $e');

      await playTrack(selectedTrackIndex);
    }
  }

  // --------------------------------------------------
  // PLAY / PAUSE
  // --------------------------------------------------

  static Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pauseMusic();
    } else {
      await resumeMusic();
    }
  }

  // --------------------------------------------------
  // NEXT TRACK
  // --------------------------------------------------

  static Future<void> playNextTrack() async {
    int nextIndex = selectedTrackIndex + 1;

    if (nextIndex >= tracks.length) {
      nextIndex = 0;
    }

    await playTrack(nextIndex);
  }

  // --------------------------------------------------
  // VOLUME
  // --------------------------------------------------

  static Future<void> changeVolume(double value) async {
    volume = value;

    await player.setVolume(value);
  }

  // --------------------------------------------------
  // STOP MUSIC
  // --------------------------------------------------

  static Future<void> stopMusic() async {
    try {
      await player.stop();

      isPlaying = false;
    } catch (e) {
      print('Stop Music Error: $e');
    }
  }
}