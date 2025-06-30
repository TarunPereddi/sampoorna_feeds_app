// lib/services/persona_state.dart
import 'package:flutter/foundation.dart';

class PersonaState extends ChangeNotifier {
  static String? _persona;

  static String? get persona => _persona;

  static void setPersona(String persona) {
    _persona = persona;
    // In a real app, you might want to notify listeners or persist this
    debugPrint('Persona set to: $persona');
  }
}
