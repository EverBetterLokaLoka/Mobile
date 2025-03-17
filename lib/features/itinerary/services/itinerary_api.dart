import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:lokaloka/globals.dart';

import '../../../core/utils/apis.dart';
import '../models/Itinerary.dart';

class ItineraryApi {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> fetchItineraries() async {
    try {
      final response = await _apiService.request(
        path: '/itineraries',
        method: 'GET',
        typeUrl: 'baseUrl',
        currentPath: '',
      );

      if (response.statusCode == 200) {
        final dynamic responseBody = jsonDecode(response.body);

        if (responseBody is Map<String, dynamic> &&
            responseBody.containsKey('data')) {
          final dynamic data = responseBody['data'];
          if (data is List) {
            return List<Map<String, dynamic>>.from(data);
          }
        }
      }
    } catch (e) {
      print("Error fetching itineraries: $e");
    }
    return [];
  }

  Future<String?> saveItinerary(Itinerary itinerary) async {
    try {
      final Map<String, dynamic> body = {
        "title": itinerary.title,
        "description": itinerary.description,
        "price": itinerary.price,
        "address": cityTrip ?? "",
        "init_date": travelDays ?? "",
        "locations": itinerary.locations.map((location) {
          return {
            "name": location.name,
            "day": location.day,
            "description": location.description,
            "image": location.image ?? "",
            "flag": location.flag ?? false,
            "time_start": location.timeStart?.toUtc().toIso8601String() ?? "",
            "time_finish": location.timeFinish?.toUtc().toIso8601String() ?? "",
            "time_reminder": location.timeReminder ?? "0",
            "culture": location.culture ?? "",
            "recommended_time": location.recommendedTime ?? "",
            "price": location.price?.toString() ?? "0.0",
            "activities": location.activities.map((activity) {
              return {
                "name": activity.name,
                "description": activity.description,
                "activities_possible": activity.activitiesPossible ?? "",
                "price": activity.price?.toString() ?? "0.0",
                "rule": activity.rule ?? "",
                "recommend": activity.recommend ?? "",
              };
            }).toList(),
          };
        }).toList(),
      };

      debugPrint("Request body: $body", wrapWidth: 1024);

      final response = await _apiService.request(
        path: '/itineraries',
        method: 'POST',
        typeUrl: 'baseUrl',
        currentPath: '',
        data: body,
      );

      print("Response received");

      if (response.statusCode == 201) {
        print("Itinerary saved successfully!");
        return "ok";
      }
      if (response.statusCode == 403) {
        print("Itinerary saved successfully!");
        return "douLiName";
      } else {
        print(
            "Failed to save itinerary: ${response.body ?? 'No response body'}");
        return "fail";
      }
    } catch (e, stackTrace) {
      print("Error saving itinerary: $e");
      print(stackTrace);
    }
    return "false";
  }

  Future<Itinerary> getItineraryById(int? itineraryId) async {
    try {
      final response = await _apiService.request(
        path: '/itineraries/$itineraryId',
        method: 'GET',
        typeUrl: 'baseUrl',
        currentPath: '',
      );

      if (response.statusCode == 200) {
        final dynamic responseBody = jsonDecode(response.body);

        if (responseBody is Map<String, dynamic>) {
          if (responseBody.containsKey('data') &&
              responseBody['data'] != null) {
            return Itinerary.fromJson(responseBody['data']);
          }
          return Itinerary(
              id: 0,
              title: "Unknown",
              description: "No data",
              price: "0",
              locations: []);
        }
      }
    } catch (e) {
      print("Error fetching itinerary by ID: $e");
    }
    return Itinerary(locations: [], id: 0);
  }

