part of '../dart_telegram_bot.dart';

Future<void> fetchWeatherData(
  Context ctx, {
  String? cityName,
  double? latitude,
  double? longitude,
}) async {
  try {
    final weatherRepository = WeatherRepositoryImpl();
    final imageRepository = ImageRepositoryImpl();
    final currencyRepository = CurrencyRepositoryImpl();

    WeatherModel? weatherModel;
    String? imageUrl;

    if (cityName != null) {
      weatherModel = await weatherRepository.getWeatherByName(cityName: cityName);
      imageUrl = await imageRepository.getImageByUrl(cityName: cityName);
    } else {
      weatherModel = await weatherRepository.getWeatherByLocation(
        latitude: latitude!,
        longitude: longitude!,
      );
      imageUrl = await imageRepository.getImageByUrl(cityName: weatherModel.cityNameResponse);
    }

    final currencyRates = await currencyRepository.getCurrencyRates();

    if (currencyRates != null) {
      weatherModel = WeatherModel(
        weatherDescription: weatherModel.weatherDescription,
        temperature: weatherModel.temperature,
        feelsLike: weatherModel.feelsLike,
        humidity: weatherModel.humidity,
        windSpeed: weatherModel.windSpeed,
        timezoneOffset: weatherModel.timezoneOffset,
        cityNameResponse: weatherModel.cityNameResponse,
        currencyRates: currencyRates,
      );
    }

    if (imageUrl != null) {
      await ctx.replyWithPhoto(
        InputFile.fromUrl(imageUrl),
        caption: weatherModel.toString(),
        parseMode: ParseMode.markdown,
      );
    } else {
      await ctx.reply(weatherModel.toString(), parseMode: ParseMode.markdown);
    }
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      await ctx
          .reply('⚠️ Shahar nomi topilmadi yoki joylashuv ma\'lumotlari noto\'g\'ri. Iltimos, qayta urinib ko\'ring.');
    } else {
      await ctx.reply(
        '⚠️ Xatolik yuz berdi! Ob-havo ma\'lumotlarini olishda muammo paydo bo\'ldi.\n\nXato: ${e.message}',
      );
    }
  } catch (e) {
    await ctx.reply(
      '⚠️ Kutilmagan xatolik yuz berdi. Iltimos, qayta urinib ko‘ring.\n\nXato: ${e.toString()}',
    );
  }
}
