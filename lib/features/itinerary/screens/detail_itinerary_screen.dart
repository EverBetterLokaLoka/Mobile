import 'package:flutter/material.dart';
import '../../../core/styles/colors.dart';
import '../../../core/utils/transfer_money.dart';
import '../../../globals.dart';
import '../../../widgets/notice_widget.dart';
import '../services/itinerary_api.dart';
import '../models/Itinerary.dart';
import '../../../core/utils/fortmat_daytime.dart';
import 'package:timeline_tile/timeline_tile.dart';

class DetailItineraryScreen extends StatefulWidget {
  final Itinerary itineraryItems;
  final String? title;
  final String type;

  const DetailItineraryScreen(
      {Key? key, required this.itineraryItems, this.title, required this.type})
      : super(key: key);

  @override
  _DetailItineraryScreenState createState() => _DetailItineraryScreenState();
}

class _DetailItineraryScreenState extends State<DetailItineraryScreen> {
  int selectedDay = 1;
  bool _isExpanded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _preloadImages();
  }

  void _preloadImages() {
    for (var location in widget.itineraryItems.locations) {
      if (location.image != null && location.image!.isNotEmpty) {
        precacheImage(NetworkImage(location.image!), context);
      }
    }
  }

  Future<bool> showNotice(
      BuildContext context, String message, String type) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (type != "error") ...[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor:
                              type == "error" ? Colors.red : Colors.cyan,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "OK",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itineraryItems.locations.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          // actions: [
          //   TextButton(
          //     onPressed: () => Navigator.of(context).pop(false),
          //     child: Text("NO"),
          //   ),
          //   TextButton(
          //     onPressed: () => Navigator.of(context).pop(true),
          //     child: Text("YES"),
          //   ),
          // ],
          title: Text('Detail Itinerary'),
        ),
        body: const Center(
          child: Text(
            "No locations available.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }
    List<Location> filteredLocations = widget.itineraryItems.locations
        .where((location) => location.day == selectedDay)
        .toList();

    void handleDialog(BuildContext context) async {
      bool? result = await showNotice(context,
          "Save Itinerary successfully!\nDo you want to exits?", "confirm");
      if (result == true) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/my-trip',
          ModalRoute.withName('/home'),
        );
      }
    }

    Future<String?> showTripNameDialog(BuildContext context) async {
      TextEditingController nameController = TextEditingController();
      String? errorMessage;

      return showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                contentPadding: const EdgeInsets.all(20.0),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Enter a name for your trip",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Name:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        errorText: errorMessage,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(null);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Cancel",
                              style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            String trimmedText = nameController.text.trim();

                            if (trimmedText.isEmpty) {
                              if (nameController.text.isEmpty) {
                                setState(() {
                                  errorMessage = "Please enter a trip name.";
                                });
                              } else {
                                setState(() {
                                  errorMessage = "Enter valid trip name.";
                                });
                              }
                            } else {
                              Navigator.of(context).pop(nameController.text);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Save",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    void _showTripDialog(BuildContext context) async {
      String? tripName = await showTripNameDialog(context);

      if (tripName != null) {
        widget.itineraryItems.title = tripName;
        int index = 0;
        for (var location in widget.itineraryItems.locations) {
          if (index < images.length) {
            location.image = images[index];
            index++;
          }
        }
        String? result =
            await ItineraryApi().saveItinerary(context, widget.itineraryItems);
        if (result == "ok") {
          handleDialog(context);
        } else if (result == "douLiName") {
          await showCustomNotice(
              context,
              "Title already exits. Please enter the difference tile",
              "noitice");
        }
        print("User entered trip name: $tripName");
      } else {
        print("User canceled the dialog.");
      }
    }

    // return WillPopScope(
        // onWillPop: () async {
        //   bool? shouldPop = await showDialog<bool>(
        //     context: context,
        //     builder: (context) => AlertDialog(
        //       title: Text("Confirm"),
        //       content: Text("Are you sure you want to exit?"),
        //       actions: [
        //         TextButton(
        //           onPressed: () => Navigator.of(context).pop(false),
        //           child: Text("NO"),
        //         ),
        //         TextButton(
        //           onPressed: () => Navigator.of(context).pop(true),
        //           child: Text("YES"),
        //         ),
        //       ],
        //     ),
        //   );
        //   return shouldPop ?? false;
        // },
        // child: Scaffold(

    return Scaffold(
    appBar: AppBar(
            title: Text(widget.title ?? 'Itinerary Detail'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(travelDays, (index) {
                      int dayNumber = index + 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedDay = dayNumber;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedDay == dayNumber
                                ? AppColors.orangeColor
                                : AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          child: Text(
                            "Day $dayNumber",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: filteredLocations.isNotEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.all(14.0),
                          itemCount: filteredLocations.length,
                          itemBuilder: (context, index) {
                            final location = filteredLocations[index];
                            return _buildTimelineTile(
                                location,
                                index,
                                index == 0,
                                index == filteredLocations.length - 1);
                          },
                        )
                      : const Center(
                          child: Text(
                            "No locations available for this day.",
                            style:
                                TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: widget.type == "view"
              ? null
              : Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    if (_isExpanded) ...[
                      _buildOptionButton(
                          Icons.bookmark, AppColors.orangeColor, 70, () {
                        _showTripDialog(context);
                      }),
                      // _buildOptionButton(Icons.edit, AppColors.orangeColor, 68,
                      //     () {
                      //   print("Edit Clicked");
                      // }),
                    ],
                    Positioned(
                      bottom: 20,
                      right: 10,
                      child: FloatingActionButton.small(
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        backgroundColor: AppColors.orangeColor,
                        shape: const CircleBorder(),
                        child: Icon(
                          _isExpanded ? Icons.close : Icons.add,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
        );
  }

  Widget _buildTimelineTile(
      Location location, int index, bool isFirst, bool isLast) {
    return TimelineTile(
      alignment: TimelineAlign.manual,
      lineXY: 0.1,
      isFirst: isFirst,
      isLast: isLast,
      indicatorStyle: IndicatorStyle(
        width: 10,
        color: AppColors.primaryColor,
        indicatorXY: 0.0,
        padding: const EdgeInsets.all(4),
      ),
      beforeLineStyle: LineStyle(
        color: AppColors.primaryColor,
        thickness: 2,
      ),
      startChild: Column(
        children: [
          const SizedBox(height: 5),
          Text(
            formatStartTime(location.timeStart.toString()),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: Colors.black),
          ),
        ],
      ),
      endChild: Padding(
        padding: const EdgeInsets.only(left: 16.0, bottom: 20.0),
        child: _buildLocationCard(location, index),
      ),
    );
  }

  Widget _buildLocationCard(Location location, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Destination ${index + 1}: ${location.name}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              location.image!,
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 190,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 190,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: Icon(Icons.image_not_supported,
                      size: 50, color: Colors.grey),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (location.name.isNotEmpty) ...[
                  Text(
                    location.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orangeColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                if (location.description.isNotEmpty)
                  Text(
                    location.description,
                    style: const TextStyle(color: Colors.black54),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: AppColors.primaryColor),
                    const SizedBox(width: 5),
                    const Text("Visit duration: ",
                        style: TextStyle(color: AppColors.primaryColor)),
                    Text(
                      formatVisitTime(
                        location.timeStart.toString(),
                        location.timeFinish.toString(),
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.attach_money,
                        color: AppColors.primaryColor),
                    const SizedBox(width: 5),
                    const Text("Cost: ",
                        style: TextStyle(color: AppColors.primaryColor)),
                    Text(
                      CurrencyFormatter.formatVnd(location.price),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                if (location.culture?.isNotEmpty ?? false)
                  Row(
                    children: [
                      const Icon(Icons.home_repair_service_sharp,
                          color: AppColors.primaryColor),
                      const SizedBox(width: 5),
                      const Text("Culture: ",
                          style: TextStyle(color: AppColors.primaryColor)),
                      Text(
                        location.culture!,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                if (location.activities.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Activities:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      ...location.activities.map(
                        (activity) => Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "• ${activity.name}: ${activity.description}",
                                style: const TextStyle(color: Colors.black87),
                              ),
                              const SizedBox(height: 3),
                              if (activity.activitiesPossible != null &&
                                  activity.activitiesPossible!.isNotEmpty)
                                Text(
                                  "   🔹 Possible: ${activity.activitiesPossible}",
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              Text(
                                "   💰 Price: ${CurrencyFormatter.formatVnd(activity.price.toString())}",
                                style: const TextStyle(color: Colors.black87),
                              ),
                              if (activity.rule != null &&
                                  activity.rule!.isNotEmpty)
                                Text(
                                  "   ⚠️ Rule: ${activity.rule}",
                                  style: const TextStyle(color: Colors.red),
                                ),
                              if (activity.recommend != null &&
                                  activity.recommend!.isNotEmpty)
                                Text(
                                  "   ⭐ Recommend: ${activity.recommend}",
                                  style: const TextStyle(color: Colors.green),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
      IconData icon, Color color, double bottom, VoidCallback onPressed) {
    return Positioned(
      bottom: bottom,
      right: 10,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: color,
        onPressed: onPressed,
        shape: const CircleBorder(),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
