import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// import 'package:geolocator/geolocator.dart';
import '../providers/language_provider.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/farmer_service.dart';
import '../models/farmer_model.dart';
import '../services/weather_notification_service.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Weather? _weather;
  Farmer? _farmer;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // First, get the farmer's data
      _farmer = await FarmerService.getFarmer();
      
      if (_farmer == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'farmerDataMissing';
        });
        return;
      }
      
      // Check if farmer has valid coordinates
      if (_farmer!.latitude == 0.0 && _farmer!.longitude == 0.0) {
        final location = '${_farmer!.village}, ${_farmer!.district}, ${_farmer!.state}';
        _weather = await WeatherService.getWeatherByCity(location);
      } else {
        // Check for invalid coordinate values
        if (_farmer!.latitude < -90 || _farmer!.latitude > 90 || 
            _farmer!.longitude < -180 || _farmer!.longitude > 180) {
          throw Exception('Invalid coordinates: ${_farmer!.latitude}, ${_farmer!.longitude}');
        }
        
        // Use farmer's stored coordinates
        _weather = await WeatherService.getWeatherByCoordinates(
          _farmer!.latitude,
          _farmer!.longitude,
        );
      }
      
      setState(() {
        _isLoading = false;
      });
      
      // Check if widget is still mounted before using context
      if (!mounted) return;
      
      // Check weather conditions and show notifications if necessary
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final isTamil = languageProvider.language == 'ta';
      await WeatherNotificationService.checkWeatherAndNotify(_weather!, isTamil);
    } on Exception {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'weatherError';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isTamil = languageProvider.language == 'ta';

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFA62E), Color(0xFFEA4D2C)],
              ),
            ),
          ),
          
          // Background patterns
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),

          Positioned(
            bottom: -100,
            left: -50,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(13),
                borderRadius: BorderRadius.circular(150),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        isTamil ? 'வானிலை' : 'Weather',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Refresh button
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadWeatherData,
                        tooltip: isTamil ? 'புதுப்பிக்க' : 'Refresh',
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: _isLoading
                      ? _buildLoadingWidget(isTamil)
                      : _hasError
                          ? _buildErrorWidget(isTamil)
                          : _buildWeatherContent(isTamil),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(bool isTamil) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            isTamil ? 'வானிலை தகவல்களை ஏற்றுகிறது...' : 'Loading weather data...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(bool isTamil) {
    String errorText;
    
    if (_errorMessage == 'farmerDataMissing') {
      errorText = isTamil 
          ? 'விவசாயி தகவல்கள் கிடைக்கவில்லை. முதலில் உங்கள் சுயவிவரத்தை உருவாக்கவும்.'
          : 'Farmer data is missing. Please create your profile first.';
    } else {
      errorText = isTamil
          ? 'வானிலை தகவல்களை பெற முடியவில்லை. தயவுசெய்து மீண்டும் முயற்சிக்கவும்.'
          : 'Could not fetch weather data. Please try again.';
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              color: Colors.white,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              errorText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadWeatherData,
              icon: const Icon(Icons.refresh),
              label: Text(isTamil ? 'மீண்டும் முயற்சி செய்' : 'Retry'),
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color(0xFFEA4D2C),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherContent(bool isTamil) {
    if (_weather == null) return const SizedBox.shrink();
    
    // Get translations for Tamil if needed
    final tamilTranslations = isTamil 
        ? WeatherService.getTamilWeatherTranslations(_weather!.description)
        : <String, String>{};
    
    final weatherDescription = isTamil 
        ? tamilTranslations['condition'] ?? _weather!.description
        : _weather!.description;
    
    final dateFormat = DateFormat('E, dd MMM yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location display
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _weather!.cityName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Date and time
            Text(
              dateFormat.format(_weather!.date),
              style: TextStyle(
                color: Colors.white.withAlpha(230),
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Weather icon and temperature
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  'https:${_weather!.iconCode}',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.cloud,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _weather!.temperature.round().toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '°C',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      weatherDescription,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Weather details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(51)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Wind
                  _buildWeatherDetailItem(
                    icon: Icons.air,
                    value: '${_weather!.windSpeed.round()} ${isTamil ? tamilTranslations['kph'] : 'km/h'}',
                    label: isTamil ? tamilTranslations['wind']! : 'Wind',
                  ),
                  // Humidity
                  _buildWeatherDetailItem(
                    icon: Icons.water_drop_outlined,
                    value: '${_weather!.humidity}${isTamil ? tamilTranslations['percent'] : '%'}',
                    label: isTamil ? tamilTranslations['humidity']! : 'Humidity',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Crop Advisory Section
            _buildCropAdvisorySection(isTamil),
            
            const SizedBox(height: 30),
            
            // Forecast title
            Text(
              isTamil ? tamilTranslations['forecast']! : 'Forecast',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Forecast list
            SizedBox(
              height: 145,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _weather!.forecast.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final forecast = _weather!.forecast[index];
                  final day = DateFormat('E').format(forecast.date);
                  final dayTamil = _getDayNameInTamil(forecast.date);
                  
                  
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(38),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(51)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isTamil ? dayTamil : day,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Image.network(
                          'https:${forecast.iconCode}',
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.cloud,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${forecast.maxTemp.round()}°/${forecast.minTemp.round()}°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${forecast.chanceOfRain.round()}%',
                          style: TextStyle(
                            color: Colors.white.withAlpha(204),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Last updated text
            Center(
              child: Text(
                '${isTamil ? tamilTranslations['updated'] : 'Updated'}: ${timeFormat.format(_weather!.date)}',
                style: TextStyle(
                  color: Colors.white.withAlpha(179),
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWeatherDetailItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(204),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  String _getDayNameInTamil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateDay = DateTime(date.year, date.month, date.day);
    
    if (dateDay == today) {
      return 'இன்று';
    } else if (dateDay == tomorrow) {
      return 'நாளை';
    }
    
    final dayOfWeek = date.weekday;
    switch (dayOfWeek) {
      case DateTime.monday:
        return 'திங்கள்';
      case DateTime.tuesday:
        return 'செவ்வாய்';
      case DateTime.wednesday:
        return 'புதன்';
      case DateTime.thursday:
        return 'வியாழன்';
      case DateTime.friday:
        return 'வெள்ளி';
      case DateTime.saturday:
        return 'சனி';
      case DateTime.sunday:
        return 'ஞாயிறு';
      default:
        return '';
    }
  }
  
  // New method to build crop advisory section
  Widget _buildCropAdvisorySection(bool isTamil) {
    // Define thresholds for different weather conditions
    const double highRainThreshold = 60.0; // 60% chance of rain
    const double highWindThreshold = 25.0; // 25 km/h
    const double highTempThreshold = 35.0; // 35°C
    
    // Check weather conditions
    bool hasHighRainChance = false;
    bool hasHighWinds = false;
    bool hasHighTemperature = false;
    
    // Check today's temperature
    if (_weather!.temperature >= highTempThreshold) {
      hasHighTemperature = true;
    }
    
    // Check wind speed
    if (_weather!.windSpeed >= highWindThreshold) {
      hasHighWinds = true;
    }
    
    // Check forecast for rain
    if (_weather!.forecast.isNotEmpty && _weather!.forecast[0].chanceOfRain >= highRainThreshold) {
      hasHighRainChance = true;
    }
    
    // If no alerts, return empty container
    if (!hasHighRainChance && !hasHighWinds && !hasHighTemperature) {
      return const SizedBox();
    }
    
    // Build advisory messages
    List<Widget> advisories = [];
    
    if (hasHighRainChance) {
      advisories.add(
        _buildAdvisoryItem(
          icon: Icons.umbrella,
          title: isTamil ? 'மழை எச்சரிக்கை' : 'Rain Alert',
          message: isTamil 
              ? 'இன்று அதிக மழைக்கு வாய்ப்பு உள்ளது. பயிர்களுக்கு தண்ணீர் பாய்ச்சுவதை தவிர்க்கவும்.'
              : 'High chance of rain today. Avoid watering your crops.',
          color: Colors.blue,
        ),
      );
    }
    
    if (hasHighWinds) {
      advisories.add(
        _buildAdvisoryItem(
          icon: Icons.air,
          title: isTamil ? 'காற்று எச்சரிக்கை' : 'Wind Alert',
          message: isTamil 
              ? 'அதிக காற்று வீசுகிறது. பயிர்களை பாதுகாப்பாக வைக்க நடவடிக்கை எடுக்கவும்.'
              : 'Strong winds are expected. Take measures to protect your crops.',
          color: Colors.orange,
        ),
      );
    }
    
    if (hasHighTemperature) {
      advisories.add(
        _buildAdvisoryItem(
          icon: Icons.wb_sunny,
          title: isTamil ? 'வெப்பநிலை எச்சரிக்கை' : 'Heat Alert',
          message: isTamil 
              ? 'அதிக வெப்பநிலை உள்ளது. பயிர்களுக்கு வழக்கத்தை விட அதிகமாக தண்ணீர் பாய்ச்சவும்.'
              : 'High temperature detected. Water your crops more frequently.',
          color: Colors.red,
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Advisory title
        Text(
          isTamil ? 'பயிர் ஆலோசனை' : 'Crop Advisory',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Advisory list
        Column(
          children: advisories,
        ),
      ],
    );
  }
  
  // Helper method to build advisory items
  Widget _buildAdvisoryItem({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}