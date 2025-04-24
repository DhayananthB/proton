import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';

class WeatherService {
  // Use WeatherAPI (https://www.weatherapi.com/) - requires API key
  // Sign up for a free API key and replace 'YOUR_API_KEY' with your actual key
  static const String apiKey = '3e3151b8fdb54a058bc225258252404';
  static const String baseUrl = 'https://api.weatherapi.com/v1';

  // Get weather based on location coordinates
  static Future<Weather> getWeatherByCoordinates(double latitude, double longitude) async {
    try {
      // Format coordinates with proper precision
      final String formattedLat = latitude.toStringAsFixed(6);
      final String formattedLon = longitude.toStringAsFixed(6);
      
      print('Fetching weather for coordinates: $formattedLat, $formattedLon');
      
      final Uri uri = Uri.parse('$baseUrl/forecast.json?key=$apiKey&q=$formattedLat,$formattedLon&days=5&aqi=no&alerts=no');
      print('Weather API URL: ${uri.toString()}');
      
      final response = await http.get(uri);
      
      print('Weather API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Weather data received for: ${data['location']['name']}');
        return Weather.fromJson(data);
      } else {
        print('Failed to load weather: ${response.statusCode}, Response: ${response.body}');
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching weather by coordinates: $e');
      throw Exception('Error fetching weather: $e');
    }
  }

  // Get weather for a specific city
  static Future<Weather> getWeatherByCity(String city) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/forecast.json?key=$apiKey&q=$city&days=5&aqi=no&alerts=no'),
      );

      if (response.statusCode == 200) {
        return Weather.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }

  // Get the current location of the user
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get the current position
    return await Geolocator.getCurrentPosition();
  }

  // Get weather forecast translations in Tamil
  static Map<String, String> getTamilWeatherTranslations(String condition) {
    final tamilTranslations = {
      'Sunny': 'சூரியன் உள்ளது',
      'Clear': 'தெளிவாக உள்ளது',
      'Partly cloudy': 'ஓரளவு மேகமூட்டம்',
      'Cloudy': 'மேகமூட்டமானது',
      'Overcast': 'மேகமூட்டமானது',
      'Mist': 'மூடுபனி',
      'Patchy rain possible': 'சில இடங்களில் மழை பெய்யலாம்',
      'Patchy snow possible': 'சில இடங்களில் பனி பெய்யலாம்',
      'Patchy sleet possible': 'சில இடங்களில் ஆலங்கட்டி மழை பெய்யலாம்',
      'Patchy freezing drizzle possible': 'சில இடங்களில் உறைந்த தூறல் மழை சாத்தியம்',
      'Thundery outbreaks possible': 'இடியுடன் கூடிய மழை சாத்தியம்',
      'Blowing snow': 'பனி வீசும்',
      'Blizzard': 'பனிப்புயல்',
      'Fog': 'மூடுபனி',
      'Freezing fog': 'உறைந்த மூடுபனி',
      'Patchy light drizzle': 'சில இடங்களில் இலேசான தூறல் மழை',
      'Light drizzle': 'இலேசான தூறல் மழை',
      'Freezing drizzle': 'உறைந்த தூறல் மழை',
      'Heavy freezing drizzle': 'கனமான உறைந்த தூறல் மழை',
      'Patchy light rain': 'சில இடங்களில் இலேசான மழை',
      'Light rain': 'இலேசான மழை',
      'Moderate rain at times': 'சில நேரங்களில் மிதமான மழை',
      'Moderate rain': 'மிதமான மழை',
      'Heavy rain at times': 'சில நேரங்களில் கனமழை',
      'Heavy rain': 'கனமழை',
      'Light freezing rain': 'இலேசான உறைந்த மழை',
      'Moderate or heavy freezing rain': 'மிதமான அல்லது கனமான உறைந்த மழை',
      'Light sleet': 'இலேசான ஆலங்கட்டி மழை',
      'Moderate or heavy sleet': 'மிதமான அல்லது கனமான ஆலங்கட்டி மழை',
      'Patchy light snow': 'சில இடங்களில் இலேசான பனி',
      'Light snow': 'இலேசான பனி',
      'Patchy moderate snow': 'சில இடங்களில் மிதமான பனி',
      'Moderate snow': 'மிதமான பனி',
      'Patchy heavy snow': 'சில இடங்களில் கனமான பனி',
      'Heavy snow': 'கனமான பனி',
      'Ice pellets': 'பனிக்கட்டிகள்',
      'Light rain shower': 'இலேசான மழைப் பொழிவு',
      'Moderate or heavy rain shower': 'மிதமான அல்லது கனமான மழைப் பொழிவு',
      'Torrential rain shower': 'பெருமழைப் பொழிவு',
      'Light sleet showers': 'இலேசான ஆலங்கட்டி மழைப் பொழிவு',
      'Moderate or heavy sleet showers': 'மிதமான அல்லது கனமான ஆலங்கட்டி மழைப் பொழிவு',
      'Light snow showers': 'இலேசான பனிப் பொழிவு',
      'Moderate or heavy snow showers': 'மிதமான அல்லது கனமான பனிப் பொழிவு',
      'Light showers of ice pellets': 'இலேசான பனிக்கட்டி பொழிவு',
      'Moderate or heavy showers of ice pellets': 'மிதமான அல்லது கனமான பனிக்கட்டி பொழிவு',
      'Patchy light rain with thunder': 'இடியுடன் சில இடங்களில் இலேசான மழை',
      'Moderate or heavy rain with thunder': 'இடியுடன் மிதமான அல்லது கனமான மழை',
      'Patchy light snow with thunder': 'இடியுடன் சில இடங்களில் இலேசான பனி',
      'Moderate or heavy snow with thunder': 'இடியுடன் மிதமான அல்லது கனமான பனி',
    };

    return {
      'condition': tamilTranslations[condition] ?? condition,
      'city': 'நகரம்',
      'temperature': 'வெப்பநிலை',
      'wind': 'காற்று',
      'humidity': 'ஈரப்பதம்',
      'forecast': 'வானிலை முன்னறிவிப்பு',
      'today': 'இன்று',
      'tomorrow': 'நாளை',
      'maxTemp': 'அதிகபட்ச வெப்பநிலை',
      'minTemp': 'குறைந்தபட்ச வெப்பநிலை',
      'chanceOfRain': 'மழை பெய்ய வாய்ப்பு',
      'loading': 'வானிலை தகவல்களை ஏற்றுகிறது...',
      'locationError': 'உங்கள் இருப்பிடத்தை பெற முடியவில்லை',
      'weatherError': 'வானிலை தகவல்களை பெற முடியவில்லை',
      'permissionDenied': 'இருப்பிட அனுமதி மறுக்கப்பட்டது',
      'enableLocation': 'வானிலை தகவல்களுக்கு இருப்பிட சேவைகளை இயக்கவும்',
      'retry': 'மீண்டும் முயற்சி செய்',
      'kph': 'கி.மீ/மணி',
      'celsius': '°C',
      'percent': '%',
      'feelsLike': 'உணர்கிறது',
      'updated': 'புதுப்பிக்கப்பட்டது',
      'weatherForecast': 'வானிலை முன்னறிவிப்பு',
      'dayForecast': 'நாள் முன்னறிவிப்பு',
    };
  }
} 