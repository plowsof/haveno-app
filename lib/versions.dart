import 'dart:convert';
import 'package:flutter/services.dart'; // For rootBundle

class Versions {
  // Private static instance variable
  static final Versions _instance = Versions._internal();

  // Internal map to store version data
  late Map<String, Map<String, String>> _data;

  // Private constructor
  Versions._internal();

  // Public factory constructor to provide the same instance
  factory Versions() {
    return _instance;
  }

  // Load JSON data
  Future<void> load() async {
    try {
      // Load the JSON file
      final String jsonString = await rootBundle.loadString('assets/versions.json');
      final Map<String, dynamic> jsonResponse = json.decode(jsonString);

      // Convert the loaded JSON into a Map
      _data = jsonResponse.map((key, value) => MapEntry(key, Map<String, String>.from(value)));
    } catch (e) {
      print("Error loading versions: $e");
    }
  }

  // Get version for a given component
  String? getVersion(String component) {
    return _data[component]?['default'];
  }
}
