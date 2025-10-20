import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/theme_model.dart'; // ✅ Import ThemeProvider

class ClubHubPage extends StatelessWidget {
  const ClubHubPage({super.key});

  // Updated clubs data
  // 🔴 IMPORTANT: Update the 'logo' paths to match your exact asset filenames.
  // I have added all 15 new clubs with placeholder logo paths.
  final List<Map<String, String>> clubs = const [
    {
      "name": "Association of Computing Engineers (ACE)",
      "logo": "assets/images/ACE-bgless.png", // This one was already here
      "url": "https://ace-sastra.vercel.app/"
    },
    {
      "name": "1nf1n1ty Team",
      "logo": "assets/images/infinity.png", // 🔴 UPDATE THIS
      "url": "https://1nf1n1ty.team/"
    },
    {
      "name": "Carpediem",
      "logo": "assets/images/carpediem.png", // 🔴 UPDATE THIS
      "url": "https://carpediem.kuruksastra.in/"
    },
    {
      "name": "Daksh",
      "logo": "assets/images/daksh.jpeg", // 🔴 UPDATE THIS
      "url": "https://www.instagram.com/daksh_2k26"
    },
    {
      "name": "Salvo for AI",
      "logo": "assets/images/salvo.jpeg", // 🔴 UPDATE THIS
      "url": "https://www.instagram.com/salvoforai"
    },
    {
      "name": "Sastra Racing Team",
      "logo": "assets/images/ratio.jpg", // 🔴 UPDATE THIS
      "url": "https://www.instagram.com/sastra_racing_team_ratio"
    },
    {
      "name": "Daksh Arts Team",
      "logo": "assets/images/darts.jpeg", // 🔴 UPDATE THIS
      "url": "https://www.instagram.com/daksh_arts_team"
    },
    {
      "name": "KS Merch Sastra",
      "logo": "assets/images/krmerch.jpeg", // 🔴 UPDATE THIS
      "url": "https://www.instagram.com/ksmerch.sastra"
    },
    {
      "name": "E-Cell Sastra",
      "logo": "assets/images/ecell.png", // 🔴 UPDATE THIS
      "url": "https://www.instagram.com/ecell_sastra"
    },
    {
      "name": "Robotics Club Sastra",
      "logo": "assets/images/rcs.png", // 🔴 UPDATE THIS
      "url": "https://www.instagram.com/robotics_club_sastra"
    },
    {
      "name": "Insiders Sastra",
      "logo": "assets/images/insiders.jpeg", // 🔴 UPDATE THIS
      "url": "https://www.instagram.com/insiders_sastra"
    },
    {
      "name": "Sastra Music Team",
      "logo": "assets/images/music.png", // 🔴 UPDATE THIS
      "url": "https://www.instagram.com/sastramusicteam"
    },
    {
      "name": "The Artz Gumbal Sastra",
      "logo": "assets/images/artz.jpeg", // 🔴 UPDATE THIS
      "url": "https://www.instagram.com/the_artz_gumbal_sastra"
    },
    {
      "name": "Gaanavarshini",
      "logo": "assets/images/gaanavarshini.jpeg", // 🔴 UPDATE THIS
      "url": "https://www.instagram.com/gaanavarshini_"
    },
    {
      "name": "ASCIEE Sastra",
      "logo": "assets/images/ascii.jpeg", // 🔴 UPDATE THIS
      "url": "https://www.instagram.com/asciee_sastra"
    },
    {
      "name": "Kuruksastra",
      "logo": "assets/images/ks.png", // 🔴 UPDATE THIS
      "url": "https://www.instagram.com/kuruksastra"
    },
  ];

  // Function to launch URL
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text(
          "Club Hub",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: themeProvider.isDarkMode
            ? Colors.black
            : themeProvider.primaryColor,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(), // Smooth drag/scroll
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: clubs.length,
                itemBuilder: (context, index) {
                  final club = clubs[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                club["logo"]!,
                                fit: BoxFit.contain,
                                // Add error handling for images
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.hide_image_outlined,
                                    size: 50,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            club["name"]!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _launchURL(club["url"]!),
                            child: const Text(
                              "Visit",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}