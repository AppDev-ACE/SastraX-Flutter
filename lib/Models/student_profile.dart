class StudentProfile {
  final String name;
  final String regNo;
  final String department;
  final String semester;

  StudentProfile({
    required this.name,
    required this.regNo,
    required this.department,
    required this.semester,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      name: json['name'] ?? 'N/A',
      regNo: json['regNo'] ?? 'N/A',
      department: json['department'] ?? 'N/A',
      semester: json['semester'] ?? 'N/A',
    );
  }
}
