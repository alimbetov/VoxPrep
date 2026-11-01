enum CatalogueSourceMode {
  production('production'),
  demo('demo');

  const CatalogueSourceMode(this.code);

  final String code;

  static CatalogueSourceMode fromCode(String? value) {
    for (final mode in values) {
      if (mode.code == value) return mode;
    }
    return CatalogueSourceMode.production;
  }
}
