import 'dart:js_interop' as js;

@js.JS('gnosisSpeak')
external void _gnosisSpeak(
  js.JSString text,
  js.JSNumber pitch,
  js.JSNumber rate,
);

@js.JS('gnosisStopTts')
external void _gnosisStopTts();

@js.JS('onGnosisTtsComplete')
external set _onGnosisTtsComplete(js.JSFunction? callback);

void jsGnosisSpeak(String text, double pitch, double rate) {
  try {
    _gnosisSpeak(text.toJS, pitch.toJS, rate.toJS);
  } catch (_) {}
}

void jsGnosisStopTts() {
  try {
    _gnosisStopTts();
  } catch (_) {}
}

void setJsOnGnosisTtsComplete(void Function()? callback) {
  try {
    if (callback != null) {
      _onGnosisTtsComplete = callback.toJS;
    } else {
      _onGnosisTtsComplete = null;
    }
  } catch (_) {}
}
