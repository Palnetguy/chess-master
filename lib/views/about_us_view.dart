import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  _AboutUsScreenState createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _slideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _shareApp() {
    Share.share('Check out this awesome Chess app!',
        subject: 'Chess Master App');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.brown,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnimatedSection(
                'Meet the TAK Kinship Developers',
                [
                  'Martin Rhine - Lead Developer',
                  'Ian Rush - Frontend Developer',
                  'Kazibwe David - UI/UX Designer',
                  'Rafael Pereira - Junior Frontend Developer',
                  'Bashir Kasuja - Junior Frontend Developer',
                ],
              ),
              const SizedBox(height: 24),
              _buildAnimatedSection(
                'How to Play Chess',
                [
                  '1. Set up the board correctly.',
                  '2. White always moves first.',
                  '3. Learn how each piece moves:',
                  '   - King: One square in any direction',
                  '   - Queen: Any number of squares diagonally, horizontally, or vertically',
                  '   - Rook: Any number of squares horizontally or vertically',
                  '   - Bishop: Any number of squares diagonally',
                  '   - Knight: In an "L" shape',
                  '   - Pawn: Forward one square, or two on first move',
                  '4. Capture opponent\'s pieces by moving to their square.',
                  '5. The goal is to checkmate the opponent\'s king.',
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share App'),
                  onPressed: _shareApp,
                  style: ElevatedButton.styleFrom(
                    // backgroundColor: Colors.brown[600],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSection(String title, List<String> content) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
            ),
            const SizedBox(height: 8),
            ...content.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(item),
                )),
          ],
        ),
      ),
    );
  }
}
