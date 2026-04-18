import 'dart:js_interop';

typedef SpeechResultCallback = void Function(String texte);

@JS('startSpeechRecognition')
external void _startSpeechRecognition(JSFunction callback);

@JS('window.startSpeechRecognition')
external JSAny? get _startSpeechRecognitionFn;

@JS('stopSpeechRecognition')
external void _stopSpeechRecognition();

@JS('speakText')
external void _speakText(JSString text, JSString lang, JSString genre);

class SpeechService {
  static bool get isSupported => estDisponible();

  static bool estDisponible() {
    try {
      return _startSpeechRecognitionFn != null;
    } catch (_) {
      return false;
    }
  }

  static void demarrerMicro(SpeechResultCallback onResult) {
    try {
      if (!estDisponible()) {
        // ignore: avoid_print
        print('[speech] startSpeechRecognition non disponible');
        return;
      }
      _startSpeechRecognition(
        (JSString result) {
          onResult(result.toDart);
        }.toJS,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[speech] Erreur micro: $e');
    }
  }

  static void arreterMicro() {
    try {
      _stopSpeechRecognition();
    } catch (e) {
      // ignore: avoid_print
      print('[speech] Erreur stop micro: $e');
    }
  }

  static void parler(String texte, {String lang = 'fr-FR', String genre = 'homme'}) {
    try {
      _speakText(texte.toJS, lang.toJS, genre.toJS);
    } catch (e) {
      // ignore: avoid_print
      print('[speech] Erreur TTS: $e');
    }
  }
}
