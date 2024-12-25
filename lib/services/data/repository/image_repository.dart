import 'package:dart_telegram_bot/constants/const_keys.dart';
import 'package:dio/dio.dart';

abstract class ImageRepository {
  Future<String?> getImageByUrl({required String cityName});
}

class ImageRepositoryImpl extends ImageRepository {
  final dio = Dio();
  @override
  Future<String?> getImageByUrl({required String cityName}) async {
    final response = await dio.get(
      ConstKeys.urlImage,
      queryParameters: {
        'query': cityName,
        'per_page': 1,
      },
      options: Options(
        headers: {'Authorization': ConstKeys.pexelsApiKey},
      ),
    );
    if (response.data['photos'].isNotEmpty) {
      return response.data['photos'][0]['src']['original'];
    }
    return null;
  }
}
