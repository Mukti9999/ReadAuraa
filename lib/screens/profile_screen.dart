import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'listening_history_screen.dart';
import 'favourites_screen.dart';
import 'reading_history_screen.dart';
import 'ai_reflection_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'thoughts_list_screen.dart';

import '../services/favourite_service.dart';
import '../services/reading_history_service.dart';
import '../services/thoughts_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Mukti Vyas';
  String _userEmail = '';
  String _profileImage = '';

  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // --------------------------------------------------
  // LOAD USER PROFILE
  // --------------------------------------------------

  Future<void> _loadUserProfile() async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          _isLoadingProfile = false;
        });
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>>
      document =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (document.exists &&
          document.data() != null) {
        final data = document.data()!;

        setState(() {
          _userName =
              data['name']?.toString() ??
                  user.displayName ??
                  'Mukti Vyas';

          _userEmail =
              data['email']?.toString() ??
                  user.email ??
                  '';

          _profileImage =
              data['profileImage']?.toString() ??
                  '';

          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _userName =
              user.displayName ?? 'Mukti Vyas';

          _userEmail = user.email ?? '';

          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint(
        'Profile loading error: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  // --------------------------------------------------
  // LOGOUT
  // --------------------------------------------------

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  // --------------------------------------------------
  // OPTION TILE
  // --------------------------------------------------

  Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),
        leading: Container(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFE8DDF1),
            borderRadius:
            BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF8B739F),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B5B7B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 12,
            color: Color(0xFF9A8FA3),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Color(0xFFB5AAB9),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor:
      const Color(0xFFFFF9FC),

      appBar: AppBar(
        backgroundColor:
        const Color(0xFFFFF9FC),
        elevation: 0,
        title: const Text(
          'My Profile 🌸',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            color: Color(0xFF6B5B7B),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xFF8B739F),
            ),
            onPressed: _logout,
          ),
        ],
      ),

      body: _isLoadingProfile
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC8B6E2),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // --------------------------------------
            // PROFILE HEADER
            // --------------------------------------

            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                const Color(0xFFE8DDF1),
                borderRadius:
                BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                      const Color(
                        0xFFC8B6E2,
                      ),
                      image: _profileImage
                          .isNotEmpty
                          ? DecorationImage(
                        image:
                        NetworkImage(
                          _profileImage,
                        ),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: _profileImage
                        .isEmpty
                        ? const Icon(
                      Icons
                          .person_rounded,
                      size: 40,
                      color:
                      Colors.white,
                    )
                        : null,
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          _userName,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            fontFamily:
                            'Times New Roman',
                            fontSize: 22,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            Color(
                              0xFF6B5B7B,
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          _userEmail,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            fontFamily:
                            'Times New Roman',
                            fontSize: 13,
                            color:
                            Color(
                              0xFF8B739F,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------
            // READING JOURNEY
            // --------------------------------------

            const Text(
              'Your Reading Journey 📚',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                // BOOKS
                Expanded(
                  child: _statCard(
                    icon:
                    Icons.menu_book_rounded,
                    title: 'Books',
                    value: ReadingHistoryService
                        .getHistory()
                        .length
                        .toString(),
                  ),
                ),

                const SizedBox(width: 10),

                // FAVOURITES
                Expanded(
                  child: _statCard(
                    icon:
                    Icons.favorite_rounded,
                    title: 'Favourites',
                    value: FavouriteService
                        .favourites
                        .length
                        .toString(),
                  ),
                ),

                const SizedBox(width: 10),

                // THOUGHTS
                Expanded(
                  child: StreamBuilder<int>(
                    stream: ThoughtsService
                        .getThoughtCountStream(),
                    initialData: 0,
                    builder:
                        (context, snapshot) {
                      return _statCard(
                        icon: Icons
                            .edit_note_rounded,
                        title: 'Thoughts',
                        value:
                        (snapshot.data ??
                            0)
                            .toString(),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --------------------------------------
            // MY READAURA
            // --------------------------------------

            const Text(
              'My ReadAura',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B5B7B),
              ),
            ),

            const SizedBox(height: 15),

            // MY THOUGHTS
            _optionTile(
              icon:
              Icons.edit_note_rounded,
              title: 'My Thoughts',
              subtitle:
              'View your saved reading thoughts',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const ThoughtsListScreen(),
                  ),
                );
              },
            ),

            // FAVOURITE PASSAGES
            _optionTile(
              icon:
              Icons.favorite_rounded,
              title: 'Favourite Passages',
              subtitle:
              'View your saved lines and passages',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const FavouritesScreen(),
                  ),
                );
              },
            ),

            // LISTENING HISTORY
            _optionTile(
              icon:
              Icons.headphones_rounded,
              title: 'Listening History',
              subtitle:
              'Continue your audiobook journey',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const ListeningHistoryScreen(),
                  ),
                );
              },
            ),

            // READING HISTORY
            _optionTile(
              icon:
              Icons.history_rounded,
              title: 'Reading History',
              subtitle:
              'See your reading progress',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const ReadingHistoryScreen(),
                  ),
                );
              },
            ),

            // AI REFLECTION
            _optionTile(
              icon:
              Icons.auto_awesome_rounded,
              title: 'AI Reflection',
              subtitle:
              'Reflect on your reading journey',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const AIReflectionScreen(
                      bookTitle: '',
                    ),
                  ),
                );
              },
            ),

            // SETTINGS
            _optionTile(
              icon: Icons.settings_rounded,
              title: 'Settings',
              subtitle:
              'Manage your ReadAura preferences',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const SettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            Center(
              child: TextButton.icon(
                onPressed: _logout,
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: Color(0xFF9A8FA3),
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontFamily:
                    'Times New Roman',
                    color:
                    Color(0xFF9A8FA3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // STAT CARD
  // --------------------------------------------------

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 17,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8DDF1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF8B739F),
            size: 25,
          ),

          const SizedBox(height: 7),

          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B5B7B),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 11,
              color: Color(0xFF9A8FA3),
            ),
          ),
        ],
      ),
    );
  }
}