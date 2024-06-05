import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_forecast_app/services/weather_api_service.dart';

class WeatherHomePage extends StatefulWidget {
  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _controller = TextEditingController();
  final WeatherApiService _apiService = WeatherApiService();
  String _city = '';
  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>>? _dailyForecast;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLastSelectedCity();
  }

  Future<void> _loadLastSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _city = prefs.getString('selected_city') ?? '';
    });
    if (_city.isNotEmpty) {
      _fetchWeatherData(_city);
    }
  }

  Future<void> _fetchWeatherData(String city) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final currentWeather = await _apiService.getCurrentWeather(city);
      final forecast = await _apiService.get5DayForecast(city);

      setState(() {
        _currentWeather = currentWeather;
        _dailyForecast = _groupForecastByDay(forecast['list']);
      });

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('selected_city', city);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load weather data';
      });
      print('Error fetching weather data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _groupForecastByDay(List<dynamic> forecastList) {
    Map<String, List<dynamic>> groupedData = {};
    for (var item in forecastList) {
      String date = item['dt_txt'].split(' ')[0];
      if (!groupedData.containsKey(date)) {
        groupedData[date] = [];
      }
      groupedData[date]!.add(item);
    }

    List<Map<String, dynamic>> dailyData = [];
    groupedData.forEach((date, items) {
      dailyData.add({
        'date': date,
        'items': items,
      });
    });

    return dailyData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather Forecast App'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            if (_isLoading) _buildLoadingIndicator(),
            if (_errorMessage != null) _buildErrorMessage(),
            if (_currentWeather != null) _buildCurrentWeather(),
            if (_dailyForecast != null) _buildForecastList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Enter city',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
            },
          ),
        ),
        onSubmitted: (city) {
          if (city.isNotEmpty) {
            _fetchWeatherData(city);
          }
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Text(
        _errorMessage!,
        style: TextStyle(color: Colors.red, fontSize: 16),
      ),
    );
  }

  Widget _buildCurrentWeather() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Current Weather in ${_currentWeather!['name']}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getWeatherIcon(_currentWeather!['weather'][0]['icon']),
                SizedBox(width: 10),
                Text(
                  '${_currentWeather!['main']['temp']}°C',
                  style: TextStyle(fontSize: 40),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              _currentWeather!['weather'][0]['description'],
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _dailyForecast!.length,
        itemBuilder: (context, index) {
          final dayForecast = _dailyForecast![index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text(
                _formatDate(dayForecast['date']),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                children: dayForecast['items'].map<Widget>((item) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatTime(item['dt_txt'])),
                      _getWeatherIcon(item['weather'][0]['icon']),
                      Text('${item['main']['temp']}°C'),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getWeatherIcon(String iconCode) {
    return Image.network(
      'https://openweathermap.org/img/wn/$iconCode.png',
      width: 30,
      height: 30,
    );
  }

  String _formatDate(String dateTime) {
    final date = DateTime.parse(dateTime);
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(String dateTime) {
    final time = DateTime.parse(dateTime);
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
