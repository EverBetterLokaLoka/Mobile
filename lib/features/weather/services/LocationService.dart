import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static Future<bool> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    return permission != LocationPermission.deniedForever;
  }

  static Future<Position?> getCurrentLocation() async {
    if (await checkPermission()) {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }
    return null;
  }

  static Future<String?> getCityFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        String? province = place.administrativeArea;

        print("Tỉnh/Thành phố lấy được: $province");
        return province;
      } else {
        print("Không tìm thấy tỉnh/thành phố.");
      }
    } catch (e) {
      print("Lỗi lấy địa điểm: $e");
    }
    return null;
  }

  static Future<String?> getCurrentCity() async {
    Position? position = await getCurrentLocation();
    if (position != null) {
      return await getCityFromCoordinates(
          position.latitude, position.longitude);
    }
    return null;
  }

  static const String apiKey = "Yg9F1M4zefVwffqyQz-d7SuRYZnDwhyUgbCoOkEwf_8";

  static Future<List<LatLng>> getCoordinatesFromAddresses(List<String> places, String city) async {
    List<LatLng> coordinates = [];

    for (String place in places) {
      final String query = "$place, $city, Viet Nam";
      final url = Uri.parse("https://geocode.search.hereapi.com/v1/geocode?q=${Uri.encodeComponent(query)}&apiKey=$apiKey");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'].isNotEmpty) {
          double lat = data['items'][0]['position']['lat'];
          double lon = data['items'][0]['position']['lng'];
          coordinates.add(LatLng(lat, lon));
        }
      }
    }
    print(coordinates);

    return coordinates;
  }

  Future<String> getAddressesFromItinerary(
      Map<String, dynamic> jsonData) async {
    if (jsonData.containsKey("address")) {
      return jsonData["address"] as String;
    }
    return "";
  }
}
