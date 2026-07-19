class DI {
  DI._();
  static final DI _instance = DI._();
  factory DI() => _instance;

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

DI di() => DI();

