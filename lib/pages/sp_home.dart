import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stock_pulse/pages/sp_stock.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _controllerOne;
  late Animation _animationOne;

  late AnimationController _controllerTwo;
  late Animation _animationTwo;

  late AnimationController _controllerThree;
  late Animation _animationThree;

  final String _textName = "Hey, Rutul";
  final String _textWelcome = "Welcome to Stock Pulse";

  TextEditingController _textSearch = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<dynamic, dynamic>> _news = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Controller for user name
    _controllerOne = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _animationOne = IntTween(begin: 0, end: _textName.length).animate(
      CurvedAnimation(parent: _controllerOne, curve: Curves.easeInOut),
    );

    _controllerOne.addListener(() {
      setState(() {});
    });
    _controllerOne.forward();

    // Controller for Welcome
    _controllerTwo = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _animationTwo = IntTween(begin: 0, end: _textWelcome.length).animate(
      CurvedAnimation(parent: _controllerTwo, curve: Curves.easeInOut),
    );

    _controllerTwo.addListener(() {
      setState(() {});
    });

    _controllerTwo.forward();

    // Hand wave controller
    _controllerThree = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _animationThree = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _controllerThree, curve: Curves.elasticIn),
    );

    _controllerThree.forward();

    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      _news = await _getNews();
      setState(() {});
    } catch (e) {
      print('$e');
    }
  }

  Future<List<Map<dynamic, dynamic>>> _getNews() async {
    final url = Uri.parse(
        'https://www.alphavantage.co/query?function=NEWS_SENTIMENT&tickers=&apikey=SU62IQLSOYFU53SU');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final newsList = data['feed'] as List<dynamic>;

      final filteredNews = newsList.where((item) {
        return item['banner_image'] != null && item['banner_image'].isNotEmpty;
      }).toList();

      return filteredNews.map((item) {
        return {
          'title': item['title'],
          'url': item['url'],
          'source': item['source'],
          'time_published': item['time_published'],
          'banner_image': item['banner_image'],
        };
      }).toList();
    } else {
      throw Exception('Failed to load news');
    }
  }

  Future<List<Map<String, String>>> _getSuggestions(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final url = Uri.parse(
        'https://www.alphavantage.co/query?function=SYMBOL_SEARCH&keywords=$query&apikey=SU62IQLSOYFU53SU');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final bestMatches = data['bestMatches'];
      if (bestMatches == null) {
        return [];
      }

      if (bestMatches is! List) {
        return [];
      }

      return (bestMatches as List).map((result) {
        return {
          'symbol': result['1. symbol'] as String? ?? '',
          'name': result['2. name'] as String? ?? '',
        };
      }).toList();
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  void _navigateToDetailsPage(Map<String, String> stockDetails) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockPage(stockDetails),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('$e');
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
              SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TypeAheadFormField<Map<String, String>>(
                        textFieldConfiguration: TextFieldConfiguration(
                          controller: _textSearch,
                          style: TextStyle(color: Theme.of(context).focusColor),
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: "Search Stock Here...",
                            hintStyle: TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 15.0, horizontal: 20.0),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30.0)),
                              borderSide:
                                  BorderSide(color: Colors.grey, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30.0)),
                              borderSide:
                                  BorderSide(color: Colors.grey, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30.0)),
                              borderSide:
                                  BorderSide(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                        suggestionsCallback: (pattern) async {
                          return await _getSuggestions(pattern);
                        },
                        itemBuilder: (context, suggestion) {
                          return ListTile(
                            title: Row(
                              children: [
                                Text(
                                  '${suggestion['symbol']} - ',
                                  style: TextStyle(
                                    color: Theme.of(context).focusColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${suggestion['name']}',
                                    style: TextStyle(
                                        color: Theme.of(context).focusColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        onSuggestionSelected: (suggestion) {
                          _textSearch.text = suggestion['symbol']!;
                          _navigateToDetailsPage(suggestion);
                        },
                        noItemsFoundBuilder: (context) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'No items found',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a stock symbol to search';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Row(
                        children: [
                          Text(
                            _textName.substring(0, _animationOne.value),
                            style: TextStyle(
                                fontSize: 45,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).focusColor),
                          ),
                          SizedBox(width: 10),
                          AnimatedBuilder(
                            animation: _animationThree,
                            child: Icon(
                              Icons.waving_hand_rounded,
                              size: 40,
                              color: Theme.of(context).focusColor,
                            ),
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_animationThree.value, 0),
                                child: child,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    _textWelcome.substring(0, _animationTwo.value),
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).focusColor),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Divider(color: Colors.white24),
              Text(
                'TOP MARKET INSIGHTS',
                style: TextStyle(
                    color: Theme.of(context).focusColor, fontSize: 18),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _news.length,
                  itemBuilder: (context, index) {
                    final newsItem = _news[index];
                    return Container(
                      padding: EdgeInsets.all(7),
                      margin: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).focusColor),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          newsItem['banner_image'] != null &&
                                  newsItem['banner_image'].isNotEmpty
                              ? Image.network(
                                  newsItem['banner_image'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  "assets/images/logo_named.png",
                                  width: 80,
                                  height: 80,
                                ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  newsItem['title'] ?? 'No title',
                                  style: TextStyle(
                                    color: Theme.of(context).focusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Source: ${newsItem['source'] ?? 'Unknown'}',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Divider(),
                                InkWell(
                                  onTap: () {
                                    _launchURL(newsItem['url'] ?? '');
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Click here for more details ',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      Icon(
                                        Icons.link,
                                        color: Colors.blue,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controllerOne.dispose();
    _controllerTwo.dispose();
    _controllerThree.dispose();
    super.dispose();
  }
}
