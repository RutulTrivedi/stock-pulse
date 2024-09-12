import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StockPage extends StatefulWidget {
  final Map<String, String> stockDetails;

  const StockPage(this.stockDetails);

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  List<ChartData> _chartData = [];
  bool _isLoading = true;
  double? _openingPrice;
  double? _closingPrice;
  double? _lowestPrice;
  double? _highestPrice;
  String _selectedPeriod = '7d'; // Default to last 7 days

  @override
  void initState() {
    super.initState();
    _fetchStockData();
  }

  Future<void> _fetchStockData() async {
    final String symbol = widget.stockDetails['symbol']!;
    final url = Uri.parse(
        'https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=$symbol&apikey=YTCTRCCNNNYSNXTP');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final Map<String, dynamic> timeSeries =
          data['Time Series (Daily)'] as Map<String, dynamic>;

      final List<ChartData> loadedData = [];
      double? previousClose;

      _openingPrice = null;
      _closingPrice = null;
      _lowestPrice = null;
      _highestPrice = null;

      // Filter the data based on the selected period
      final filteredEntries = timeSeries.entries
          .toList()
          .take(_getNumberOfDaysFromSelection(_selectedPeriod));

      // Flag to skip the first entry for correct comparison
      bool isFirstEntry = true;

      for (var entry in filteredEntries) {
        final dateTime = DateTime.parse(entry.key);
        final closePrice =
            double.parse(entry.value['4. close']) * 83; // Convert to INR
        final openPrice =
            double.parse(entry.value['1. open']) * 83; // Convert to INR
        final lowPrice =
            double.parse(entry.value['3. low']) * 83; // Convert to INR
        final highPrice =
            double.parse(entry.value['2. high']) * 83; // Convert to INR

        Color color;

        if (isFirstEntry) {
          // Skip color comparison for the first entry
          color = Colors.green; // Default color for the first entry
          isFirstEntry = false;
        } else {
          // Correct color logic based on the comparison with the previous close
          color = closePrice >= previousClose! ? Colors.red : Colors.green;
        }

        loadedData.add(ChartData(dateTime, closePrice, color));
        previousClose = closePrice;

        // Set opening, highest, and lowest prices based on data
        if (_openingPrice == null) {
          _openingPrice = openPrice;
        }
        _lowestPrice = (_lowestPrice == null || lowPrice < _lowestPrice!)
            ? lowPrice
            : _lowestPrice;
        _highestPrice = (_highestPrice == null || highPrice > _highestPrice!)
            ? highPrice
            : _highestPrice;
      }

      _closingPrice = loadedData.isNotEmpty ? loadedData.last.closePrice : null;

      setState(() {
        _chartData = loadedData.reversed.toList();
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load stock data');
    }
  }

  int _getNumberOfDaysFromSelection(String selection) {
    switch (selection) {
      case '7d':
        return 7;
      case '15d':
        return 15;
      case '30d':
        return 30;
      default:
        return 7;
    }
  }

  String _getPeriodFromSelection(String selection) {
    switch (selection) {
      case '7d':
        return '7days';
      case '15d':
        return '15days';
      case '30d':
        return '30days';
      default: // '7d'
        return '7days';
    }
  }

  Future<void> _addToWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? existingWatchlist = prefs.getStringList('watchlist');
    final List<Map<String, String>> watchlist = existingWatchlist != null
        ? existingWatchlist
            .map((jsonString) => json.decode(jsonString))
            .toList()
            .cast<Map<String, String>>()
        : [];

    final stockData = {
      'symbol': widget.stockDetails['symbol']!,
      'name': widget.stockDetails['name']!,
    };

    // Add the stock to the watchlist
    watchlist.add(stockData);

    // Save the updated watchlist
    await prefs.setStringList(
      'watchlist',
      watchlist.map((data) => json.encode(data)).toList(),
    );

    print(prefs.getStringList('watchlist').toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.stockDetails['name']} added to watchlist'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
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
                    '${widget.stockDetails['name']}',
                    style: TextStyle(
                        color: Theme.of(context).focusColor, fontSize: 18),
                  ),
                  SizedBox(height: 20),
                  _buildPeriodDropdown(),
                  SizedBox(height: 20),
                  _isLoading
                      ? CircularProgressIndicator()
                      : Container(
                          height: MediaQuery.of(context).size.height *
                              0.4, // Reduced size
                          child: SfCartesianChart(
                            primaryXAxis: DateTimeAxis(
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                            primaryYAxis: NumericAxis(
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                            series: _buildSeries(),
                          ),
                        ),
                  SizedBox(height: 20),
                  if (!_isLoading) ...[
                    Text(
                      'Stock Details',
                      style: TextStyle(
                          color: Theme.of(context).focusColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildStockDetailsColumn1()),
                        SizedBox(width: 10),
                        Expanded(child: _buildStockDetailsColumn2()),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Overall Change: ${_calculateOverallChange()}%',
                      style: TextStyle(
                        color: _calculateChangeColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Spacer(), // Pushes the button to the bottom
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addToWatchlist,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 10), // Reduced size
                ),
                child: Text('Add to Watchlist'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return DropdownButton<String>(
      value: _selectedPeriod,
      dropdownColor: Colors.black,
      items: ['7d', '15d', '30d'].map((String period) {
        return DropdownMenuItem<String>(
          value: period,
          child: Text(
            _formatPeriod(period),
            style: TextStyle(color: Colors.white), // Set text color to white
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedPeriod = newValue!;
          _isLoading = true;
        });
        _fetchStockData(); // Fetch the stock data for the new period
      },
    );
  }

  String _formatPeriod(String period) {
    switch (period) {
      case '7d':
        return 'Last 7 Days';
      case '15d':
        return 'Last 15 Days';
      case '30d':
        return 'Last 30 Days';
      default:
        return 'Unknown';
    }
  }

  List<LineSeries<ChartData, DateTime>> _buildSeries() {
    return [
      LineSeries<ChartData, DateTime>(
        dataSource: _chartData,
        xValueMapper: (ChartData data, _) => data.dateTime,
        yValueMapper: (ChartData data, _) => data.closePrice,
        pointColorMapper: (ChartData data, _) => data.color,
        width: 2,
      )
    ];
  }

  Widget _buildStockDetailsColumn1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opening Price: ₹${_openingPrice?.toStringAsFixed(2) ?? 'N/A'}',
          style: TextStyle(color: Colors.white),
        ),
        Text(
          'Closing Price: ₹${_closingPrice?.toStringAsFixed(2) ?? 'N/A'}',
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildStockDetailsColumn2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lowest Price: ₹${_lowestPrice?.toStringAsFixed(2) ?? 'N/A'}',
          style: TextStyle(color: Colors.white),
        ),
        Text(
          'Highest Price: ₹${_highestPrice?.toStringAsFixed(2) ?? 'N/A'}',
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  String _calculateOverallChange() {
    if (_closingPrice != null && _openingPrice != null) {
      final overallChange =
          ((_closingPrice! - _openingPrice!) / _openingPrice!) * 100;
      return overallChange.toStringAsFixed(2);
    }
    return '0.00';
  }

  Color _calculateChangeColor() {
    final overallChange = _closingPrice != null && _openingPrice != null
        ? ((_closingPrice! - _openingPrice!) / _openingPrice!) * 100
        : 0.0;
    return overallChange >= 0 ? Colors.green : Colors.red;
  }
}

class ChartData {
  final DateTime dateTime;
  final double closePrice;
  final Color color;

  ChartData(this.dateTime, this.closePrice, this.color);
}
