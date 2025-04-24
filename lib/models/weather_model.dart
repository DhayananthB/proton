class Weather {
  final String cityName;
  final double temperature;
  final String description;
  final String iconCode;
  final double windSpeed;
  final int humidity;
  final DateTime date;
  final List<WeatherForecast> forecast;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.iconCode,
    required this.windSpeed,
    required this.humidity,
    required this.date,
    required this.forecast,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    // Current weather data
    final currentWeather = json['current'];
    
    // Parse forecast data
    List<WeatherForecast> forecastList = [];
    if (json['forecast'] != null && json['forecast']['forecastday'] is List) {
      for (var day in json['forecast']['forecastday']) {
        forecastList.add(WeatherForecast.fromJson(day));
      }
    }

    return Weather(
      cityName: json['location']['name'] ?? 'Unknown',
      temperature: currentWeather['temp_c']?.toDouble() ?? 0.0,
      description: currentWeather['condition']['text'] ?? 'Unknown',
      iconCode: currentWeather['condition']['icon'] ?? '//cdn.weatherapi.com/weather/64x64/day/116.png',
      windSpeed: currentWeather['wind_kph']?.toDouble() ?? 0.0,
      humidity: currentWeather['humidity'] ?? 0,
      date: DateTime.parse(currentWeather['last_updated'] ?? DateTime.now().toString()),
      forecast: forecastList,
    );
  }
}

class WeatherForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final String iconCode;
  final String condition;
  final double chanceOfRain;

  WeatherForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.iconCode,
    required this.condition,
    required this.chanceOfRain,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final day = json['day'];
    
    return WeatherForecast(
      date: DateTime.parse(json['date']),
      maxTemp: day['maxtemp_c']?.toDouble() ?? 0.0,
      minTemp: day['mintemp_c']?.toDouble() ?? 0.0,
      iconCode: day['condition']['icon'] ?? '//cdn.weatherapi.com/weather/64x64/day/116.png',
      condition: day['condition']['text'] ?? 'Unknown',
      chanceOfRain: day['daily_chance_of_rain']?.toDouble() ?? 0.0,
    );
  }
} 