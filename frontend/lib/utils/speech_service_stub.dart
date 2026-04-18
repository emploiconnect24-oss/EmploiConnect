typedef SpeechResultCallback = void Function(String texte);

class SpeechService {
  static bool get isSupported => false;

  static bool estDisponible() => false;

  static void demarrerMicro(SpeechResultCallback onResult) {}

  static void arreterMicro() {}

  static void parler(String texte, {String lang = 'fr-FR', String genre = 'homme'}) {}
}
