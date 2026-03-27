import 'package:flutter/material.dart';

class AdminTopBar extends StatelessWidget {
  const AdminTopBar({
    super.key,
    required this.title,
    required this.onMenuPressed,
    required this.isMobile,
    required this.onLogout,
  });

  final String title;
  final VoidCallback onMenuPressed;
  final bool isMobile;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenuPressed,
            tooltip: isMobile ? 'Ouvrir le menu' : 'Réduire la sidebar',
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          if (!isMobile)
            SizedBox(
              width: 280,
              height: 38,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
            ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () {},
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await onLogout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'profile',
                child: Text('Mon profil'),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Text('Déconnexion'),
              ),
            ],
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF1A56DB),
              child: Text(
                'A',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
