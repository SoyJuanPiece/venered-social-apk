import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:venered_social/screens/home_feed_screen.dart';
import 'package:venered_social/screens/profile_screen.dart';
import 'package:venered_social/screens/create_post_screen.dart';
import 'package:venered_social/screens/explore_screen.dart';
import 'package:venered_social/screens/messages_screen.dart';
import 'package:venered_social/widgets/fade_slide_in.dart';

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late Stream<int> _unreadStream;
  final String? _currentUserId =
      Supabase.instance.client.auth.currentUser?.id;

  static const List<_NavItem> _navItems = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Inicio'),
    _NavItem(Icons.explore_outlined, Icons.explore_rounded, 'Explorar'),
    _NavItem(Icons.add_box_outlined, Icons.add_box_rounded, 'Crear'),
    _NavItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Mensajes'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
  ];

  List<Widget> get _screens => [
        const HomeFeedScreen(),
        const ExploreScreen(),
        CreatePostScreen(),
        const MessagesScreen(),
        _currentUserId == null
            ? const Scaffold(
                body: Center(
                    child: Text('Inicia sesión para ver tu perfil')))
            : ProfileScreen(userId: _currentUserId!),
      ];

  @override
  void initState() {
    super.initState();
    _unreadStream = _buildUnreadStream();
  }

  Stream<int> _buildUnreadStream() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return Stream.value(0);
    return Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((rows) => rows
            .where((m) =>
                m['receiver_id'] == user.id && m['is_read'] == false)
            .length)
        .handleError((_) => 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return constraints.maxWidth >= 800
          ? _buildWideLayout(context)
          : _buildNarrowLayout(context);
    });
  }

  // ── WEB / TABLET ──────────────────────────────────────────────────────────
  Widget _buildWideLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          _buildSidebar(theme, isDark),
          Expanded(
              child: IndexedStack(
                  index: _selectedIndex, children: _screens)),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme, bool isDark) {
    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C0C1A) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark
                ? const Color(0xFF1E1E36)
                : const Color(0xFFE8EDF5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 28, 26, 36),
              child: ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFF818CF8), Color(0xFFF472B6)],
                ).createShader(b),
                child: Text(
                  'Venered',
                  style: GoogleFonts.grandHotel(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: List.generate(_navItems.length, (i) {
                  if (i == 3) {
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 40 + (i * 40)),
                      beginOffset: const Offset(-0.08, 0),
                      child: StreamBuilder<int>(
                        stream: _unreadStream,
                        initialData: 0,
                        builder: (_, snap) => _sidebarItem(
                            theme, isDark, i,
                            badge: snap.data ?? 0),
                      ),
                    );
                  }
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 40 + (i * 40)),
                    beginOffset: const Offset(-0.08, 0),
                    child: _sidebarItem(theme, isDark, i),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(ThemeData theme, bool isDark, int index,
      {int badge = 0}) {
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _selectedIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF6366F1)
                            .withOpacity(isDark ? 0.22 : 0.12),
                        const Color(0xFFEC4899)
                            .withOpacity(isDark ? 0.08 : 0.04),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
            ),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (b) => (isSelected
                          ? const LinearGradient(colors: [
                              Color(0xFF818CF8),
                              Color(0xFFF472B6)
                            ])
                          : LinearGradient(colors: [
                              Colors.grey.shade500,
                              Colors.grey.shade500
                            ]))
                      .createShader(b),
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFF6366F1),
                        Color(0xFFEC4899)
                      ]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── MOBILE ────────────────────────────────────────────────────────────────
  Widget _buildNarrowLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C0C1A) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: StreamBuilder<int>(
              stream: _unreadStream,
              initialData: 0,
              builder: (_, snap) {
                final unread = snap.data ?? 0;
                return Row(
                  children: List.generate(_navItems.length, (i) {
                    if (i == 2) {
                      return Expanded(
                        child: FadeSlideIn(
                          delay: const Duration(milliseconds: 80),
                          child: _createButton(context),
                        ),
                      );
                    }
                    return Expanded(
                      child: FadeSlideIn(
                        delay: Duration(milliseconds: 40 + (i * 30)),
                        child: _bottomNavItem(
                            context, i, i == 3 ? unread : 0),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem(BuildContext context, int index, int badge) {
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: ShaderMask(
                key: ValueKey(isSelected),
                shaderCallback: (b) => (isSelected
                        ? const LinearGradient(colors: [
                            Color(0xFF818CF8),
                            Color(0xFFF472B6)
                          ])
                        : LinearGradient(colors: [
                            Colors.grey.shade600,
                            Colors.grey.shade600
                          ]))
                    .createShader(b),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 26,
                  color: Colors.white,
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                bottom: 2,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            if (badge > 0)
              Positioned(
                top: 4,
                right: 10,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _createButton(BuildContext context) {
    final isSelected = _selectedIndex == 2;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = 2),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.5),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
