// Haveno App extends the features of Haveno, supporting mobile devices and more.
// Copyright (C) 2024 Kewbit (https://kewbit.org)
// Source Code: https://git.haveno.com/haveno/haveno-app.git
//
// Author: Kewbit
//    Website: https://kewbit.org
//    Contact Email: me@kewbit.org
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.


import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:haveno/grpc_models.dart';
import 'package:haveno/profobuf_models.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  // Private constructor
  DatabaseHelper._privateConstructor();

  // Single instance of DatabaseHelper
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  static bool _isResetting = false;

  // Initialize the sqflite ffi loader
  Future<void> _initFfiLoader() async {
    sqfliteFfiInit(); // Initialize FFI loader
  }

  Future<Database?> get database async {
    if (_isResetting) {
      return null;
    }

    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database with FFI support
  Future<Database> _initDatabase() async {
    await _initFfiLoader(); // Initialize FFI

    // Get application directory for cross-platform support
    final io.Directory appDocumentsDir = await getApplicationSupportDirectory();

    // Define the database path
    final String databasePath =
        path.join(appDocumentsDir.path, 'databases', 'haveno.db');

    // Use the FFI database factory
    var databaseFactory = databaseFactoryFfi;

    return await databaseFactory.openDatabase(databasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('PRAGMA foreign_keys = ON');
            // Create trades table
            await db.execute('''
                CREATE TABLE IF NOT EXISTS trades(
                  tradeId TEXT PRIMARY KEY,
                  data TEXT
                )
              ''');

            // Create disputes table
            await db.execute('''
                CREATE TABLE IF NOT EXISTS disputes(
                  disputeId TEXT PRIMARY KEY,
                  tradeId TEXT UNIQUE,
                  data TEXT,
                  FOREIGN KEY(tradeId) REFERENCES trades(tradeId) ON DELETE CASCADE
                )
              ''');

            // Create trade_chat_messages table
            await db.execute('''
                CREATE TABLE IF NOT EXISTS trade_chat_messages(
                  messageId TEXT PRIMARY KEY,
                  tradeId TEXT,
                  data TEXT,
                  FOREIGN KEY(tradeId) REFERENCES trades(tradeId) ON DELETE CASCADE
                )
              ''');

            // Create dispute_chat_messages table
            await db.execute('''
                CREATE TABLE IF NOT EXISTS dispute_chat_messages(
                  messageId TEXT PRIMARY KEY,
                  disputeId TEXT,
                  data TEXT,
                  FOREIGN KEY(disputeId) REFERENCES disputes(disputeId) ON DELETE CASCADE
                )
              ''');

            // Create payment_methods table
            await db.execute('''
                CREATE TABLE IF NOT EXISTS payment_methods(
                  paymentMethodId TEXT PRIMARY KEY,
                  data TEXT
                )
              ''');

            // Create payment_accounts table
            await db.execute('''
                CREATE TABLE IF NOT EXISTS payment_accounts(
                  paymentAccountId TEXT PRIMARY KEY,
                  paymentMethodId TEXT,
                  accountName TEXT,
                  creationDate INT,
                  data TEXT,
                  FOREIGN KEY(paymentMethodId) REFERENCES payment_methods(paymentMethodId) ON DELETE CASCADE
                )
              ''');

            // Create payment_account_forms table
            await db.execute('''
                CREATE TABLE IF NOT EXISTS payment_account_forms(
                  paymentAccountFormId TEXT PRIMARY KEY,
                  paymentMethodId TEXT UNIQUE,
                  data TEXT
                )
              ''');

            // Create trade_statistics table
            await db.execute('''
                CREATE TABLE IF NOT EXISTS trade_statistics(
                  hash BLOB PRIMARY KEY,
                  hashcode INTEGER,
                  amount INTEGER,
                  paymentMethodId TEXT,
                  date INTEGER,
                  arbitrator TEXT,
                  price INTEGER,
                  currency TEXT,
                  makerDepositTxnId TEXT,
                  takerDepositTxnId TEXT,
                  extraData TEXT,
                  data TEXT
                )
              ''');

            await db.execute('''
                CREATE TABLE IF NOT EXISTS offers(
                  offerId TEXT PRIMARY KEY,
                  paymentMethodId TEXT,
                  direction TEXT,
                  isMyOffer INTEGER,
                  ownerNodeAddress TEXT,
                  baseCurrencyCode TEXT,
                  counterCurrencyCode TEXT,
                  date INTEGER,
                  data TEXT,
                  hashcode INTEGER
                )
              ''');
            print("It's run the db init script");
            // Create indexes for tradeId and disputeId
            await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_tradeId ON trade_chat_messages(tradeId)');
            await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_disputeId ON dispute_chat_messages(disputeId)');
          },
        ));
  }

  // Close the database
  Future<void> closeDatabase() async {
    final db = await instance.database;
    if (db!.isOpen) {
      await db.close();
    }
  }

  Future<void> destroyDatabase({bool reinitialize = true}) async {
    try {
      final db = await instance.database;

      // Set the reset flag and initialize the completer if needed
      _isResetting = true;

      // Close and delete the database
      final databasePath = await getApplicationSupportDirectory();
      final databaseFilePath = path.join(databasePath.path, 'haveno.db');

      if (db!.isOpen) {
        print("Closing database...");
        await db.close();
        print("Database closed.");
      }

      print("Deleting database file...");
      await deleteDatabase(databaseFilePath);
      print("Database file deleted.");

      // Nullify the current instance of the database
      _database = null;

      // Delay to ensure file deletion is completed
      await Future.delayed(const Duration(milliseconds: 500));

      // Optionally reinitialize the database
      if (reinitialize) {
        print("Reinitializing the database...");
        _database = await _initDatabase();
        print("Database reinitialized.");
      }
    } catch (e) {
      print("Error during database destruction: $e");
    } finally {
      // Mark the database as reset and complete the completer
      _isResetting = false;
    }
  }

  // Insert a trade into the database
  Future<void> insertTrade(TradeInfo trade) async {
    final db = await instance.database;
    final tradeJson = jsonEncode(trade.toProto3Json());
    await db!.insert(
      'trades',
      {
        'tradeId': trade.tradeId,
        'data': tradeJson,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertTrades(List<TradeInfo> trades) async {
    final db = await instance.database;
    final batch = db!.batch();

    for (var trade in trades) {
      final tradeJson = jsonEncode(trade.toProto3Json());

      batch.insert(
        'trades',
        {
          'tradeId': trade.tradeId, // string
          'data': tradeJson, // json string of proto3 object
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Commit the batch
    await batch.commit(noResult: true);
  }

  // Insert a trade chat message into the database
  Future<void> insertTradeChatMessage(
      ChatMessage message, String tradeId) async {
    final db = await instance.database;
    final messageJson = jsonEncode(message.toProto3Json());
    await db!.insert(
      'trade_chat_messages',
      {
        'messageId': message.uid,
        'tradeId': tradeId,
        'data': messageJson,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert a dispute into the database
  Future<void> insertDispute(Dispute dispute) async {
    final db = await instance.database;
    final disputeJson = jsonEncode(dispute.toProto3Json());
    await db!.insert(
      'disputes',
      {
        'disputeId': dispute.id,
        'tradeId': dispute.tradeId,
        'data': disputeJson,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert a dispute chat message into the database
  Future<void> insertDisputeChatMessage(
      ChatMessage message, String disputeId) async {
    final db = await instance.database;
    final messageJson = jsonEncode(message.toProto3Json());
    await db!.insert(
      'dispute_chat_messages',
      {
        'messageId': message.uid,
        'disputeId': disputeId,
        'data': messageJson,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert a payment method into the database
  Future<void> insertPaymentMethod(PaymentMethod paymentMethod) async {
    final db = await instance.database;
    final paymentMethodJson = jsonEncode(paymentMethod.toProto3Json());
    await db!.insert(
      'payment_methods',
      {
        'paymentMethodId': paymentMethod.id,
        'data': paymentMethodJson,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Batch insert payment methods
  Future<void> insertPaymentMethods(List<PaymentMethod> paymentMethods) async {
    final db = await instance.database;
    final batch = db!.batch();

    for (var paymentMethod in paymentMethods) {
      final paymentMethodJson = jsonEncode(paymentMethod.toProto3Json());

      batch.insert(
        'payment_methods',
        {
          'paymentMethodId': paymentMethod.id, // string
          'data': paymentMethodJson, // json string of proto3 object
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Commit the batch
    await batch.commit(noResult: true);
  }

  Future<void> insertOffer(OfferInfo offer) async {
    final db = await instance.database;
    final offerJson = jsonEncode(offer.toProto3Json());
    await db!.insert(
      'offers',
      {
        'offerId': offer.id,
        'paymentMethodId': offer.paymentMethodId,
        'direction': offer.direction,
        'ownerNodeAddress': offer.ownerNodeAddress,
        'baseCurrencyCode': offer.baseCurrencyCode,
        'counterCurrencyCode': offer.counterCurrencyCode,
        'isMyOffer': offer.isMyOffer ? 1 : 0,
        'date': offer.date.toInt(),
        'data': offerJson,
        'hashcode': offer
            .hashCode // should store this canse then we know if the object changed or not
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Batch insert payment accounts
  Future<void> insertOffers(List<OfferInfo> offers) async {
    final db = await instance.database;
    final batch = db!.batch();

    for (var offer in offers) {
      final offerJson = jsonEncode(offer.toProto3Json());

      batch.insert(
        'offers',
        {
          'offerId': offer.id,
          'paymentMethodId': offer.paymentMethodId,
          'direction': offer.direction,
          'ownerNodeAddress': offer.ownerNodeAddress,
          'baseCurrencyCode': offer.baseCurrencyCode,
          'counterCurrencyCode': offer.counterCurrencyCode,
          'isMyOffer': offer.isMyOffer ? 1 : 0,
          'date': offer.date.toInt(),
          'data': offerJson,
          'hashcode': offer.hashCode
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Commit the batch
    await batch.commit(noResult: true);
  }

  Future<void> insertPaymentAccount(PaymentAccount paymentAccount) async {
    final db = await instance.database;
    final paymentAccountJson = jsonEncode(paymentAccount.toProto3Json());
    await db!.insert(
      'payment_accounts',
      {
        'paymentAccountId': paymentAccount.id,
        'paymentMethodId': paymentAccount.paymentMethod.id, //string
        'accountName': paymentAccount.accountName,
        'creationDate':
            paymentAccount.creationDate.toInt(), //int64 but convtered to int
        'data': paymentAccountJson, //json string of proto3 object
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Batch insert payment accounts
  Future<void> insertPaymentAccounts(
      List<PaymentAccount> paymentAccounts) async {
    final db = await instance.database;
    final batch = db!.batch();

    for (var paymentAccount in paymentAccounts) {
      final paymentAccountJson = jsonEncode(paymentAccount.toProto3Json());

      batch.insert(
        'payment_accounts',
        {
          'paymentAccountId': paymentAccount.id,
          'paymentMethodId': paymentAccount.paymentMethod.id, // string
          'accountName': paymentAccount.accountName,
          'creationDate':
              paymentAccount.creationDate.toInt(), // int64 but converted to int
          'data': paymentAccountJson, // json string of proto3 object
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Commit the batch
    await batch.commit(noResult: true);
  }

  // Insert trade statistic
  Future<void> insertTradeStatistic(TradeStatistics3 tradeStatistic) async {
    final db = await instance.database;
    final tradeStatisticJson = jsonEncode(tradeStatistic.toProto3Json());
    await db!.insert(
      'trade_statistics',
      {
        'hashcode': tradeStatistic.hashCode, //int
        'hash': tradeStatistic.hash, //list<int>
        'amount': tradeStatistic.amount.toInt(), //int64 but converted to int
        'paymentMethodId': tradeStatistic.paymentMethod, //string
        'date': tradeStatistic.date.toInt(), //int64 but convtered to int
        'arbitrator': tradeStatistic.arbitrator, //string
        'price': tradeStatistic.price.toInt(), //int64 but converted to int
        'currency': tradeStatistic.currency, //string
        'makerDepositTxnId': tradeStatistic.makerDepositTxId, //string
        'takerDepositTxnId': tradeStatistic.takerDepositTxId, //string
        'extraData': jsonEncode(tradeStatistic
            .extraData), //Map<String, String> but json encoded to stirng...
        'data': tradeStatisticJson, //json string of proto3 object
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get trade statistic groups by a specific peroid
  Future<List<TradeStatistics3>> getTradeStatistics(String? period) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query('trade_statistics');

    // Convert the list of maps to a list of PaymentMethod objects
    List<TradeStatistics3> tradeStatistics = maps.map((map) {
      final String tradeStatisticsJson = map['data'];
      return TradeStatistics3.create()
        ..mergeFromProto3Json(jsonDecode(tradeStatisticsJson));
    }).toList();

    //print("Found ${tradeStatistics.length} trade statistics entries in the database.");

    return tradeStatistics;
  }

  // Batch delete offers by id or isMyOffer
  Future<void> deleteOffers(List<OfferInfo>? offers, {bool? isMyOffer}) async {
    final db = await instance.database;
    final batch = db!.batch();

    if (offers != null && offers.isNotEmpty) {
      // Delete by offer id for the provided offers list
      for (var offer in offers) {
        batch.delete(
          'offers',
          where: 'offerId = ?',
          whereArgs: [offer.id],
        );
      }
    } else if (isMyOffer != null) {
      // Delete by isMyOffer flag if offers are not provided
      batch.delete(
        'offers',
        where: 'isMyOffer = ?',
        whereArgs: [isMyOffer ? 1 : 0], // 1 for true, 0 for false
      );
    }

    // Commit the batch
    await batch.commit(noResult: true);
  }

  // Get all payment methods
  Future<List<PaymentMethod>> getAllPaymentMethods() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query('payment_methods');

    // Convert the list of maps to a list of PaymentMethod objects
    List<PaymentMethod> paymentMethods = maps.map((map) {
      final String paymentMethodJson = map['data'];
      return PaymentMethod.create()
        ..mergeFromProto3Json(jsonDecode(paymentMethodJson));
    }).toList();

    //print("Found ${paymentMethods.length} payment methods in the database.");

    return paymentMethods;
  }

  // Get all trades
  Future<List<TradeInfo>> getAllTrades() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query('trades');

    // Convert the list of maps to a list of PaymentMethod objects
    List<TradeInfo> trades = maps.map((map) {
      final String tradesJson = map['data'];
      return TradeInfo.create()..mergeFromProto3Json(jsonDecode(tradesJson));
    }).toList();

    return trades;
  }

  // Get disputes
  Future<List<Dispute>> getAllDisputes() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query('disputes');

    // Convert the list of maps to a list of PaymentMethod objects
    List<Dispute> disputes = maps.map((map) {
      final String disputesJson = map['data'];
      return Dispute.create()..mergeFromProto3Json(jsonDecode(disputesJson));
    }).toList();

    return disputes;
  }

  Future<List<OfferInfo>> getOffers(
      {String? paymentMethodId, String? direction, bool? isMyOffer}) async {
    final db = await instance.database;

    // Build the where clause dynamically based on the provided criteria
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (paymentMethodId != null) {
      whereClauses.add('paymentMethodId = ?');
      whereArgs.add(paymentMethodId);
    }

    if (direction != null) {
      whereClauses.add('direction = ?');
      whereArgs.add(direction);
    }

    if (isMyOffer != null) {
      whereClauses.add('isMyOffer = ?');
      whereArgs.add(isMyOffer
          ? 1
          : 0); // Assuming isMyOffer is stored as 1 for true, 0 for false
    }

    // Combine the where clauses into a single string
    final whereClause =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    // Query the database with the dynamic where clause
    final List<Map<String, dynamic>> maps = await db!.query(
      'offers',
      where: whereClause,
      whereArgs: whereArgs,
    );

    // Convert the list of maps to a list of OfferInfo objects
    final List<OfferInfo> offers = maps.map((map) {
      final String offerJson =
          map['data']; // Assuming 'data' contains the serialized OfferInfo JSON
      return OfferInfo.create()..mergeFromProto3Json(jsonDecode(offerJson));
    }).toList();

    //print("Found ${offers.length} offers in the database.");

    return offers;
  }

  // Get payment method by ID
  Future<PaymentMethod> getPaymentMethodById(String paymentMethodId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'payment_methods',
      where: 'paymentMethodId = ?',
      whereArgs: [paymentMethodId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      // The data column contains the JSON string of the PaymentMethod
      final String paymentMethodJson = maps.first['data'];
      // Deserialize JSON back into a PaymentMethod object
      final paymentMethod = PaymentMethod.create()
        ..mergeFromProto3Json(jsonDecode(paymentMethodJson));
      return paymentMethod;
    }

    throw Exception(
        "Could not find payment method with ID $paymentMethodId in database, local state or fetched from remote!");
  }

  // Get trade by ID
  Future<TradeInfo?> getTradeById(String tradeId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'trades',
      where: 'tradeId = ?',
      whereArgs: [tradeId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      // The data column contains the JSON string of the PaymentMethod
      final String tradeJson = maps.first['data'];
      // Deserialize JSON back into a PaymentMethod object
      final trade = TradeInfo.create()
        ..mergeFromProto3Json(jsonDecode(tradeJson));
      return trade;
    }

    throw Exception("Could not find trade with ID $tradeId in database...");
  }

  // Get payment method by ID
  Future<PaymentMethod> getDisputeByTradeId(String paymentMethodId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'payment_methods',
      where: 'paymentMethodId = ?',
      whereArgs: [paymentMethodId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      // The data column contains the JSON string of the PaymentMethod
      final String paymentMethodJson = maps.first['data'];
      // Deserialize JSON back into a PaymentMethod object
      final paymentMethod = PaymentMethod.create()
        ..mergeFromProto3Json(jsonDecode(paymentMethodJson));
      return paymentMethod;
    }

    throw Exception(
        "Could not find payment method with ID $paymentMethodId in database, local state or fetched from remote!");
  }

  // Get all payment accounts
  Future<List<PaymentAccount>> getAllPaymentAccounts() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query('payment_accounts');

    // Convert the list of maps to a list of PaymentMethod objects
    List<PaymentAccount> paymentAccounts = maps.map((map) {
      final String paymentAccountsJson = map['data'];
      return PaymentAccount.create()
        ..mergeFromProto3Json(jsonDecode(paymentAccountsJson));
    }).toList();

    return paymentAccounts;
  }

  // Get payment account form by payment method ID
  Future<PaymentAccountForm?> getPaymentAccountFormByPaymentMethodId(
      String paymentMethodId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'payment_account_forms',
      where: 'paymentMethodId = ?',
      whereArgs: [paymentMethodId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      // The data column contains the JSON string of the PaymentMethod
      final String paymentAccountFormJson = maps.first['data'];
      // Deserialize JSON back into a PaymentMethod object
      final paymentAccountForm = PaymentAccountForm.create()
        ..mergeFromProto3Json(jsonDecode(paymentAccountFormJson));
      return paymentAccountForm;
    } else {
      return null;
    }
  }

  // Get all payment methods
  Future<List<PaymentAccountForm>?> getAllPaymentAccountForms() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps =
        await db!.query('payment_account_forms');

    // Convert the list of maps to a list of PaymentMethod objects
    List<PaymentAccountForm>? paymentAccountForms = maps.map((map) {
      final String paymentAccountFormsJson = map['data'];
      return PaymentAccountForm.create()
        ..mergeFromProto3Json(jsonDecode(paymentAccountFormsJson));
    }).toList();

    //print("Found ${paymentAccountForms.length} payment account forms in the database.");

    return paymentAccountForms;
  }

  // Insert a payment account into the database
  Future<void> insertPaymentAccountForm(
      String paymentMethodId, PaymentAccountForm paymentAccountForm) async {
    final db = await instance.database;
    final paymentAccountFormJson =
        jsonEncode(paymentAccountForm.toProto3Json());
    await db!.insert(
      'payment_account_forms',
      {
        'paymentAccountFormId': paymentAccountForm.id.name,
        'paymentMethodId': paymentMethodId,
        'data': paymentAccountFormJson,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Check if a trade is new
  Future<bool> isTradeNew(String tradeId) async {
    final db = await instance.database;
    final result =
        await db!.query('trades', where: 'tradeId = ?', whereArgs: [tradeId]);
    return result.isEmpty;
  }

  // Check if a trade chat message is new
  Future<bool> isTradeChatMessageNew(String messageId) async {
    final db = await instance.database;
    final result = await db!.query('trade_chat_messages',
        where: 'messageId = ?', whereArgs: [messageId]);
    return result.isEmpty;
  }

  // Check if a dispute is new
  Future<bool> isDisputeNew(String disputeId) async {
    final db = await instance.database;
    final result = await db!
        .query('disputes', where: 'disputeId = ?', whereArgs: [disputeId]);
    return result.isEmpty;
  }

  // Check if a dispute chat message is new
  Future<bool> isDisputeChatMessageNew(String messageId) async {
    final db = await instance.database;
    final result = await db!.query('dispute_chat_messages',
        where: 'messageId = ?', whereArgs: [messageId]);
    return result.isEmpty;
  }
}
