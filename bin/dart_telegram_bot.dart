import 'package:cron/cron.dart';
import 'package:dart_telegram_bot/constants/const_keys.dart';
import 'package:dart_telegram_bot/services/data/models/weather_model.dart';
import 'package:dart_telegram_bot/services/data/repository/currency_repository.dart';
import 'package:dart_telegram_bot/services/data/repository/image_repository.dart';
import 'package:dart_telegram_bot/services/data/repository/weather_repository.dart';
import 'package:dio/dio.dart';
import 'package:televerse/televerse.dart';

part './widgets/get_weather_function.dart';

void main() async {
  final bot = Bot(ConstKeys.botToken);
  final cron = Cron();

  const String onLocation = '📍 Location orqali';
  const String onCityName = '🌎 Shahar nomi orqali';
  const String onAutoWeather = '⏰ Avtomatik ob-havo sozlash';
  const String onAutoLocationWeather = '📍 Location orqali avto ob-havo';
  const String onAutoCityNameWeather = '📝 Shahar nomi orqali avto ob-havo';
  const String onMainMenu = '🔙 Bosh menu';

  int chatId = 0; // Global chatId saqlash

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
      ..requestLocation(onAutoLocationWeather)
      ..addText(onAutoCityNameWeather)
      ..row()
      ..addText(onMainMenu)
      ..resized();

    await ctx.reply(
      'Avtomatik ob-havo sozlash uchun quyidagi tugmalardan birini tanlang:',
      replyMarkup: keyboard,
    );
  }

  bot.command('start', (ctx) async {
    chatId = ctx.message?.chat.id ?? 0; // chatId ni saqlash
    await showMainMenu(ctx);
  });

  bot.onLocation((ctx) async {
    final location = ctx.message?.location;

    if (location == null) {
      await ctx.reply('⚠️ Iltimos, joylashuvni yuboring.');
      return;
    }

    await fetchWeatherData(ctx, latitude: location.latitude, longitude: location.longitude);
  });

  /// Xabarni qayta ishlash
  bot.onMessage((ctx) async {
    chatId = ctx.message!.chat.id;
    final text = ctx.message?.text;

    if (text == null) {
      await ctx.reply('⚠️ Xabar noto‘g‘ri formatda.');
      return;
    }

    switch (text) {
      case onMainMenu:
        await showMainMenu(ctx);
        break;
      case onLocation:
        await ctx.reply('📍 Location orqali ob-havo funksiyasi tayyorlanmoqda.');
        break;
      case onCityName:
        await ctx.reply('🌎 Shahar nomini kiriting:');
        break;
      case onAutoWeather:
        await showAutoWeatherMenu(ctx);
        break;
      default:
        await fetchWeatherData(ctx, cityName: text);
        break;
    }
  });

  cron.schedule(Schedule.parse('* * * * *'), () async {
    if (chatId != 0) {
      try {
        final weatherRepository = WeatherRepositoryImpl();
        final imageRepository = ImageRepositoryImpl();
        final currencyRepository = CurrencyRepositoryImpl();

        WeatherModel? weatherModel;
        String? imageUrl;

        weatherModel = await weatherRepository.getWeatherByName(cityName: 'Tashkent');
        imageUrl = await imageRepository.getImageByUrl(cityName: 'Tashkent');

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
          await bot.api.sendPhoto(
            ChatID(chatId),
            InputFile.fromUrl(imageUrl),
            caption: '⏰Avto ob-havo ma\'lumotlari: (TestMode)\n\n${weatherModel.toString()}',
            parseMode: ParseMode.markdown,
          );
        } else {
          await bot.api.sendMessage(
            ChatID(chatId),
           '⏰ Avto ob-havo ma\'lumotlari:\n\n${weatherModel.toString()}',
            parseMode: ParseMode.markdown,
          );
        }
      } catch (e) {
        print('Ob-havo ma\'lumotlarini olishda xatolik: $e');
        await bot.api.sendMessage(
          ChatID(chatId),
          '⚠️ Xatolik yuz berdi! Ob-havo ma\'lumotlarini olishda muammo paydo bo\'ldi.\n\nXato: $e',
        );
      }
    } else {
      
      print('Chat ID mavjud emas!');
    }
  });

  await bot.start();
}
