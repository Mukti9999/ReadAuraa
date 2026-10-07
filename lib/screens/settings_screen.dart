import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool readingMode = false;
  bool readingMusic = true;
  bool notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF6B5B7B),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Settings ⚙️',
          style: TextStyle(
            color: Color(0xFF6B5B7B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Make ReadAura yours ✨',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Customize your reading experience.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9A8FA3),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Reading',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(height: 12),

            _settingTile(
              icon: Icons.nightlight_round,
              title: 'Night Reading',
              subtitle: 'Use a darker reading interface',
              value: readingMode,
              onChanged: (value) {
                setState(() {
                  readingMode = value;
                });
              },
            ),

            const SizedBox(height: 10),

            _settingTile(
              icon: Icons.music_note_rounded,
              title: 'Reading Music',
              subtitle: 'Play soft background music while reading',
              value: readingMusic,
              onChanged: (value) {
                setState(() {
                  readingMusic = value;
                });
              },
            ),

            const SizedBox(height: 25),

            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(height: 12),

            _settingTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Receive reading reminders and updates',
              value: notifications,
              onChanged: (value) {
                setState(() {
                  notifications = value;
                });
              },
            ),

            const SizedBox(height: 25),

            const Text(
              'About ReadAura',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(height: 12),

            _infoTile(
              icon: Icons.auto_awesome_rounded,
              title: 'About ReadAura',
              subtitle: 'Read. Feel. Reflect.',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'ReadAura',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFFC8B6E2),
                    size: 35,
                  ),
                  children: const [
                    Text(
                      'ReadAura is a personalized reading app designed to make reading more enjoyable through mood-based recommendations, reading reflections, favourite passages and a calming reading experience.',
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 10),

            _infoTile(
              icon: Icons.info_outline_rounded,
              title: 'App Version',
              subtitle: 'ReadAura 1.0.0',
              onTap: () {},
            ),

            const SizedBox(height: 30),

            const Center(
              child: Text(
                'Read. Feel. Reflect. 💗',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF9A8FA3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EAF6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6B5B7B),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B5B7B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9A8FA3),
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFC8B6E2),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EAF6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B5B7B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A8FA3),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Color(0xFFB2A6B8),
            ),
          ],
        ),
      ),
    );
  }
}