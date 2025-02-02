class PatientInfo {
  int patientId;
  String name;
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
    return 'QuestionnaireModel(Patient_Id: $patientId,name: $name,birthDate: $birthDate,address: $address,  phone: $phone,email: $email,school: $school,motherName: $motherName,isOnClinic: $isInClinic)';
  }
}
