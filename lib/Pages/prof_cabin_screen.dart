import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard

void main() => runApp(ProfessorCabinApp());

class ProfessorCabinApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Professor Cabin List',
      home: ProfessorCabinScreen(),
    );
  }
}

class Professor {
  final String name;
  final String cabin;
  final String email;

  Professor({required this.name, required this.cabin, required this.email});
}

class ProfessorCabinScreen extends StatefulWidget {
  @override
  _ProfessorCabinScreenState createState() => _ProfessorCabinScreenState();
}

class _ProfessorCabinScreenState extends State<ProfessorCabinScreen> {
  final List<Professor> professors = [
    Professor(name: 'Dr. UmaMakeshwari A', cabin: 'LTC 110 A', email: 'umamakeshwari.a@sastra.ac.in'),
    Professor(name: 'Rajarajan', cabin: 'SOC 311B', email: 'rajarajan@sastra.ac.in'),
    Professor(name: 'Manikandan', cabin: 'SOC 311B', email: 'manikandan@sastra.ac.in'),
    Professor(name: 'AnanthaKrishnan', cabin: 'SOC 411A', email: 'ananthakrishnan@sastra.ac.in'),
    // add all professors here ...
    Professor(name: 'L. Amudha', cabin: 'SoC 320', email: 'amudha.l@sastra.ac.in'),
  ];

  List<Professor> filteredProfessors = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredProfessors = professors;
    searchController.addListener(_searchProfessors);
  }

  void _searchProfessors() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredProfessors = professors.where((prof) {
        return prof.name.toLowerCase().contains(query) ||
               prof.cabin.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _copyEmail(String email) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied $email to clipboard'))
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Professors'),
        bottom: PreferredSize(
          preferredSize: Size(double.infinity, 60),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or cabin...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: filteredProfessors.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (context, index) {
          final prof = filteredProfessors[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(prof.name[0]),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            title: Text(prof.name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Cabin: ${prof.cabin}\nEmail: ${prof.email}'),
            isThreeLine: true,
            trailing: IconButton(
              icon: Icon(Icons.copy),
              onPressed: () => _copyEmail(prof.email),
              tooltip: 'Copy email',
            ),
          );
        },
      )
    );
  }
}
