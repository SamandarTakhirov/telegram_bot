import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class ImageRepository {
  Future<String?> getImageByUrl({required String cityName});
}

class ImageRepositoryImpl extends ImageRepository {
  final dio = Dio();

  @override
  Future<String?> getImageByUrl({required String cityName}) async {
    await dotenv.load(fileName: '.env');
    try {
      final response = await dio.get(
        dotenv.env['URLIMAGE']!,
        queryParameters: {
          'query': '$cityName city',        
          'per_page': 1,            
          'orientation': 'portrait',
        },
        options: Options(
          headers: {'Authorization': 'Client-ID ${dotenv.env['IMAGEAPIKEY']}'},
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
