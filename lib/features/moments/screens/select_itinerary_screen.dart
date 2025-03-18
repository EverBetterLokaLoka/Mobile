import 'package:flutter/material.dart';
import 'dart:convert';

import '../../itinerary/services/itinerary_api.dart';

class SelectItineraryScreen extends StatefulWidget {
  @override
  _SelectItineraryScreenState createState() => _SelectItineraryScreenState();
}

class _SelectItineraryScreenState extends State<SelectItineraryScreen> {
  List<Map<String, dynamic>> itineraries = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchItineraries();
  }

  Future<void> _fetchItineraries() async {
    setState(() => isLoading = true);

    final fetchedItineraries = await ItineraryApi().fetchItineraries();

    final filteredItineraries = fetchedItineraries.where((itinerary) {
      return itinerary['status'] == 2;
    }).toList();

    setState(() {
      itineraries = filteredItineraries;
      isLoading = false;
    });
  }

  void _selectItinerary(Map<String, dynamic> itinerary) {
    Navigator.pop(context, itinerary);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Choose Itinerary")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: itineraries.length,
        itemBuilder: (context, index) {
          final itinerary = itineraries[index];
          return GestureDetector(
            onTap: () => _selectItinerary(itinerary),
            child: _buildTripCard(itinerary),
          );
        },
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: trip['locations'] != null && trip['locations'].isNotEmpty
                    ? Image.network(
                  trip['locations'].firstWhere(
                        (location) => location['image'] != null && location['image'].isNotEmpty,
                    orElse: () => {'image': ''},
                  )['image'],
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300], // Placeholder
                  child: Icon(Icons.image, color: Colors.grey),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip['title'] ?? 'Unknown Title',
                      style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text('2 days 1 night',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text(trip['price']?.toString() ?? 'N/A',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.place, size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text('${trip['locations']?.length ?? 0} Destinations',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
