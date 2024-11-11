class User_model {
  static const String nameKey = "name";
  static const String emailKey = "email";
  static const String dniKey = "dni";
  static const String firstNameKey = "firstName";
  static const String lastNameKey = "lastName";
  static const String faceDataKey = "faceData";

  String id;
  String name;
  String email;
  String dni;
  String firstName;
  String lastName;
  List<double> faceData;

  User_model({
    required this.id,
    required this.name,
    required this.email,
    required this.dni,
    required this.firstName,
    required this.lastName,
    required this.faceData,
  });

  factory User_model.fromJson(Map<String, dynamic> json) => User_model(
        id: json['id'],
        name: json[nameKey],
        email: json[emailKey],
        dni: json[dniKey],
        firstName: json[firstNameKey],
        lastName: json[lastNameKey],
        faceData: List<double>.from(json[faceDataKey]),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        nameKey: name,
        emailKey: email,
        dniKey: dni,
        firstNameKey: firstName,
        lastNameKey: lastName,
        faceDataKey: faceData,
      };
}
