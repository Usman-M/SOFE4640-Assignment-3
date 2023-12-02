import 'package:flutter/material.dart';
import 'package:assign3_meal_planner/dbHelper.dart';
import 'package:intl/intl.dart';

class NewEntryScreen extends StatefulWidget {
  @override
  _NewEntryScreenState createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  late TextEditingController targetCaloriesController;
  List<Map<String, dynamic>> foodItems = [];
  List<FoodEntry> foodEntries = [];
  int? selectedFoodItemId;
  int? selectedDropdownItemId;
  int targetDailyCalories = 0;
  DateTime? selectedDate;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    targetCaloriesController = TextEditingController();
    _loadFoodItems();
  }

  Future<void> _loadFoodItems() async {
    final database = MealPlannerDatabase.instance;
    final db = await database.database;

    final List<Map<String, dynamic>> items = await db.query('items');

    setState(() {
      foodItems = items;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'No Date Selected';
    } else {
      return 'Selected Date: ${DateFormat('yyyy-MM-dd').format(date)}';
    }
  }

  void _addRow() {
    if (selectedFoodItemId == null && selectedDropdownItemId == null) {
      return;
    }

    int selectedItemId = selectedFoodItemId ?? selectedDropdownItemId!;

    final selectedFoodItem =
        foodItems.firstWhere((item) => item['id'] == selectedItemId);
    final int calories = selectedFoodItem['calories'] as int;

    setState(() {
      foodEntries
          .add(FoodEntry(foodItemId: selectedItemId, calories: calories));
      searchController.clear();
      selectedFoodItemId = null;
      selectedDropdownItemId = null;
    });
  }

  void _deleteRow(FoodEntry entry) {
    setState(() {
      foodEntries.remove(entry);
    });
  }

  void _saveEntryToDatabase() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must select a date.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (targetDailyCalories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must enter a valid target calories value.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (foodEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must add at least one food item.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (calculateTotalCalories() > targetDailyCalories) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Total calories cannot exceed the daily target.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final database = MealPlannerDatabase.instance;
    final db = await database.database;

    final totalCalories = calculateTotalCalories();

    final formattedDate =
        "${selectedDate!.year}-${selectedDate!.month}-${selectedDate!.day}";

    final foodItemIds = foodEntries.map((entry) => entry.foodItemId).toList();

    await database.dbInsertEntry(totalCalories, formattedDate, foodItemIds);

    setState(() {
      foodEntries.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved succesfully.'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  int calculateTotalCalories() {
    return foodEntries.fold(0, (sum, entry) => sum + entry.calories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Meal Plan'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      _selectDate(context);
                    },
                    child: Text('Select Date'),
                  ),
                  SizedBox(width: 10),
                  Text(
                    _formatDate(selectedDate),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                keyboardType: TextInputType.number,
                controller: targetCaloriesController,
                decoration: InputDecoration(
                  labelText: 'Target Calories',
                ),
                onChanged: (value) {
                  setState(() {
                    targetDailyCalories = int.tryParse(value) ?? 0;
                  });
                },
                validator: (value) {
                  if (targetDailyCalories <= 0) {
                    return 'Please enter a valid daily calories value.';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField<int>(
                value: selectedDropdownItemId,
                onChanged: (value) {
                  setState(() {
                    selectedDropdownItemId = value;
                  });
                },
                items: foodItems.map<DropdownMenuItem<int>>((item) {
                  return DropdownMenuItem<int>(
                    value: item['id'] as int,
                    child: Text(item['name'] as String),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Select Food Item',
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _addRow();
              },
              child: Text('Add Item'),
            ),
            SizedBox(height: 20),
            foodEntries.isEmpty
                ? Text('No Items Added')
                : DataTable(
                    columns: [
                      DataColumn(label: Text('Food Item')),
                      DataColumn(label: Text('Calories')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: foodEntries.map<DataRow>((FoodEntry entry) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              foodItems.firstWhere(
                                (item) => item['id'] == entry.foodItemId,
                                orElse: () => {'name': 'Unknown'},
                              )['name'] as String,
                            ),
                          ),
                          DataCell(
                            Text(
                              entry.calories.toString(),
                            ),
                          ),
                          DataCell(
                            TextButton(
                              onPressed: () {
                                _deleteRow(entry);
                              },
                              child: Text('Delete'),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
            SizedBox(height: 20),
            Text(
              'Total Calories: ${calculateTotalCalories()}',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _saveEntryToDatabase();
              },
              child: Text('Save Meal Plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class FoodEntry {
  final int foodItemId;
  final int calories;

  FoodEntry({required this.foodItemId, required this.calories});
}
