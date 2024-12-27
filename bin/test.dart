import 'package:dart_telegram_bot/constants/const_keys.dart';
import 'package:dart_telegram_bot/services/data/models/weather_model.dart';
import 'package:dart_telegram_bot/services/data/repository/currency_repository.dart';
import 'package:dart_telegram_bot/services/data/repository/image_repository.dart';
import 'package:dart_telegram_bot/services/data/repository/weather_repository.dart';
import 'package:televerse/televerse.dart';

void main() async {
  final bot = Bot(ConstKeys.botToken);

  // Tugmalar uchun belgilash
  const String onLocation = '📍 Location orqali';
  const String onCityName = '🌎 Shahar nomi orqali';
  const String onAutoWeather = '⏰ Avtomatik ob-havo sozlash';
  const String onAutoLocationWeather = '📍 Location orqali avto ob-havo';
  const String onAutoCityNameWeather = '📝 Manzil kiritish orqali avto ob-havo';
  const String onMainMenu = '🔙 Bosh menu';

  /// Asosiy menyuni ko'rsatish funksiyasi
  Future<void> showMainMenu(Context ctx) async {
    final user = ctx.message?.from;
    final firstName = user?.firstName ?? 'Foydalanuvchi';
    final lastName = user?.lastName ?? '';

    final keyboard = Keyboard()
      ..requestLocation(onLocation)
      ..addText(onCityName)
      ..row()
      ..addText(onAutoWeather)
      ..resized();

    await ctx.reply(
      '🌤 Salom $firstName $lastName! Ob-havo botiga xush kelibsiz.\n\nQuyidagi tugmalardan birini tanlang yoki o\'zingiz yozib yuboring:',
      replyMarkup: keyboard,
    );
  }

  /// Avto ob-havo sozlash menyusi
  Future<void> showAutoWeatherMenu(Context ctx) async {
    final keyboard = Keyboard()
      ..addText(onAutoLocationWeather)
      ..addText(onAutoCityNameWeather)
      ..row()
      ..addText(onMainMenu)
      ..resized();

    await ctx.reply(
      'Avtomatik ob-havo sozlash uchun quyidagi tugmalardan birini tanlang:',
      replyMarkup: keyboard,
    );
  }

  /// Ob-havo ma'lumotlarini olish funksiyasi
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
      } else if (latitude != null && longitude != null) {
        weatherModel = await weatherRepository.getWeatherByLocation(
          latitude: latitude,
          longitude: longitude,
        );
        imageUrl = await imageRepository.getImageByUrl(cityName: weatherModel.cityNameResponse);
      } else {
        throw Exception("Location yoki shahar nomi berilmadi!");
      }

      final currencyRates = await currencyRepository.getCurrencyRates();

      if (currencyRates != null && weatherModel != null) {
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

      if (imageUrl != null && weatherModel != null) {
        await ctx.replyWithPhoto(
          InputFile.fromUrl(imageUrl),
          caption: weatherModel.toString(),
          parseMode: ParseMode.markdown,
        );
      } else if (weatherModel != null) {
        await ctx.reply(weatherModel.toString(), parseMode: ParseMode.markdown);
      } else {
        throw Exception("Ob-havo ma'lumotlari topilmadi!");
      }
    } catch (e) {
      await ctx.reply(
        '⚠️ Ob-havo ma\'lumotlarini olishda xatolik yuz berdi.\n\nXato: ${e.toString()}',
      );
    }
  }

  /// Location orqali ob-havo
  bot.onLocation((ctx) async {
    final location = ctx.message?.location;

    if (location != null) {
      await fetchWeatherData(ctx, latitude: location.latitude, longitude: location.longitude);
    } else {
      await ctx.reply('⚠️ Location ma\'lumotlari topilmadi. Iltimos, qayta yuboring.');
    }
  });

  /// Xabarni qayta ishlash
  bot.onMessage((ctx) async {
    final text = ctx.message?.text;

    if (text == null) {
      await ctx.reply('⚠️ Xabar noto‘g‘ri formatda.');
      return;
    }

    switch (text) {
      case onLocation:
        await ctx.reply('📍 Location orqali ob-havo funksiyasi tayyorlanmoqda.');
        break;
      case onCityName:
        await ctx.reply('🌎 Shahar nomini kiriting:');
        break;
      case onAutoWeather:
        await showAutoWeatherMenu(ctx);
        break;
      case onAutoLocationWeather:
        await ctx.reply('📍 Avto location orqali ob-havo funksiyasi tayyorlanmoqda.');
        break;
      case onAutoCityNameWeather:
        await ctx.reply('📝 Avto manzil kiritish orqali ob-havo funksiyasi tayyorlanmoqda.');
        break;
      case onMainMenu:
        await showMainMenu(ctx);
        break;
      default:
        await fetchWeatherData(ctx, cityName: text);
        break;
    }
  });

  /// Start komandasi
  bot.command('start', (ctx) async {
    await showMainMenu(ctx);
  });

  /// Botni ishga tushirish
  await bot.start();
}
