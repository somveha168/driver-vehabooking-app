/// Build-time environment selection.
///
/// Pass `--dart-define=ENV=dev|staging|prod` at build/run time. Defaults to
/// [Environment.dev] so a plain `flutter run` targets the local backend.
enum Environment {
  dev,
  staging,
  prod;

  static Environment get current {
    const value = String.fromEnvironment('ENV', defaultValue: 'dev');
    return Environment.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Environment.dev,
    );
  }

  bool get isDev => this == Environment.dev;
}
