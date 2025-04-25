import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/weather_model.dart';

class WeatherNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  // Initialize notifications
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notifications.initialize(
      initializationSettings,
    );
    
    _isInitialized = true;
  }
  
  // Check weather conditions and show notifications if necessary
  static Future<void> checkWeatherAndNotify(Weather weather, bool isTamil) async {
    await initialize();
    
    // Define thresholds for weather alerts
    const double highRainThreshold = 60.0; // 60% chance of rain
    const double highWindThreshold = 25.0; // 25 km/h
    const double highTempThreshold = 35.0; // 35°C
    
    // Check today's weather for high temperatures
    if (weather.temperature >= highTempThreshold) {
      _showNotification(
        id: 1,
        title: isTamil ? 'அதிக வெப்பநிலை எச்சரிக்கை' : 'High Temperature Alert',
        body: isTamil 
            ? 'தற்போதைய வெப்பநிலை ${weather.temperature.round()}°C. பயிர்களுக்கு தண்ணீர் பாய்ச்சுவதை அதிகரிக்கவும்.' 
            : 'Current temperature is ${weather.temperature.round()}°C. Increase watering for your crops.',
      );
    }
    
    // Check if there's a forecast for rain or high winds in the next 24 hours
    if (weather.forecast.isNotEmpty) {
      final todayForecast = weather.forecast[0];
      
      // Check for high chance of rain
      if (todayForecast.chanceOfRain >= highRainThreshold) {
        _showNotification(
          id: 2,
          title: isTamil ? 'மழை எச்சரிக்கை' : 'Rain Alert',
          body: isTamil 
              ? 'இன்று ${todayForecast.chanceOfRain.round()}% மழைக்கான வாய்ப்பு உள்ளது. பயிர்களுக்கு தண்ணீர் பாய்ச்சுவதை தவிர்க்கவும்.' 
              : 'There is a ${todayForecast.chanceOfRain.round()}% chance of rain today. Avoid watering your crops.',
        );
      }
      
      // Check for high winds
      if (weather.windSpeed >= highWindThreshold) {
        _showNotification(
          id: 3,
          title: isTamil ? 'அதிக காற்று எச்சரிக்கை' : 'High Wind Alert',
          body: isTamil 
              ? 'தற்போது ${weather.windSpeed.round()} கி.மீ/மணி வேகத்தில் காற்று வீசுகிறது. உங்கள் பயிர்களை பாதுகாக்க நடவடிக்கை எடுக்கவும்.' 
              : 'Current wind speed is ${weather.windSpeed.round()} km/h. Take measures to protect your crops.',
        );
      }
    }
  }
  
  // Show a notification
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'weather_alerts',
      'Weather Alerts',
      channelDescription: 'Notifications for weather conditions affecting crops',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        
    await _notifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
} 