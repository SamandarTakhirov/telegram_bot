import 'package:dart_telegram_bot/services/data/models/weather_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    await dotenv.load(fileName: '.env');
    final response = await dio.get(dotenv.env['URLWEATHER']!, queryParameters: {
      'lat': latitude,
      'lon': longitude,
      'appid': dotenv.env['APIWEATHER'],
      'units': 'metric',
      'lang': 'uz',
    });
    return WeatherModel.fromJson(response.data);
  }

  @override
  Future<WeatherModel> getWeatherByName({required String cityName}) async {
    final response = await dio.get(dotenv.env['URLWEATHER']!, queryParameters: {
      'q': cityName,
      'appid':  dotenv.env['APIWEATHER'],
      'units': 'metric',
      'lang': 'uz',
    });
    return WeatherModel.fromJson(response.data, cityName: cityName);
  }
}
