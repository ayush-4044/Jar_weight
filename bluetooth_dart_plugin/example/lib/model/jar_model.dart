import 'dart:convert';

class JarModel {
  final String name;
  final String capacity;
  final String expiryDate;
  final String addedOn;
  final double currentWeight;

  JarModel({
    required this.name,
    required this.capacity,
    required this.expiryDate,
    required this.addedOn,
    required this.currentWeight,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'capacity': capacity,
      'expiryDate': expiryDate,
      'addedOn': addedOn,
      'currentWeight': currentWeight,
    };
  }

  factory JarModel.fromMap(Map<String, dynamic> map) {
    return JarModel(
      name: map['name'],
      capacity: map['capacity'],
      expiryDate: map['expiryDate'],
      addedOn: map['addedOn'],
      currentWeight: map['currentWeight'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory JarModel.fromJson(String source) =>
      JarModel.fromMap(jsonDecode(source));
}
