import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class MealPlannerDatabase {
  static final MealPlannerDatabase instance = MealPlannerDatabase._init();
  static Database? _database;

  MealPlannerDatabase._init();

  /// Getter for the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;

    /// Initialize the database if it's not already created
    _database = await _initDB('calorie_calculator.db');
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDB(String dbName) async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/$dbName';

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _dbCreate,
    );

    return db;
  }

  /// Create the necessary tables when the database is first created
  Future<void> _dbCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        calories INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tot_cals INTEGER,
        date TEXT,
        item_ids TEXT,
        FOREIGN KEY (item_ids) REFERENCES items(id)
      )
    ''');

    /// Insert initial food items into the 'items' table
    await _dbInsertInitialFoodItems(db);
  }

  /// Insert initial food items into the 'items' table
  Future<void> _dbInsertInitialFoodItems(Database db) async {
    final foodItems = [
      {'name': 'Spinach Salad', 'calories': 50},
      {'name': 'Grilled Chicken Wrap', 'calories': 300},
      {'name': 'Quinoa Bowl', 'calories': 220},
      {'name': 'Roasted Vegetable Medley', 'calories': 120},
      {'name': 'Mango Salsa', 'calories': 45},
      {'name': 'Black Bean Burger', 'calories': 250},
      {'name': 'Cucumber Roll', 'calories': 80},
      {'name': 'Mixed Berry Smoothie', 'calories': 150},
      {'name': 'Hummus and Pita', 'calories': 180},
      {'name': 'Stuffed Bell Peppers', 'calories': 160},
      {'name': 'Pesto Pasta', 'calories': 280},
      {'name': 'Greek Salad', 'calories': 180},
      {'name': 'Teriyaki Tofu Bowl', 'calories': 230},
      {'name': 'Chickpea Curry', 'calories': 200},
      {'name': 'Veggie Spring Rolls', 'calories': 120},
      {'name': 'Pineapple Fried Rice', 'calories': 280},
      {'name': 'Caprese Sandwich', 'calories': 320},
      {'name': 'Mixed Nut Trail Mix', 'calories': 200},
      {'name': 'Vegetarian Chili', 'calories': 180},
      {'name': 'Fruit Salad', 'calories': 70},
    ];

    for (final foodItem in foodItems) {
      await db.insert(
        'items',
        foodItem,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Insert a new entry into the 'records' table
  Future<int> dbInsertEntry(
      int totalCalories, String date, List<int> foodItemIds) async {
    final db = await database;
    final formattedDate = _dbFormatDate(date);
    return await db.insert('records', {
      'tot_cals': totalCalories,
      'date': formattedDate,
      'item_ids': foodItemIds.join(','),
    });
  }

  /// Delete an entry from the 'records' table
  Future<void> dbDeleteEntry(int entryId) async {
    final db = await database;
    await db.delete('records', where: 'id = ?', whereArgs: [entryId]);
  }

  /// Update an entry in the 'records' table
  Future<void> dbUpdateEntry(
    int entryId,
    int totalCalories,
    String date,
    List<int> foodItemIds,
  ) async {
    final db = await database;

    final formattedDate = _dbFormatDate(date);

    final updatedEntry = {
      'tot_cals': totalCalories,
      'date': formattedDate,
      'item_ids': foodItemIds.join(','),
    };

    await db.update(
      'records',
      updatedEntry,
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  /// Format a DateTime object into a string for the database
  Future<String> _dbFormatDateForDatabase(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    return formattedDate;
  }

  /// Retrieve all entries from the 'records' table
  Future<List<Map<String, dynamic>>> dbGetRecords() async {
    final db = await database;
    return await db.query('records');
  }

  /// Retrieve food items for a specific entry from the 'records' table
  Future<List<int>> dbGetFoodItemsForRecord(int entryId) async {
    final db = await database;
    final result =
        await db.query('records', where: 'id = ?', whereArgs: [entryId]);
    final foodItemIds = (result.isNotEmpty) ? result.first['item_ids'] : '';
    return (foodItemIds as String)
        .split(',')
        .map((id) => int.parse(id))
        .toList();
  }

  /// Retrieve food items by their IDs from the 'items' table
  Future<List<Map<String, dynamic>>> dbGetFoodItemsByIds(
      List<int> foodItemIds) async {
    final db = await database;
    final inClause = foodItemIds.map((id) => '?').join(',');
    return await db.rawQuery(
        'SELECT * FROM items WHERE id IN ($inClause)', foodItemIds);
  }

  /// Retrieve a specific entry by its ID from the 'records' table
  Future<Map<String, dynamic>> dbGetEntryById(int entryId) async {
    final db = await database;
    final result =
        await db.query('records', where: 'id = ?', whereArgs: [entryId]);

    return result.isNotEmpty ? result.first : {};
  }

  /// Format a string date from the database into a standard format
  String _dbFormatDate(String rawDate) {
    final dateComponents = rawDate.split("-");
    final year = dateComponents[0];
    final month = dateComponents[1].padLeft(2, '0');
    final day = dateComponents[2].padLeft(2, '0');
    return '$year-$month-$day';
  }
}
