import 'dart:async';

typedef StreamCallback<T> = void Function(T);

class StreamValue<T> {
  StreamValue(this.stream, {T? initialValue}) {
    _value = initialValue;

    _subscription = stream.listen((event) {
      if (_value == null) {
        _valueCompleter.complete(event);
      }
      _value = event;

      _callbacks.forEach((element) => element.call(event));
    });
  }

  final List<StreamCallback<T>> _callbacks = <StreamCallback>[];
  late final StreamSubscription<T> _subscription;
  final Stream<T> stream;
  final Completer<T> _valueCompleter = Completer<T>();

  T? _value;

  Future<T> get value async {
    if (_value == null) {
      return _valueCompleter.future;
    }

    return Future<T>.value(_value);
  }

  void addCallback(StreamCallback<T> callback) {
    _callbacks.add(callback);
  }

  void dispose() => _subscription.cancel();
}
