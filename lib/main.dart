import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // The product is portrait-first: guests hold the phone up to scan a QR code
  // and take a selfie, organisers work one-handed at a venue.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const FaceDeliverApp());
}
