import 'package:dart_telegram_bot/constants/const_keys.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

abstract class CurrencyRepository {
  Future<Map<String, double>?> getCurrencyRates();
}

class CurrencyRepositoryImpl extends CurrencyRepository {
  final dio = Dio();

  @override
  Future<Map<String, double>?> getCurrencyRates() async {
    try {
      final response = await dio.get(ConstKeys.bankUrl);
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
