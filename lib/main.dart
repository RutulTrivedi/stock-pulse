import 'package:flutter/material.dart';
import 'package:stock_pulse/components/sp_layout.dart';
import 'package:stock_pulse/pages/sp_home.dart';
import 'package:stock_pulse/pages/sp_stock.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'Nunito',
        useMaterial3: true,
        // Blue : #3A5A81
        primaryColor: Color.fromRGBO(58, 90, 129, 1),
        // Red : #D31336
        shadowColor: Color.fromRGBO(211, 19, 54, 1),
        // Black : #252131
        canvasColor: Color.fromRGBO(37, 33, 49, 1),
        //White
        focusColor: Colors.white
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      home: LayoutPage(),
      // home: StockPage({
      //   "symbol":"IBM",
      //   "name":"IBM"
      // }),
    );
  }
}