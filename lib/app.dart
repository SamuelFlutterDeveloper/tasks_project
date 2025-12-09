import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks_project/pages/property/screen/propertiy_list_page.dart';
import 'package:tasks_project/provider/property_provider.dart';
import 'package:tasks_project/util/app_constant.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (ctx) => PropertyProvider())],
      child: MaterialApp(
        title: AppConstant.appName,
        debugShowCheckedModeBanner: false,
        home: PropertiyListPage(),
      ),
    );
  }
}
