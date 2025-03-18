import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:lokaloka/globals.dart';
import 'package:translator/translator.dart';
import '../../../core/utils/apis.dart';
import '../services/LocationService.dart';
import '../services/wether_api.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  var imageUrl;
  int selectedForecast = 0;



  TextEditingController _textEditingController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  List<Map<String, dynamic>> vietnameseData = [];
  final translator = GoogleTranslator();

  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _locations = [];
  String? _selectedLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWeather(cityName);
    setState(() {});
    _fetchLocations();
  }

  void fetchWeather(String city) async {
    setState(() {
      isLoading = true;
    });

    var image_url = await ApiService().fetchImageUrl(cityName);

    var data = await WeatherApi().fetchWeather(cityName);
    if (data != null) {
      setState(() {
        weatherData = data;
        imageUrl = image_url;
        isLoading = false;
      });
    }
  }

  IconData getWeatherIcon(String weather) {
    switch (weather.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.cloudy_snowing;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'drizzle':
        return Icons.grain;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.blur_on;
      default:
        return Icons.help_outline;
    }
  }

  void searchByCity(BuildContext context) {
    TextEditingController cityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter city name"),
          content:

          TypeAheadField<Map<String, String>>(
            suggestionsCallback: (search) async {
              var results = _filterLocations(search);
              print("Suggestions: $results");
              return results;
            },
            builder: (context, controller, focusNode) {
              return TextFormField(
                controller: cityController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'Where to?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (_selectedLocation == null) {
                    return 'Please select a destination';
                  }
                  return null;
                },
              );
            },
            itemBuilder: (context, location) {
              return ListTile(
                title: Text(location['name'] ?? 'Unknown'),
              );
            },
            onSelected: (location) {
              _textEditingController.text = location['name']!;
              _selectedLocation = location['name']!;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                String city = cityController.text.trim();
                if (city.isNotEmpty) {
                  cityName = city;
                  fetchWeather(city);
                  Navigator.pop(context);
                }
              },
              child: Text("Search"),
            ),
          ],
        );
      },
    );
  }

  void changeForecast(int index) {
    setState(() {
      selectedForecast = index;
    });
    // Gọi API lấy dữ liệu thời tiết tương ứng nếu cần
  }

  void getCity() async {
    String? city = await LocationService.getCurrentCity();
    if (city != null) {
      cityName = city;
      print("Thành phố hiện tại: $city");
    } else {
      print("Không thể lấy thành phố.");
    }
  }

  Future<void> translateData(List<Map<String, dynamic>> vietnameseData) async {
    final translator = GoogleTranslator();

    await Future.wait(vietnameseData.map((item) async {
      var translatedName =
      await translator.translate(item['name'], from: 'vi', to: 'en');
      item['name'] = translatedName.text;
    }));
  }

  Future<void> _fetchLocations() async {
    try {
      final response = await _apiService.request(
          path: '', method: 'GET', typeUrl: 'locationUrl', currentPath: '');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        vietnameseData = List<Map<String, dynamic>>.from(data);
        await translateData(vietnameseData);

        setState(() {
          _locations = data
              .map((item) => {'id': item['id'], 'name': item['name']})
              .toList();
          setState(() {
            _isLoading = false;
          });
        });
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (e) {
      print('Error fetching locations: $e');
      setState(() {
        setState(() {
          _isLoading = false;
        });
      });
    }
  }

  List<Map<String, String>> _filterLocations(String query) {
    return _locations
        .where((location) => (location['name']?.toString().toLowerCase() ?? '')
        .contains(query.toLowerCase()))
        .map((location) => {
      'id': location['id'].toString(),
      'name': location['name'].toString(),
    })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(),
                  _buildWeatherDetails(),
                  _buildHourlyForecast(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 0, 0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("Forecast",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold))),
                  ),
                  _buildForecastSummary(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('$imageUrl'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 10,
          child: GestureDetector(
            onTap: () {
              getCity();
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        Positioned(
          top: 20,
          right: 10,
          child: GestureDetector(
            onTap: () => searchByCity(context),
            child: Icon(Icons.search, color: Colors.white),
          ),
        ),
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(cityName,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text("${(weatherData!['list'][0]['main']['temp'] as num).ceil()}°",
                  style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text("${weatherData!['list'][0]['weather'][0]['description']}",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        // Positioned(
        //   bottom: 10,
        //   left: 20,
        //   right: 20,
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //     children: [
        //       _weatherButton("Today",
        //           isActive: selectedForecast == 0,
        //           onTap: () => changeForecast(0)),
        //       _weatherButton("Tomorrow",
        //           isActive: selectedForecast == 1,
        //           onTap: () => changeForecast(1)),
        //       _weatherButton("5 day",
        //           isActive: selectedForecast == 2,
        //           onTap: () => changeForecast(2)),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _weatherButton(String text,
      {bool isActive = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.orange : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetails() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _weatherDetailCard(Icons.air, "Wind Speed",
                  "${weatherData!['list'][0]['wind']['speed']} km/h"),
              _weatherDetailCard(Icons.water_drop, "Humidity",
                  "${weatherData!['list'][0]['main']['humidity']}%"),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _weatherDetailCard(Icons.speed, "Pressure",
                  "${weatherData!['list'][0]['main']['pressure']} hPa"),
              _weatherDetailCard(Icons.wb_sunny, "UV Index", "2.3"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast() {
    return Container(
      margin: EdgeInsets.all(30),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.blue[200], borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_filled_rounded,
                color: Colors.white,
              ),
              SizedBox(
                width: 5,
              ),
              Text("Hourly forecast",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              var forecast = weatherData!['list'][index];
              return _hourlyForecastItem(
                  forecast['dt_txt'].split(' ')[1].substring(0, 5),
                  "${forecast['main']['temp']}°",
                  weatherData);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSummary() {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        padding: EdgeInsets.all(17),
        decoration: BoxDecoration(
            color: Colors.blue[200], borderRadius: BorderRadius.circular(10)),
        child: Text(
          "Now: ${weatherData!['list'][0]['main']['temp']}° ${weatherData!['list'][0]['weather'][0]['description']}.\n" +
              "Temperature range today is ${weatherData!['list'][0]['main']['temp_min']}° to ${weatherData!['list'][0]['main']['temp_max']}°.",
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }

  Widget _weatherDetailCard(IconData icon, String label, String value) {
    return Container(
      width: 167,
      height: 80,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.blue[200], borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 30, color: Colors.white),
              SizedBox(
                width: 5,
              ),
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 16, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _hourlyForecastItem(
      String time, String temp, Map<String, dynamic>? weatherData) {
    return Column(
      children: [
        Icon(
          getWeatherIcon(weatherData!['list'][0]['weather'][0]['main']),
          size: 24,
          color: Colors.white,
        ),
        Text(time, style: TextStyle(fontSize: 14, color: Colors.white)),
        Text(temp,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ],
    );
  }
}
