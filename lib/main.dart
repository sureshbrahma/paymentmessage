import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Payment Confirmation Status',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Payment Confirmation Status'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _billNoController = TextEditingController();
  final TextEditingController _billDateController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _getPaymentStatus() async {
    final String billNo = _billNoController.text;
    final String billDate = _billDateController.text;

    try {
      final response = await http.get(Uri.parse('http://192.168.73.220:88/api/payment'));

      if (response.statusCode == 200) {
        List<Map<String, String>> apiData = [];
        List<dynamic> jsonData = json.decode(response.body);

        for (var item in jsonData) {
          apiData.add({
            'billNo': item['BillNo'],
            'billDate': item['BillDate'],
            'amount': item['Amount'].toString(),
            'refNo': item['RefNo'],
            'dateOfPayment': item['DateOfPayment'],
            'department': item['Department'],
            'partyName': item['PartyName'],
            'mode': item['Mode'],
          });
        }

        final payment = apiData.firstWhere(
              (element) => element['billNo'] == billNo && element['billDate'] == billDate,
          orElse: () => {},
        );

        if (payment.isEmpty) {
          _showDialog('Your Bill Is in Processing');
        } else {
          _showRoleDialog(payment);
        }
      } else {
        print('Error: ${response.statusCode} ${response.body}');
        _showDialog('Failed to fetch payment status. Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
      _showDialog('Error fetching data: $e');
    }
  }

  Future<bool> _checkInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _billDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Status'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showRoleDialog(Map<String, String> data) {
    String formattedDateOfPayment = data['dateOfPayment'] != null
        ? DateFormat('dd-MM-yyyy').format(DateTime.parse(data['dateOfPayment']!))
        : 'N/A';
    String formattedBillDate = data['billDate'] != null
        ? DateFormat('dd-MM-yyyy').format(DateTime.parse(data['billDate']!))
        : 'N/A';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Role'),
          content: const Text('Are you a Department or Seller?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the role selection dialog
                _updateViewStatus(data['billNo']!, 'Seller');
                _showDialog(
                  'Om Shanti\nYour Payment for Rs. ${data['amount']} has been transferred to your account through ${data['mode']} Ref. No. ${data['refNo']} Dated $formattedDateOfPayment',
                );
              },
              child: const Text('Seller'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the role selection dialog
                _updateViewStatus(data['billNo']!, 'Department');
                _showDialog(
                  'Om Shanti\nDivine Brother, ${data['department']},\nPayment to ${data['partyName']} for Rs. ${data['amount']} has been transferred to their A/c Through ${data['mode']} Ref. No. ${data['refNo']} Dated $formattedDateOfPayment',
                );
              },
              child: const Text('Department'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateViewStatus(String billNo, String role) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.73.220:88/api/payment/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'billNo': billNo, 'role': role}),
      );

      if (response.statusCode == 200) {
        print('View status updated successfully for $role');
      } else {
        print('Failed to update view status. Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.deepOrangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/logo.png',
                    height: 100,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Confirmation Status',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _billNoController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Bill No',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _billDateController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Bill Date (yyyy-MM-dd)',
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            onTap: () async {
                              FocusScope.of(context).requestFocus(FocusNode());
                              await _selectDate(context);
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              final bool isConnected = await _checkInternetConnectivity();
                              if (isConnected) {
                                _getPaymentStatus();
                              } else {
                                _showDialog('No internet connection. Please check your network settings.');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent, // Change this to your desired color
                            ),
                            child: const Text('Get Payment Status'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
