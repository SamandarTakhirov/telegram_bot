import 'package:dart_telegram_bot/constants/const_keys.dart';
import 'package:dart_telegram_bot/services/data/models/weather_model.dart';
import 'package:dart_telegram_bot/services/data/repository/image_repository.dart';
import 'package:dart_telegram_bot/services/data/repository/weather_repository.dart';
import 'package:dio/dio.dart';
import 'package:televerse/televerse.dart';
import 'package:cron/cron.dart';

void main() async {
  final bot = Bot(ConstKeys.botToken);
  final String onLocation = '📍 Location orqali';
  final String onCityName = '🌎 Shahar nomi orqali';
  final String onAutoWeather = '⏰ Avtomatik ob-havo sozlash';
  bot.command('start', (ctx) async {
    final user = ctx.message?.from;
    final firstName = user?.firstName ?? 'Foydalanuvchi';
    final lastName = user?.lastName ?? '';

    final keyboard = Keyboard()
      ..requestLocation(onLocation)
      ..oneTime()
      ..addText(onCityName)
      ..oneTime()
      ..row()
      ..addText(onAutoWeather)
      ..oneTime()
      ..resized();

    await ctx.reply(
      '🌤 Salom $firstName $lastName! Ob-havo botiga xush kelibsiz.\n\nQuyidagi tugmalardan birini tanlang yoki o\'zingiz yozib yuboring:',
      replyMarkup: keyboard,
    );
  });

  Future<void> fetchWeatherData(
    Context ctx, {
    String? cityName,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final weatherRepository = WeatherRepositoryImpl();
      final imageRepository = ImageRepositoryImpl();
      final WeatherModel? weatherModel;
      final String? imageUrl;

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
        await ctx.reply(
            '⚠️ Shahar nomi topilmadi yoki joylashuv ma\'lumotlari noto\'g\'ri. Iltimos, qayta urinib ko\'ring.');
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

  bot.onLocation((ctx) async {
    final location = ctx.message?.location;

    if (location == null) {
      await ctx.reply('⚠️ Iltimos, joylashuvni yuboring.');
      return;
    }

    await fetchWeatherData(ctx, latitude: location.latitude, longitude: location.longitude);
  });

  // final cron = Cron();

  // bot.onLocation((ctx) async {
  //   print('Auto ${ctx.message?.text}');
  //   final location = ctx.message?.location;

  //   if (location == null) {
  //     await ctx.reply('⚠️ Iltimos, joylashuvni yuboring.');
  //     return;
  //   }

  //   cron.schedule(Schedule.parse('0 7 * * *'), () async {
  //     final weatherRepository = WeatherRepositoryImpl();
  //     final weatherModel = await weatherRepository.getWeatherByLocation(
  //       latitude: location.latitude,
  //       longitude: location.longitude,
  //     );

  //     await ctx.reply(
  //       '🌤 Bugungi ob-havo:\n\n'
  //       'Harorat: ${weatherModel.temperature}°C\n'
  //       'His etish: ${weatherModel.feelsLike}°C\n'
  //       'Namlik: ${weatherModel.humidity}%\n'
  //       'Shamol tezligi: ${weatherModel.windSpeed} m/s\n\n'
  //       'Avtomatik ob-havo ma’lumotlari yuborildi.',
  //     );
  //   });

  //   await ctx.reply('✅ Avtomatik ob-havo sozlandi. Har kuni ertalab soat 7:00 da ma’lumot olasiz.');
  // });


  bot.onMessage((ctx) async {
   
    print('OnMessage ${ctx.message?.text}');
    String? cityName = ctx.message?.text?.trim();

    if (cityName == null || cityName.isEmpty) {
      await ctx.reply('⚠️ Iltimos, shahar nomini kiriting.');
      return;
    }

    await fetchWeatherData(ctx, cityName: cityName);
  });

  await bot.start();
}
