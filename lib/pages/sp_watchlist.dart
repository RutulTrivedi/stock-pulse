import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_pulse/pages/sp_stock.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WatchListPage extends StatefulWidget {
  const WatchListPage({super.key});

  @override
  State<WatchListPage> createState() => _WatchListPageState();
}

class _WatchListPageState extends State<WatchListPage> {
  List<Map<String, String>> _watchList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _loadWatchList();
  }

  Future<void> _loadWatchList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? watchListData = prefs.getStringList('watchlist');

      final List<Map<String, String>> watchList = watchListData != null
          ? watchListData.map((item) => Map<String, String>.from(json.decode(item) as Map)).toList()
          : [];

      setState(() {
        _watchList = watchList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading watchlist: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _removeFromWatchList(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _watchList.removeAt(index);
      });
      final String updatedWatchList = json.encode(_watchList);
      await prefs.setStringList(
          'watchlist', _watchList.map((data) => json.encode(data)).toList());
    } catch (e) {
      print('Error removing from watchlist: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    "assets/images/logo_bgless.png",
                    width: 50,
                    height: 50,
                  ),
                  SizedBox(width: 15),
                  Text(
                    'Stock Pulse',
                    style: TextStyle(
                        fontSize: 35, color: Theme.of(context).focusColor),
                  ),
                ],
              ),
              Divider(),
              Text(
                "MY WATCHLIST",
                style: TextStyle(
                    color: Theme.of(context).focusColor, fontSize: 18),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : _watchList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.hourglass_empty,
                                    color: Theme.of(context).focusColor,
                                    size: 30),
                                SizedBox(height: 15),
                                Text(
                                  "Your watchlist is empty",
                                  style: TextStyle(
                                      color: Theme.of(context).focusColor),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _watchList.length,
                            itemBuilder: (context, index) {
                              final stock = _watchList[index];
                              return Dismissible(
                                key: Key(stock['symbol']!),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) {
                                  _removeFromWatchList(index);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          "${stock['name']} removed from watchlist"),
                                    ),
                                  );
                                },
                                background: Container(
                                  color: Colors.red,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(15.0),
                                      child: Icon(Icons.delete,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(stock['name']!,style: TextStyle(color: Theme.of(context).focusColor),),
                                  subtitle: Text(stock['symbol']!,style: TextStyle(color: Theme.of(context).focusColor)),
                                  onTap: () async {
                                    final symbol = stock['symbol'];
                                    final url = Uri.parse(
                                        'https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=$symbol&apikey=YTCTRCCNNNYSNXTP');

                                    final response = await http.get(url);

                                    if (response.statusCode == 200) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StockPage(jsonDecode(response.body)),
                                        ),
                                      );
                                    } else {
                                      throw Exception(
                                          'Failed to load stock data');
                                    }

                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
