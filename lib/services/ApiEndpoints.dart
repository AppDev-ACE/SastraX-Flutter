class ApiEndpoints {
  final String baseUrl;

  ApiEndpoints(this.baseUrl);

  // Auth and User Info
  String get captcha => '$baseUrl/captcha';
  String get login => '$baseUrl/login';
  String get profile => '$baseUrl/profile';
  String get profilePic => '$baseUrl/profilePic';
  String get dob => '$baseUrl/dob';

  // Attendance and Grades
  String get attendance => '$baseUrl/attendance';
  String get subjectWiseAttendance => '$baseUrl/subjectWiseAttendance';
  String get currentSemCredits => '$baseUrl/currentSemCredits';
  String get sgpa => '$baseUrl/sgpa';
  String get cgpa => '$baseUrl/cgpa';

  // Academics and Services
  String get timetable => '$baseUrl/timetable';
  String get pyq => '$baseUrl/pyq';
  String get facultyList => '$baseUrl/facultyList';
  String get chatbot => '$baseUrl/chatbot';
  String get semGrades => '$baseUrl/semGrades';

  // Fees and Status
  String get sastraDue => '$baseUrl/sastraDue';
  String get hostelDue => '$baseUrl/hostelDue';
  String get studentStatus => '$baseUrl/studentStatus';

  // Other
  String get bunk => '$baseUrl/bunk';
  String get messMenu => '$baseUrl/messMenu';
}