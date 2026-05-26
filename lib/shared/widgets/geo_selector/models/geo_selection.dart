class GeoSelection {
  final String country;
  final String countryCode; // ISO2 (e.g., IN, US)

  final String state;
  final String stateCode; // isoCode from dataset

  final String city;
  final String cityCode; // optional dataset id

  const GeoSelection({
    required this.country,
    required this.countryCode,
    required this.state,
    required this.stateCode,
    required this.city,
    required this.cityCode,
  });

  const GeoSelection.empty()
      : country = '',
        countryCode = '',
        state = '',
        stateCode = '',
        city = '',
        cityCode = '';

  bool get isComplete =>
      countryCode.isNotEmpty && stateCode.isNotEmpty && city.isNotEmpty;

  GeoSelection copyWith({
    String? country,
    String? countryCode,
    String? state,
    String? stateCode,
    String? city,
    String? cityCode,
  }) {
    return GeoSelection(
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      state: state ?? this.state,
      stateCode: stateCode ?? this.stateCode,
      city: city ?? this.city,
      cityCode: cityCode ?? this.cityCode,
    );
  }
}
