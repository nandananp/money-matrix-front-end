import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FinalScreen extends StatefulWidget {
  const FinalScreen({super.key});

  @override
  State<FinalScreen> createState() => _FinalScreenState();
}

class _FinalScreenState extends State<FinalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Congratulations!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade900, Colors.green.shade400],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Congratulations on completing all the levels! 🎉',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                'Completing this game does not mean you have fully acquired financial knowledge. This is just the beginning of your journey. Regardless of your profession—scientist, doctor, teacher, or farmer—without financial knowledge, achieving financial freedom is impossible. This game aims to provide you with a foundation for understanding financial principles.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildBookCard(
                      title: 'Rich Dad Poor Dad',
                      author: 'Robert Kiyosaki',
                      quote: '"The poor and the middle class work for money. The rich have money work for them."',
                      url: 'https://www.amazon.com/Rich-Dad-Poor-Teach-Middle/dp/1612680194',
                    ),
                    _buildBookCard(
                      title: 'The Psychology of Money',
                      author: 'Morgan Housel',
                      quote: '"Spending money to show people how much money you have is the fastest way to have less money."',
                      url: 'https://www.amazon.com/Psychology-Money-Timeless-lessons-happiness/dp/0857197681',
                    ),
                    _buildBookCard(
                      title: 'Atomic Habits',
                      author: 'James Clear',
                      quote: '"You should be far more concerned with your current trajectory than with your current results."',
                      url: 'https://www.amazon.com/Atomic-Habits-Proven-Build-Break/dp/0735211299',
                    ),
                    _buildQuoteCard(
                      quote: '"The stock market is filled with individuals who know the price of everything but the value of nothing." - Philip Fisher',
                    ),
                    _buildQuoteCard(
                      quote: '"Do not save what is left after spending, but spend what is left after saving." - Warren Buffett',
                    ),
                    _buildQuoteCard(
                      quote: '"Your income can grow only to the extent that you do." - T. Harv Eker',
                    ),
                    _buildQuoteCard(
                      quote: '"Money is a terrible master but an excellent servant." - P.T. Barnum',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookCard({
    required String title,
    required String author,
    required String quote,
    required String url,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 5),
            Text(
              'by $author',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              '"$quote"',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => launchUrl(Uri.parse(url)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
              child: const Text('Read More', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard({
    required String quote,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          quote,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}