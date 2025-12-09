import 'package:flutter/material.dart';
import 'package:tasks_project/app.dart';
import 'package:tasks_project/config/app_intialize.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

 

  await AppInitialize.start();
  

  runApp(const MyApp());
}
