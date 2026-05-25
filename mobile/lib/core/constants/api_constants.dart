class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String otpSend = '/auth/otp/send';
  static const String otpVerify = '/auth/otp/verify';
  static const String refresh = '/auth/refresh';

  // User
  static const String profile = '/users/me';

  // Kundli
  static const String kundliGenerate = '/kundli/generate';
  static const String kundli = '/kundli/';

  // Chat & Voice
  static const String chatMessage = '/chat/message';
  static const String chatGreeting = '/chat/greeting';
  static const String voiceChat = '/voice/chat';

  // Horoscope
  static const String dailyHoroscope = '/horoscope/daily';
  static const String weeklyHoroscope = '/horoscope/weekly';

  // Payments
  static const String plans = '/payments/plans';
  static const String createOrder = '/payments/create-order';
  static const String subscription = '/payments/subscription';
}

class AppStrings {
  static const String appName = 'AI Jyotish Guru';
  static const String tagline = 'आपका डिजिटल ज्योतिष गुरु';
  static const String greetingHi =
      'नमस्कार, आपका स्वागत है। मैं आपकी कुंडली के आधार पर '
      'आपके जीवन, करियर, विवाह और आने वाले समय के बारे में जानकारी दूंगा।';
}
