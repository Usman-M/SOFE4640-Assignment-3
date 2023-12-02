import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:assign3_meal_planner/new.dart';
import 'package:assign3_meal_planner/dbHelper.dart';
import 'package:assign3_meal_planner/update.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home',
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.grey,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: Colors.black,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
        ),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late List<Map<String, dynamic>> entries = [];
  DateTime? selectedFilterDate;

  @override
  void initState() {
    super.initState();
    _loadMealRecords();
  }

  /// Load meal records from the database
  Future<void> _loadMealRecords() async {
    final database = MealPlannerDatabase.instance;
    final List<Map<String, dynamic>> records = await database.dbGetRecords();

    setState(() {
      entries = records;
    });
  }

  /// Refresh the UI by reloading meal records
  Future<void> _refresh() async {
    await _loadMealRecords();
  }

  /// Filter meal records based on selected date
  Future<void> _filterByDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedFilterDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        selectedFilterDate = picked;
      });
    }
  }

  /// Clear the date filter
  void _clearFilter() {
    setState(() {
      selectedFilterDate = null;
    });
  }

  /// Get filtered meal records based on the selected date
  List<Map<String, dynamic>> getFilteredRecords() {
    if (selectedFilterDate == null) {
      return entries;
    } else {
      return entries
          .where((record) =>
              DateTime.parse(record['date'].toString())
                  .isAtSameMomentAs(selectedFilterDate!) ||
              DateTime.parse(record['date'].toString()).isAfter(DateTime(
                    selectedFilterDate!.year,
                    selectedFilterDate!.month,
                    selectedFilterDate!.day,
                  )) &&
                  DateTime.parse(record['date'].toString()).isBefore(DateTime(
                    selectedFilterDate!.year,
                    selectedFilterDate!.month,
                    selectedFilterDate!.day + 1,
                  )))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Calories Calculator'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: entries.isEmpty
                    ? Center(
                        child: Text(
                          'No entries in the database',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : DataTable(
                        columns: [
                          DataColumn(label: Text('Actions')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Items')),
                          DataColumn(label: Text('Total Calories')),
                        ],
                        rows: getFilteredRecords().map<DataRow>((record) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => UpdateScreen(
                                              entryId: record['id'],
                                            ),
                                          ),
                                        );
                                        await _refresh();
                                      },
                                      child: Text('Edit'),
                                    ),
                                    SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        /// Show a confirmation dialog
                                        bool confirmDelete = await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Delete'),
                                            content: Text(
                                                'Confirm to delete this row'),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(false);
                                                },
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(true);
                                                },
                                                child: Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );

                                        /// If the user confirms, delete the entry
                                        if (confirmDelete == true) {
                                          await MealPlannerDatabase.instance
                                              .dbDeleteEntry(record['id']);
                                          await _refresh();
                                        }
                                      },
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(DateFormat('yyyy-MM-dd').format(
                                  DateTime.parse(record['date'].toString()),
                                )),
                              ),
                              DataCell(
                                FutureBuilder<List<String>>(
                                  future: _getFoodItems(record['id']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      return Text('Error loading food items');
                                    } else {
                                      final foodItems = snapshot.data ?? [];
                                      return Text(foodItems.join(', '));
                                    }
                                  },
                                ),
                              ),
                              DataCell(
                                Text(record['tot_cals'].toString()),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Container(
            alignment: Alignment.bottomRight,
            padding: EdgeInsets.only(right: 16, bottom: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: _filterByDate,
                      child: Text('Query Date'),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _clearFilter,
                      child: Text('Clear Query'),
                    ),
                    SizedBox(width: 10),
                    Text(
                      selectedFilterDate == null
                          ? 'No Date Query Entered'
                          : 'Filter Date: ${DateFormat('yyyy-MM-dd').format(selectedFilterDate!)}',
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  alignment: Alignment.bottomRight,
                  padding: EdgeInsets.only(right: 16, bottom: 16),
                  child: FloatingActionButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewEntryScreen(),
                        ),
                      );
                      await _refresh();
                    },
                    child: Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get food items for a specific meal record
  Future<List<String>> _getFoodItems(int mealId) async {
    final database = MealPlannerDatabase.instance;
    final List<int> foodItemIds =
        await database.dbGetFoodItemsForRecord(mealId);
    final List<Map<String, dynamic>> foodItems =
        await database.dbGetFoodItemsByIds(foodItemIds);

    return foodItems.map((item) => item['name'].toString()).toList();
  }
}
