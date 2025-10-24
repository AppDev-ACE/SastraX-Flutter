class ApiEndpoints {
  final String baseUrl;
  ApiEndpoints(this.baseUrl);
  String get captcha => '$baseUrl/captcha';
  String get login => '$baseUrl/login';
  String get profile => '$baseUrl/profile';
  String get profilePic => '$baseUrl/profilePic';
  String get dob => '$baseUrl/dob';
  String get logout => '$baseUrl/logout';
  String get reloginCaptcha => '$baseUrl/relogin-captcha';
  String get relogin => '$baseUrl/relogin';


  String get feeCollections => '$baseUrl/feeCollections';
  String get ciaWiseInternalMarks => '$baseUrl/ciaWiseInternalMarks';
  String get attendance => '$baseUrl/attendance';
  String get subjectWiseAttendance => '$baseUrl/subjectWiseAttendance';
  String get currentSemCredits => '$baseUrl/currentSemCredits';
  String get hourWiseAttendance => '$baseUrl/hourWiseAttendance';
  String get sgpa => '$baseUrl/sgpa';
  String get cgpa => '$baseUrl/cgpa';
  String get timetable => '$baseUrl/timetable';


  String get facultyList => '$baseUrl/facultyList';
  String get chatbot => '$baseUrl/materials';
  String get semGrades => '$baseUrl/semGrades';
  String get internalMarks => '$baseUrl/ciaWiseInternalMarks';
  String get courseMap => '$baseUrl/courseMap';


  String get sastraDue => '$baseUrl/sastraDue';
  String get hostelDue => '$baseUrl/hostelDue';
  String get studentStatus => '$baseUrl/studentStatus';

  
  String get bunk => '$baseUrl/bunk';
  String get messMenu => '$baseUrl/messMenu';
  String get pyqBot => '$baseUrl/chatbot';
  String get messMenuGirls => '$baseUrl/messMenuGirls';
  String get leaveHistory => '$baseUrl/leaveHistory';
  String get materials => '$baseUrl/materials';
}