import 'package:dart_telegram_bot/constants/const_keys.dart';
import 'package:dart_telegram_bot/services/data/models/weather_model.dart';
import 'package:dio/dio.dart';

abstract class WeatherRepository {
  Future<WeatherModel> getWeatherByName({
    required String cityName,
  });
  Future<WeatherModel> getWeatherByLocation({
    required double latitude,
    required double longitude,
  });
}

class WeatherRepositoryImpl extends WeatherRepository {
  final dio = Dio();
  @override
  Future<WeatherModel> getWeatherByLocation({
    required double latitude,
    required double longitude,
  }) async {
    final response = await dio.get(ConstKeys.urlWeather, queryParameters: {
      'lat': latitude,
      'lon': longitude,
      'appid': ConstKeys.apiWeather,
      'units': 'metric',
      'lang': 'uz',
    });
    return WeatherModel.fromJson(response.data);
  }

  @override
  Future<WeatherModel> getWeatherByName({required String cityName}) async {
    final response = await dio.get(ConstKeys.urlWeather, queryParameters: {
      'q': cityName,
      'appid': ConstKeys.apiWeather,
      'units': 'metric',
      'lang': 'uz',
    });
    return WeatherModel.fromJson(response.data, cityName: cityName);
  }
}
