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


import 'package:fixnum/fixnum.dart';

String calculateFormattedTimeSince(dynamic creationDate) {
  DateTime creationDateTime;

  if (creationDate is Int64) {
    creationDateTime = DateTime.fromMillisecondsSinceEpoch(creationDate.toInt());
  } else if (creationDate is DateTime) {
    creationDateTime = creationDate;
  } else {
    throw ArgumentError('Invalid argument type. Must be Int64 or DateTime.');
  }

  final now = DateTime.now();
  final difference = now.difference(creationDateTime);

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minutes';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hours';
  } else if (difference.inDays < 30) {
    return '${difference.inDays} days';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return '$months months';
  } else {
    final years = (difference.inDays / 365).floor();
    return '$years years';
  }
}