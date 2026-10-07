import 'package:flutter/material.dart';

import '../services/music_service.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  String selectedCategory = 'All';

  final List<String> categories = const [
    'All',
    'Calm',
    'Rain',
    'Focus',
    'Romantic',
    'Fantasy',
    'Emotional',
    'Mystery',
    'Sleep',
  ];

  List<MusicTrack> get filteredTracks {
    if (selectedCategory == 'All') {
      return MusicService.tracks;
    }

    return MusicService.tracks
        .where(
          (track) => track.category == selectedCategory,
    )
        .toList();
  }

  @override
  void initState() {
    super.initState();

    MusicService.initialize();
  }

  Future<void> playTrack(int index) async {
    await MusicService.playTrack(index);

    if (!mounted) return;

    setState(() {});
  }

  Future<void> togglePlayPause() async {
    await MusicService.togglePlayPause();

    if (!mounted) return;

    setState(() {});
  }

  Future<void> changeVolume(double value) async {
    await MusicService.changeVolume(value);

    if (!mounted) return;

    setState(() {});
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Romantic':
        return const Color(0xFFF7DDE7);

      case 'Rain':
        return const Color(0xFFDDEAF5);

      case 'Focus':
        return const Color(0xFFDDEBDD);

      case 'Fantasy':
        return const Color(0xFFFFE7B8);

      case 'Emotional':
        return const Color(0xFFFFDFC8);

      case 'Mystery':
        return const Color(0xFFE1D9E5);

      case 'Sleep':
        return const Color(0xFFE8DDF1);

      case 'Calm':
      default:
        return const Color(0xFFE8DDF1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<MusicTrack> visibleTracks = filteredTracks;

    final MusicTrack selectedTrack =
        MusicService.selectedTrack;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FC),

      appBar: AppBar(
        title: const Text(
          'Reading Music 🎵',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B5B7B),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFF9FC),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),

            // --------------------------------------------------
            // CURRENT TRACK
            // --------------------------------------------------

            Container(
              height: 165,
              width: 165,
              decoration: const BoxDecoration(
                color: Color(0xFFE8DDF1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  selectedTrack.emoji,
                  style: const TextStyle(
                    fontSize: 65,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            Text(
              selectedTrack.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              '${selectedTrack.category} • Reading ambience',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9A8FA3),
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // PLAY / PAUSE
            // --------------------------------------------------

            GestureDetector(
              onTap: togglePlayPause,
              child: Container(
                height: 65,
                width: 65,
                decoration: const BoxDecoration(
                  color: Color(0xFFC8B6E2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  MusicService.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 38,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // VOLUME
            // --------------------------------------------------

            Row(
              children: [
                const Icon(
                  Icons.volume_down_rounded,
                  color: Color(0xFF6B5B7B),
                ),

                Expanded(
                  child: Slider(
                    value: MusicService.volume,
                    min: 0.0,
                    max: 1.0,
                    activeColor:
                    const Color(0xFFC8B6E2),
                    onChanged: changeVolume,
                  ),
                ),

                const Icon(
                  Icons.volume_up_rounded,
                  color: Color(0xFF6B5B7B),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              MusicService.isPlaying
                  ? '♪ ${selectedTrack.title} is playing'
                  : 'Music is paused',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9A8FA3),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 30),

            // --------------------------------------------------
            // TITLE
            // --------------------------------------------------

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose your reading vibe 🎧',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B5B7B),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // --------------------------------------------------
            // CATEGORY FILTERS
            // --------------------------------------------------

            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final String category =
                  categories[index];

                  final bool isSelected =
                      selectedCategory == category;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    child: Container(
                      margin:
                      const EdgeInsets.only(
                        right: 10,
                      ),
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(
                          0xFFC8B6E2,
                        )
                            : Colors.white,
                        borderRadius:
                        BorderRadius.circular(
                          15,
                        ),
                        border: Border.all(
                          color: const Color(
                            0xFFE8DDF1,
                          ),
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                          FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(
                            0xFF7D7183,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // --------------------------------------------------
            // TRACK LIST
            // --------------------------------------------------

            ListView.builder(
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              itemCount: visibleTracks.length,
              itemBuilder: (context, index) {
                final MusicTrack track =
                visibleTracks[index];

                final int actualIndex =
                MusicService.tracks.indexOf(
                  track,
                );

                final bool isCurrent =
                    MusicService.selectedTrackIndex ==
                        actualIndex;

                return GestureDetector(
                  onTap: () {
                    playTrack(actualIndex);
                  },
                  child: Container(
                    margin:
                    const EdgeInsets.only(
                      bottom: 12,
                    ),
                    padding:
                    const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? _categoryColor(
                        track.category,
                      )
                          : Colors.white,
                      borderRadius:
                      BorderRadius.circular(
                        18,
                      ),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(
                          0xFFC8B6E2,
                        )
                            : const Color(
                          0xFFF0EAF3,
                        ),
                        width:
                        isCurrent ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 52,
                          width: 52,
                          decoration:
                          BoxDecoration(
                            color:
                            _categoryColor(
                              track.category,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(
                              15,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              track.emoji,
                              style:
                              const TextStyle(
                                fontSize: 25,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 13),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow:
                                TextOverflow
                                    .ellipsis,
                                style:
                                const TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                  FontWeight
                                      .w700,
                                  color:
                                  Color(
                                    0xFF6B5B7B,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                track.category,
                                style:
                                const TextStyle(
                                  fontSize: 12,
                                  color:
                                  Color(
                                    0xFF9A8FA3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        Container(
                          height: 40,
                          width: 40,
                          decoration:
                          const BoxDecoration(
                            color:
                            Color(
                              0xFFC8B6E2,
                            ),
                            shape:
                            BoxShape.circle,
                          ),
                          child: Icon(
                            isCurrent &&
                                MusicService
                                    .isPlaying
                                ? Icons
                                .pause_rounded
                                : Icons
                                .play_arrow_rounded,
                            color:
                            Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}