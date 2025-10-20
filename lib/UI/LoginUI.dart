import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Components/DiagonalClipper.dart';

class LoginUI extends StatelessWidget {
  const LoginUI({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Stack(
        children: [
          // Background with diagonal clip
          ClipPath(
            clipper: DiagonalClipper(),
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Logo in the bottom-left cropped diagonal area
          Positioned(
            bottom: 60, // aligns to bottom
            left: -20,   // aligns to left
            child: FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: Container(
                width: 120,
                height: 100,
                margin: const EdgeInsets.only(left: 20, bottom: 20),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/icon/black.png'),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30, // aligns to bottom
            left: 10,   // aligns to left
            child: FadeInUp(
                duration: const Duration(milliseconds: 2000),
                child: Row(
                  children: [
                    Text("ONE " , style: GoogleFonts.lato(
                        fontSize: 25,
                        fontWeight: FontWeight.w900
                    ),
                    ),
                    Text("SASTRA " , style: GoogleFonts.lato(
                        fontSize: 25,
                        color: Colors.blue,
                        fontWeight: FontWeight.w900
                    ),
                    ),
                  ],
                )
            ),
          ),
          Positioned(
            bottom: -50, // aligns to bottom
            left: -10,   // aligns to left
            child: FadeInUp(
              duration: const Duration(milliseconds: 3000),
              child: Container(
                  width: 170,
                  height: 100,
                  margin: const EdgeInsets.only(left: 20, bottom: 20),
                  child: Row(
                    children: [
                      Text("ONE " , style: GoogleFonts.lato(
                          fontSize: 25,
                          fontWeight: FontWeight.w900
                      ),
                      ),
                      Text("APP " , style: GoogleFonts.lato(
                          fontSize: 25,
                          color: Colors.blue,
                          fontWeight: FontWeight.w900
                      ),
                      ),
                    ],
                  )
              ),
            ),
          ),
        ],
      ),
    );
  }
}