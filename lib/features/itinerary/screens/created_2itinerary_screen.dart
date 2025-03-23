import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lokaloka/core/styles/colors.dart';
import 'package:lokaloka/features/itinerary/models/Itinerary.dart';
import 'package:lokaloka/features/itinerary/screens/detail_itinerary_screen.dart';

import '../../../core/utils/apis.dart';
import '../../../globals.dart';

class ItineraryCreated extends StatelessWidget {
  final ItineraryResponse data;
  final String image;

  const ItineraryCreated({Key? key, required this.data, required this.image})
      : super(key: key);

  List<String> getLocationNames(ItineraryResponse itineraryResponse) {
    return itineraryResponse.itinerary
        .expand((itinerary) => itinerary.locations)
        .map((location) => location.name)
        .toList();
  }

  Future<List<String>> fetchImages(List<String> locationNames) async {
    return await Future.wait(
      locationNames.map((name) async {
        return await ApiService().fetchImageUrl(name) ?? '';
      }),
    );
  }

  Future<void> updateItineraryWithImages(
      ItineraryResponse itineraryResponse) async {
    List<String> locationNames = getLocationNames(itineraryResponse);
    images = await fetchImages(locationNames);

    int index = 0;
    for (var itinerary in itineraryResponse.itinerary) {
      for (var location in itinerary.locations) {
        if (index < images.length) {
          location.image = images[index];
          index++;
        }
      }
    }
  }

  void fetchImagesForLocations(ItineraryResponse data) async {
    await updateItineraryWithImages(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose your itinerary'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            bool? shouldPop = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Confirm"),
                content: Text("Are you sure you want to exit?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text("NO"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text("YES"),
                  ),
                ],
              ),
            );
            if (shouldPop == true) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            _buildPlanDetails(context, data),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDetails(BuildContext context, ItineraryResponse response) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: response.itinerary.map((itinerary) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (itinerary.title?.isNotEmpty ?? false)
              Text(
                itinerary.title ?? '',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orangeColor),
              ),
            SizedBox(height: 5),
            _buildItineraryCard(context, itinerary),
            SizedBox(height: 25),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildItineraryCard(BuildContext context, Itinerary item) {
    return InkWell(
      onTap: () {
        fetchImagesForLocations(data);
        final itinerary = data.itinerary.firstWhere((it) => it.title == item.title);
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => DetailItineraryScreen(
              itineraryItems: itinerary,
              type: "detail",
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image_not_supported,
                        size: 80,
                        color: Colors.grey);
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title ?? 'No title',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text('$travelDays Days'),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text('${item.price} VND'),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text('${item.locations.length} Destinations'),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.book, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  fetchImagesForLocations(data);
                  final itinerary =
                      data.itinerary.firstWhere((it) => it.id == item.id);
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => DetailItineraryScreen(
                        itineraryItems: itinerary,
                        type: "detail",
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: AppColors.orangeColor,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size(0, 0),
                ),
                child: Text(
                  'View detail',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
