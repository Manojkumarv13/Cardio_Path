import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Constants/Lists.dart';

class DoDontsTabsPage extends StatelessWidget {
  const DoDontsTabsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 🌈 Full-page gradient background
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // 🔹 Tab Bar
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const TabBar(
                labelColor: Colors.blueAccent,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Colors.blueAccent,
                labelStyle: TextStyle(fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: "Do's"),
                  Tab(text: "Don'ts"),
                  Tab(text: "Stop Exercise If You Have"),
                ],
              ),
            ),

            // 🔹 Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  TipsList(
                    items: MyLists.dos,
                    color: Colors.green,
                    title: "✅ Things You Should Do",
                    cardGradient: const LinearGradient(
                      colors: [Color(0xFFB9FBC0), Color(0xFFE6F9E8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  TipsList(
                    items: MyLists.donts,
                    color: Colors.redAccent,
                    title: "❌ Things You Shouldn’t Do",
                    cardGradient: const LinearGradient(
                      colors: [Color(0xFFFFC4C4), Color(0xFFFFE1E1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  TipsList(
                    items: MyLists.stop,
                    color: Colors.orangeAccent,
                    title: "⚠️ Stop Exercise If You Have",
                    cardGradient: const LinearGradient(
                      colors: [Color(0xFFFFE7B3), Color(0xFFFFF4D6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TipsList extends StatelessWidget {
  final List<String> items;
  final Color color;
  final String title;
  final LinearGradient cardGradient;

  const TipsList({
    super.key,
    required this.items,
    required this.color,
    required this.title,
    required this.cardGradient,
  });

  @override
  Widget build(BuildContext context) {
    // compute a slightly darker title color (works for any Color)
    final Color titleColor = Color.lerp(color, Colors.black, 0.15) ?? color;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Card(
        elevation: 5,
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: cardGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Section Title
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 18),

              // 🔹 Dynamic Tips List
              for (var i = 0; i < items.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, color: color, size: 10),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[i],
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                if (i != items.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
