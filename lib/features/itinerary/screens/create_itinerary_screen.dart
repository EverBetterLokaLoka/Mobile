import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../globals.dart';
import '../widgets/itinerary-app_bar.dart';
import 'create_iitinerary_by_ai_screen.dart';
import '../../../core/styles/colors.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/apis.dart';
import 'package:translator/translator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class CreateItinerary extends StatefulWidget {
  @override
  _CreateItineraryState createState() => _CreateItineraryState();
}

void updateTravelDays(int days) {
  travelDays = days;
}

class _CreateItineraryState extends State<CreateItinerary> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController _textEditingController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  List<Map<String, dynamic>> vietnameseData = [];
  final translator = GoogleTranslator();

  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _locations = [];
  String? _selectedLocation;
  bool _isLoading = true;

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
  void initState() {
    super.initState();
    _fetchLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ItineraryAppBar(
        titleText: 'Create Itinerary ',
        actions: [],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Plan a new trip',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orangeColor),
                ),
                SizedBox(height: 5),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox.fromSize(
                    child: Text(
                      'Build an itinerary and map out your \n upcoming navigation plans',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ),
                ),
                SizedBox.fromSize(
                  size: Size(0, 20),
                ),
                TypeAheadField<Map<String, String>>(
                  suggestionsCallback: (search) async {
                    return _filterLocations(search);
                  },
                  builder: (context, controller, focusNode) {
                    _textEditingController = controller;
                    return TextFormField(
                      controller: controller,
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
                SizedBox(height: 20),
                TextFormField(
                  controller: _dayController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'How many days?*',
                    hintText: 'E.g., 2',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Number of Days Traveled is required.';
                    }

                    final int? days = int.tryParse(value);

                    if (days == null) {
                      return 'Invalid input. Please enter a valid number.';
                    } else if (days < 1) {
                      return 'Invalid day. Please enter a positive day.';
                    } else if (days > 3) {
                      return 'Invalid day. Please enter a value between 1 and 3.';
                    }

                    return null;
                  },
                ),
                SizedBox(height: 20),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 160,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Creating an itinerary...')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                          ),
                          child: Text(
                            'Create Trip Manually',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 160,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              cityTrip = _selectedLocation.toString();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateByAi(
                                    location: _selectedLocation.toString(),
                                    totalDay: _dayController.text,
                                    startDate: _startDateController.text,
                                    endDate: _endDateController.text,
                                  ),
                                ),
                              );
                              updateTravelDays(int.parse(_dayController.text));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ImageIcon(
                                AssetImage('assets/images/star_ai.png'),
                                size: 22,
                                color: Colors.white,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Create By AI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