  Future<bool?> deleteItinerary(int itineraryId) async {
    try {
      final response = await _apiService.request(
        path: '/itineraries/$itineraryId',
        method: 'DELETE',
        typeUrl: 'baseUrl',
        currentPath: '',
      );

      if (response.statusCode == 204) {
        print("Itinerary deleted successfully!");
        return true;
      } else {
        print("Failed to delete itinerary: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error deleting itinerary: $e");
      return false;
    }
  }

  Future<bool?> goItineraryUpdate(int? itineraryId, Itinerary itinerary) async {
    print('vao function goItineraryUpdate');
    try {
      final Map<String, dynamic> body = {
        "title": itinerary.title,
        "description": itinerary.description,
        "price": itinerary.price,
        "address": cityTrip,
        "init_date": travelDays,
        "status": 1,
        "start_date": DateTime.now().toUtc().toIso8601String(),
        "updated_at": DateTime.now().toUtc().toIso8601String(),
        "locations": itinerary.locations.map((location) {
          return {
            "name": location.name,
            "day": location.day,
            "description": location.description,
            "image": location.image,
            "flag": location.flag ?? false,
            "time_start": location.timeStart.toUtc().toIso8601String(),
            "time_finish": location.timeFinish.toUtc().toIso8601String(),
            "time_reminder": location.timeReminder,
            "culture": location.culture,
            "recommended_time": location.recommendedTime,
            "price": location.price ?? "0.0",
            "activities": location.activities.map((activity) {
              return {
                "name": activity.name,
                "description": activity.description,
                "activities_possible": activity.activitiesPossible,
                "price": activity.price,
                "rule": activity.rule,
                "recommend": activity.recommend,
              };
            }).toList(),
          };
        }).toList(),
      };

      final response = await _apiService.request(
        path: '/itineraries/$itineraryId',
        method: 'PUT',
        typeUrl: 'baseUrl',
        currentPath: '',
        data: body,
      );

      if (response.statusCode == 200) {
        print("Itinerary updated successfully!");
        return true;
      } else {
        print("Failed to update itinerary: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error updating itinerary: $e");
      return false;
    }
  }

  Future<bool?> updateItinerary(int? itineraryId, Itinerary itinerary) async {
    print('Updating itinerary with ID: $itineraryId');
    try {
      final Map<String, dynamic> body = {
        "title": itinerary.title,
        "description": itinerary.description,
        "price": itinerary.price,
        "address": cityTrip,
        "init_date": travelDays,
        "start_date": itinerary.start_date?.toUtc().toIso8601String(),
        "updated_at": DateTime.now().toUtc().toIso8601String(),
        "locations": itinerary.locations.map((location) {
          return {
            "name": location.name,
            "day": location.day,
            "description": location.description,
            "image": location.image,
            "flag": location.flag ?? false,
            "time_start": location.timeStart.toUtc().toIso8601String(),
            "time_finish": location.timeFinish.toUtc().toIso8601String(),
            "time_reminder": location.timeReminder,
            "culture": location.culture,
            "recommended_time": location.recommendedTime,
            "price": location.price ?? "0.0",
            "activities": location.activities.map((activity) {
              return {
                "name": activity.name,
                "description": activity.description,
                "activities_possible": activity.activitiesPossible,
                "price": activity.price,
                "rule": activity.rule,
                "recommend": activity.recommend,
              };
            }).toList(),
          };
        }).toList(),
      };

      final response = await _apiService.request(
        path: '/itineraries/$itineraryId',
        method: 'PUT',
        typeUrl: 'baseUrl',
        currentPath: '',
        data: body,
      );

      if (response.statusCode == 200) {
        print("✅ Itinerary updated successfully!");
        return true;
      } else {
        print("❌ Failed to update itinerary: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Error updating itinerary: $e");
      return false;
    }
  }

  Future<bool?> finishItineraryUpdate(
      int? itineraryId, Itinerary itinerary) async {
    print('vao function goItineraryUpdate');
    try {
      final Map<String, dynamic> body = {
        "title": itinerary.title,
        "description": itinerary.description,
        "price": itinerary.price,
        "address": cityTrip,
        "init_date": travelDays,
        "status": 2,
        "start_date": DateTime.now().toUtc().toIso8601String(),
        "locations": itinerary.locations.map((location) {
          return {
            "name": location.name,
            "day": location.day,
            "description": location.description,
            "image": location.image,
            "flag": location.flag ?? false,
            "time_start": location.timeStart.toUtc().toIso8601String(),
            "time_finish": location.timeFinish.toUtc().toIso8601String(),
            "time_reminder": location.timeReminder,
            "culture": location.culture,
            "recommended_time": location.recommendedTime,
            "price": location.price ?? "0.0",
            "activities": location.activities.map((activity) {
              return {
                "name": activity.name,
                "description": activity.description,
                "activities_possible": activity.activitiesPossible,
                "price": activity.price,
                "rule": activity.rule,
                "recommend": activity.recommend,
              };
            }).toList(),
          };
        }).toList(),
      };

      final response = await _apiService.request(
        path: '/itineraries/$itineraryId',
        method: 'PUT',
        typeUrl: 'baseUrl',
        currentPath: '',
        data: body,
      );

      if (response.statusCode == 200) {
        print("Itinerary updated successfully!");
        return true;
      } else {
        print("Failed to update itinerary: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error updating itinerary: $e");
      return false;
    }
  }

  void checkItineraryStatus(Map<String, dynamic> itinerary) {
    DateTime updatedAt = DateTime.parse(itinerary['updated_at']);
    DateTime? startDate = itinerary['start_date'] != null
        ? DateTime.parse(itinerary['start_date'])
        : null;
    int initDate = itinerary['init_date'] ?? 0;

    if (startDate == null) {
      print("❌ Chưa có ngày bắt đầu.");
      return;
    }

    int daysPassed = updatedAt.difference(startDate).inDays;

    if (daysPassed >= initDate) {
      print("✅ Chuyến đi đã hoàn thành!");
    } else {
      print("📅 Đang ở ngày ${daysPassed + 1} của chuyến đi.");
    }
  }

  List<Map<String, dynamic>> getLocations(Map<String, dynamic> jsonData) {
    return (jsonData["data"] as List)
        .expand((itinerary) => itinerary["locations"] as List)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  List<String> getLocationNames(Map<String, dynamic> jsonData) {
    if (jsonData["data"] == null || jsonData["data"] is! List) {
      return [];
    }

    return (jsonData["data"] as List)
        .where((itinerary) =>
            itinerary["locations"] != null &&
            itinerary["locations"] is List) // Kiểm tra null
        .expand((itinerary) => itinerary["locations"] as List)
        .where((location) => location["name"] != null) // Kiểm tra null
        .map((location) => location["name"].toString()) // Chuyển thành String
        .toList();
  }
}
