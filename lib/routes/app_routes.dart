import 'package:flutter/material.dart';
import 'package:lokaloka/features/friend/screens/friends_screen.dart';
import 'package:lokaloka/features/moments/screens/checkin_screen.dart';
import 'package:lokaloka/features/moments/screens/moment_screen.dart';
import 'package:lokaloka/features/notification/screens/notification_screen.dart';
import 'package:lokaloka/features/profile/screens/profile_screen.dart';
import 'package:lokaloka/features/auth/screens/sign_up_screen.dart';
import 'package:lokaloka/features/itinerary/screens/my_trip_screen.dart';
import '../core/constants/routes_constant.dart';
import '../features/auth/screens/intro_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/itinerary/screens/create_itinerary_screen.dart';
import '../features/navigation/screens/map_screen.dart';
import '../features/weather/screens/weather_screen.dart';

final router = RoutesConstant();

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
            builder: (_) => IntroScreen(), settings: settings);
      case '/home':
        return MaterialPageRoute(
            builder: (_) => HomeScreen(), settings: settings);
      case '/sign-up':
        return MaterialPageRoute(
            builder: (_) => SignUpScreen(), settings: settings);
      case '/login':
        return MaterialPageRoute(builder: (_) => Login(), settings: settings);
      case '/map':
        return MaterialPageRoute(
            builder: (_) => MapScreen(), settings: settings);
      case '/my-trip':
        return MaterialPageRoute(
            builder: (_) => MyTripScreen(), settings: settings);
      case '/create-itinerary':
        return MaterialPageRoute(
            builder: (_) => CreateItinerary(), settings: settings);
      case '/profile':
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      // return MaterialPageRoute(builder: (_) => ProfileScreen(), settings: settings);
      case '/weather':
        return MaterialPageRoute(
            builder: (_) => WeatherScreen(), settings: settings);
      case '/trust-phone':
        return MaterialPageRoute(
            builder: (_) => WeatherScreen(), settings: settings);
      case '/moment':
        return MaterialPageRoute(builder: (_) => MomentsScreen());
      case '/friend':
        return MaterialPageRoute(builder: (_) => FriendsScreen());
      case '/notification':
        return MaterialPageRoute(builder: (_) => NotificationScreen());
      case '/checkin':
        return MaterialPageRoute(builder: (_) => CheckinScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Không tìm thấy trang: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
