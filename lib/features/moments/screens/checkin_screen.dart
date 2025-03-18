import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CheckinScreen extends StatefulWidget {
  @override
  _MapTilerStaticMapState createState() => _MapTilerStaticMapState();
}

class _MapTilerStaticMapState extends State<CheckinScreen> {
  TextEditingController searchController = TextEditingController();
  String? staticMapUrl;
  String apiKey = "w5zq0nAcaPwQSbl1tW0V"; // Thay bằng API Key của bạn

  Future<void> _fetchStaticMap() async {
    String address = searchController.text;
    if (address.isEmpty) return;

    // Gọi API Nominatim để lấy tọa độ
    String url =
        "https://nominatim.openstreetmap.org/search?q=$address&format=json";

    final response = await http.get(Uri.parse(url), headers: {
      "User-Agent": "lokaloka (lokaloka@gmail.com)" // User-Agent hợp lệ
    });

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      if (data.isNotEmpty) {
        double lat = double.parse(data[0]["lat"]);
        double lon = double.parse(data[0]["lon"]);

        String url = 'https://api.maptiler.com/maps/streets/static/$lon,$lat,15/650x450.png?key=$apiKey';
        // Tạo URL ảnh tĩnh MapTiler
        final mapUrl =await http.get(Uri.parse(url), headers: {
          "User-Agent": "lokaloka (lokaloka@gmail.com)"
        });

        setState(() {
          staticMapUrl = mapUrl.body;
          print(mapUrl.body);
        print(staticMapUrl);
        });
      } else {
        setState(() {
          staticMapUrl = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không tìm thấy địa điểm!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bản đồ MapTiler")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Nhập địa chỉ...",
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _fetchStaticMap,
                ),
              ),
            ),
            SizedBox(height: 20),
            staticMapUrl != null
                ? Image.network(staticMapUrl!)
                : Text("Nhập địa chỉ để hiển thị bản đồ"),
          ],
        ),
      ),
    );
  }
}
