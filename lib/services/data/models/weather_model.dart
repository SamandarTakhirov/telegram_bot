import 'package:intl/intl.dart';

class WeatherModel {
  final String weatherDescription;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int timezoneOffset;
  final String cityNameResponse;
  final Map<String, double>? currencyRates;

  const WeatherModel({
    required this.weatherDescription,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.timezoneOffset,
    required this.cityNameResponse,
    this.currencyRates,
  });

  factory WeatherModel.fromJson(Map<String, Object?> json, {String? cityName}) {
    final weather = switch (json) {
      {
        "weather": List<Object?> weathers,
      } =>
        (weathers.first as Map)['description'] as String,
      _ => '',
    };
    final main = switch (json) {
      {
        "main": Map<String, Object?> main,
      } =>
        main,
      _ => {},
    };
    final wind = switch (json) {
      {
        "wind": Map<String, Object?> wind,
      } =>
        (wind['speed'] as num).toDouble(),
      _ => 0.0,
    };
    return WeatherModel(
      weatherDescription: weather,
      temperature: main['temp'].toDouble(),
      feelsLike: main['feels_like'].toDouble(),
      humidity: main['humidity'],
      windSpeed: wind,
      timezoneOffset: json['timezone'] as int? ?? 0,
      cityNameResponse: cityName ?? (json['name'] as String? ?? ''),
      currencyRates: null,
    );
  }

  @override
  String toString() {
    DateTime currentTime = DateTime.now().toUtc().add(Duration(seconds: timezoneOffset));
    String formattedTime = DateFormat('HH:mm:ss').format(currentTime);

    String currencyInfo = '';
    if (currencyRates != null) {
      currencyInfo = '''
💵 **USD:** ${currencyRates?['USD']} UZS
💶 **EUR:** ${currencyRates?['EUR']} UZS
💴 **RUB:** ${currencyRates?['RUB']} UZS
      ''';
    }

    return '''
🌤 **Shahar:** $cityNameResponse  
🌡 **Harorat:** $temperature°C  
🤔 **Tuyilgan harorat:** $feelsLike°C  
💧 **Namlik:** $humidity%  
🌬 **Shamol tezligi:** $windSpeed m/s  
🌈 **Ob-havo:** $weatherDescription  
🕒 **Soat:** $formattedTime  
$currencyInfo

      ''';
  }
}
