import 'package:dart_telegram_bot/constants/const_keys.dart';
import 'package:dio/dio.dart';

abstract class ImageRepository {
  Future<String?> getImageByUrl({required String cityName});
}

class ImageRepositoryImpl extends ImageRepository {
  final dio = Dio();

  @override
  Future<String?> getImageByUrl({required String cityName}) async {
    try {
      final response = await dio.get(
        ConstKeys.urlImage,
        queryParameters: {
          'query': '$cityName city',        
          'per_page': 1,            
          'orientation': 'portrait',
        },
        options: Options(
          headers: {'Authorization': 'Client-ID ${ConstKeys.imageApiKey}'},
        ),
      );

      if (response.data['results'] != null && response.data['results'].isNotEmpty) {
        return response.data['results'][0]['urls']['regular']; 
      }

      return null;
    } catch (e) {
      print('Error fetching image: $e');
      return null; 
    }
  }
}
