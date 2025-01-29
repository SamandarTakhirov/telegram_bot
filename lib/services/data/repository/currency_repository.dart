import 'package:dio/dio.dart';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class CurrencyRepository {
  Future<Map<String, double>?> getCurrencyRates();
}

class CurrencyRepositoryImpl extends CurrencyRepository {
  final dio = Dio();

  @override
  Future<Map<String, double>?> getCurrencyRates() async {
    await dotenv.load(fileName: '.env');
    try {
      final response = await dio.get(dotenv.env['BANKURL']!);
      if (response.statusCode == 200) {
        List<dynamic> data = [];
        if (response.data is List) {
          data = response.data;
        } else if (response.data is String) {
          data = json.decode(response.data);
        }

        Map<String, double> rates = {};
        for (var item in data) {
          if (item['Ccy'] == 'USD' || item['Ccy'] == 'EUR' || item['Ccy'] == 'RUB') {
            rates[item['Ccy']] = double.parse(item['Rate'].toString().replaceAll(',', '.'));
          }
        }

        return rates;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching currency rates: $e');
      return null;
    }
  }
}
