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

import 'package:haveno/profobuf_models.dart';
import 'package:haveno_app/utils/string_utils.dart';

String humanReadableDisputeStateAs(String disputeState, bool isBuyer, bool directedAtUser) {
  final disputeStateMap = {
    "PB_ERROR_DISPUTE_STATE": directedAtUser ? "You encountered an error in dispute state" : "Error in Dispute State",
    "NO_DISPUTE": "No Dispute",
    "DISPUTE_REQUESTED": directedAtUser ? "You requested a dispute" : isBuyer ? "Buyer requested a dispute" : "Seller requested a dispute",
    "DISPUTE_OPENED": directedAtUser ? "You opened a dispute" : isBuyer ? "Buyer opened a dispute" : "Seller opened a dispute",
    "ARBITRATOR_SENT_DISPUTE_CLOSED_MSG": directedAtUser ? "Arbitrator closed the dispute" : "Dispute closed by Arbitrator",
    "ARBITRATOR_SEND_FAILED_DISPUTE_CLOSED_MSG": directedAtUser ? "Failed to receive dispute closed message from arbitrator" : "Failed to close dispute by Arbitrator",
    "ARBITRATOR_STORED_IN_MAILBOX_DISPUTE_CLOSED_MSG": directedAtUser ? "Arbitrator stored dispute closed message in your mailbox" : "Dispute closed message stored in mailbox",
    "ARBITRATOR_SAW_ARRIVED_DISPUTE_CLOSED_MSG": directedAtUser ? "Arbitrator saw your dispute closed message" : "Arbitrator saw arrived dispute closed message",
    "DISPUTE_CLOSED": directedAtUser ? "You closed the dispute" : "Dispute Closed",
    "MEDIATION_REQUESTED": directedAtUser ? "You requested mediation" : isBuyer ? "Buyer requested mediation" : "Seller requested mediation",
    "MEDIATION_STARTED_BY_PEER": directedAtUser ? "The other party started mediation" : "Mediation started by peer",
    "MEDIATION_CLOSED": directedAtUser ? "You closed the mediation" : "Mediation Closed",
    "REFUND_REQUESTED": directedAtUser ? "You requested a refund" : isBuyer ? "Buyer requested a refund" : "Seller requested a refund",
    "REFUND_REQUEST_STARTED_BY_PEER": directedAtUser ? "The other party started a refund request" : "Refund request started by peer",
    "REFUND_REQUEST_CLOSED": directedAtUser ? "You closed the refund request" : "Refund request closed",
  };

  // Return the human-readable string or a fallback if the state is not found
  return disputeStateMap[disputeState] ?? "Unknown Dispute State";
}

String humanReadablePhaseAs(String phase, bool isBuyer, bool isDirectedAtBuyer) {
  final phaseMap = {
    "PB_ERROR_PHASE": isDirectedAtBuyer
        ? isBuyer
            ? "You encountered an error in the trade phase"
            : "The buyer encountered an error in the trade phase"
        : isBuyer
            ? "Buyer encountered an error in the trade phase"
            : "Seller encountered an error in the trade phase",
    "INIT": isDirectedAtBuyer
        ? isBuyer
            ? "You initialized the trade"
            : "The seller initialized the trade"
        : isBuyer
            ? "Buyer initialized the trade"
            : "Seller initialized the trade",
    "DEPOSIT_REQUESTED": isDirectedAtBuyer
        ? isBuyer
            ? "You requested a deposit"
            : "The seller requested a deposit"
        : isBuyer
            ? "Buyer requested a deposit"
            : "Seller requested a deposit",
    "DEPOSITS_PUBLISHED": isDirectedAtBuyer
        ? isBuyer
            ? "Your deposits were published"
            : "The seller's deposits were published"
        : isBuyer
            ? "Buyer published the deposits"
            : "Seller published the deposits",
    "DEPOSITS_CONFIRMED": isDirectedAtBuyer
        ? isBuyer
            ? "Your deposits are confirmed"
            : "The seller's deposits are confirmed"
        : isBuyer
            ? "Buyer's deposits are confirmed"
            : "Seller's deposits are confirmed",
    "DEPOSITS_UNLOCKED": isDirectedAtBuyer
        ? isBuyer
            ? "You must now send payment"
            : "The seller must now send payment"
        : isBuyer
            ? "Buyer's deposits are unlocked"
            : "Waiting for peer to pay",
    "PAYMENT_SENT": isDirectedAtBuyer
        ? isBuyer
            ? "You marked payment as sent"
            : "The seller marked payment as sent"
        : isBuyer
            ? "Buyer marked payment as sent"
            : "Seller confirming payment",
    "PAYMENT_RECEIVED": isDirectedAtBuyer
        ? isBuyer
            ? "You received the payment"
            : "The seller received your payment"
        : isBuyer
            ? "Seller received the payment"
            : "Buyer received the payment",
  };

  // Return the human-readable string or a fallback if the phase is not found
  return phaseMap[phase] ?? "Unknown Trade Phase";
}


String humanReadablePayoutStateAs(String status, bool isBuyer, bool isDirectedAtBuyer) {
  final stateMap = {
    "PAYOUT_UNPUBLISHED": isDirectedAtBuyer
        ? isBuyer
            ? "Your payout is being published"
            : "Seller's payout is published"
        : isBuyer
            ? "Buyer's payout is unpublished"
            : "Your payout is unpublished",
    "PAYOUT_PUBLISHED": isDirectedAtBuyer
        ? isBuyer
            ? "Your payout has been published"
            : "Seller's payout has been published"
        : isBuyer
            ? "Buyer's payout has been published"
            : "Your payout has been published",
    "PAYOUT_CONFIRMED": isDirectedAtBuyer
        ? isBuyer
            ? "Your payout is confirmed"
            : "Seller's payout is confirmed"
        : isBuyer
            ? "Buyer's payout is confirmed"
            : "Your payout is confirmed",
    "PAYOUT_UNLOCKED": isDirectedAtBuyer
        ? isBuyer
            ? "Completed"
            : "Completed"
        : isBuyer
            ? "Completed"
            : "Completed",
  };

  // Return the human-readable string or a fallback if the status is not found
  return stateMap[status] ?? "Unknown Payout State";
}


/// A utility function to get a human-readable label for a given form field.
String getHumanReadablePaymentMethodFormFieldLabel(
  MapEntry<String, dynamic> entry,
  List<PaymentAccountFormField?> fields,
) {
  var matchId = convertCamelCaseToSnakeCase(entry.key);

  var matchingField = fields.firstWhere(
    (field) => field != null && field.id.toString() == matchId,
    orElse: () {
      throw Exception("Couldn't map ${entry.toString()} to a payload for form for any of the fields: ${fields.join(", ")}.");
    },
  );

  return matchingField != null && matchingField.label.isNotEmpty
      ? matchingField.label
      : entry.key;
}
