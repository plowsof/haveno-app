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


/* import 'dart:convert';
import 'package:fixnum/fixnum.dart';
import 'package:haveno_app/proto/compiled/pb.pb.dart';

class CandlestickData {
  final int timestamp;
  final int open;
  final int high;
  final int low;
  final int close;
  final int volume;

  CandlestickData({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

Future<List<CandlestickData>> getCandlestickData(String period) async {
  final db = await instance.database;

  // Determine the start and end timestamps for the specified period
  int startTime;
  int endTime;

  DateTime now = DateTime.now();

  switch (period.toLowerCase()) {
    case 'daily':
      startTime = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      endTime = DateTime(now.year, now.month, now.day + 1).millisecondsSinceEpoch - 1;
      break;
    case 'weekly':
      startTime = DateTime(now.year, now.month, now.day - now.weekday + 1).millisecondsSinceEpoch;
      endTime = DateTime(now.year, now.month, now.day - now.weekday + 8).millisecondsSinceEpoch - 1;
      break;
    case 'monthly':
      startTime = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
      endTime = DateTime(now.year, now.month + 1, 1).millisecondsSinceEpoch - 1;
      break;
    case 'yearly':
      startTime = DateTime(now.year, 1, 1).millisecondsSinceEpoch;
      endTime = DateTime(now.year + 1, 1, 1).millisecondsSinceEpoch - 1;
      break;
    default:
      throw ArgumentError('Invalid period specified: $period');
  }

  // Query the database for trade statistics within the specified period
  final List<Map<String, dynamic>> maps = await db.query(
    'trade_statistics',
    where: 'date >= ? AND date <= ?',
    whereArgs: [startTime, endTime],
  );

  // Group the trade statistics by the period and calculate OHLC data
  Map<int, List<TradeStatistics3>> groupedData = {};

  for (var map in maps) {
    final tradeStatisticJson = map['data'];
    final tradeStatistic = TradeStatistics3.create()
      ..mergeFromProto3Json(jsonDecode(tradeStatisticJson));

    // Determine the period timestamp (e.g., start of the day, week, etc.)
    DateTime date = DateTime.fromMillisecondsSinceEpoch(tradeStatistic.date.toInt());
    int periodTimestamp;

    switch (period.toLowerCase()) {
      case 'daily':
        periodTimestamp = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
        break;
      case 'weekly':
        periodTimestamp = DateTime(date.year, date.month, date.day - date.weekday + 1).millisecondsSinceEpoch;
        break;
      case 'monthly':
        periodTimestamp = DateTime(date.year, date.month, 1).millisecondsSinceEpoch;
        break;
      case 'yearly':
        periodTimestamp = DateTime(date.year, 1, 1).millisecondsSinceEpoch;
        break;
      default:
        throw ArgumentError('Invalid period specified: $period');
    }

    groupedData.putIfAbsent(periodTimestamp, () => []).add(tradeStatistic);
  }

  // Calculate OHLC data for each group
  List<CandlestickData> candlestickData = groupedData.entries.map((entry) {
    final trades = entry.value;
    final sortedTrades = trades..sort((a, b) => a.date.compareTo(b.date));
    
    Int64 open = sortedTrades.first.price;
    Int64 close = sortedTrades.last.price;
    Int64 high = sortedTrades.map((trade) => trade.price).reduce((a, b) => a > b ? a : b);
    Int64 low = sortedTrades.map((trade) => trade.price).reduce((a, b) => a < b ? a : b);
    Int64 volume = sortedTrades.map((trade) => trade.amount).reduce((a, b) => a + b);

    return CandlestickData(
      timestamp: entry.key,
      open: open.toInt(),
      high: open.,
      high: ,
      low: low,
      close: close,
      volume: volume,
    );
  }).toList();

  return candlestickData;
}
 */