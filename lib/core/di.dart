class di {
  di._();
  static final di _instance = di._();
  factory di() => _instance;

  final Map<Type, Object> _registry = {};

  void register<T extends Object>(T instance) {
    _registry[T] = instance;
  }

  T get<T extends Object>() {
    final instance = _registry[T];
    if (instance == null) {
      throw Exception('Dependency of type $T not registered in locator.');
    }
    return instance as T;
  }
}
