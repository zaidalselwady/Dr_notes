class PatientInfo {
  int patientId;
  String name;
  String firstName;
  String midName;
  String lastName;
  String birthDate;
  String address;
  String phone;
  String email;
  String school;
  String motherName;
  bool isInClinic;

  PatientInfo({
    this.patientId = 0,
    required this.name,
    required this.firstName,
    required this.midName,
    required this.lastName,
    required this.birthDate,
    required this.address,
    required this.phone,
    required this.email,
    required this.school,
    required this.motherName,
    required this.isInClinic,
  });

  // You can also add methods to serialize/deserialize to/from JSON if needed
  Map<String, dynamic> toJson() {
    return {
      'Patient_Id': patientId,
      'name': name,
      'FirstName': firstName,
      'LastName': lastName,
      'MiddleName': midName,
      'birthDate': birthDate,
      'address': address,
      'phone': phone,
      'email': email,
      'school': school,
      'motherName': motherName,
      'isOnClinic': isInClinic
    };
  }

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      patientId: json['Patient_Id'],
      name: json['name'],
      firstName: json['FirstName'] ?? "",
      midName: json['MiddleName'] ?? "",
      lastName: json['LastName'] ?? "",
      birthDate: json['birthDate'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      school: json['school'],
      motherName: json['motherName'],
      isInClinic: json['isOnClinic'],
    );
  }
  @override
  String toString() {
    return 'QuestionnaireModel(Patient_Id: $patientId,name: $name,FirstName:$firstName,    MiddleName:$midName,LastName:$lastName,birthDate: $birthDate,address: $address,  phone: $phone,email: $email,school: $school,motherName: $motherName,isOnClinic: $isInClinic)';
  }
}
