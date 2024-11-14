
class Patient {
  String name;
  String surname;
  DateTime birthDate;
  String gender;
  String email;
  String phone;

  Patient({
    required this.name,
    required this.surname,
    required this.birthDate,
    required this.gender,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'surname': surname,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'email': email,
      'phone': phone,
    };
  }
}
