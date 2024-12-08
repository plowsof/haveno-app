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

bool isFiatCurrency(String currencyCode) {
  return fiatCurrencies.contains(currencyCode);
}

bool isCryptoCurrency(String currencyCode) {
  return cryptoCurrencies.contains(currencyCode);
}

Set<String> getAllFiatCurrencies() {
  return fiatCurrencies;
}

Set<String> getAllCryptoCurrencies() {
  return cryptoCurrencies;
}

// Define sets for fiat and crypto currencies
const Set<String> fiatCurrencies = {
  'AED', 'AFN', 'ALL', 'AMD', 'ANG', 'AOA', 'ARS', 'AUD', 'AWG', 'AZN', 
  'BAM', 'BBD', 'BDT', 'BGN', 'BHD', 'BIF', 'BMD', 'BND', 'BOB', 'BRL', 
  'BSD', 'BTN', 'BWP', 'BYN', 'BZD', 'CAD', 'CDF', 'CHF', 'CLP', 'CNY', 
  'COP', 'CRC', 'CUP', 'CVE', 'CZK', 'DJF', 'DKK', 'DOP', 'DZD', 'EGP', 
  'ERN', 'ETB', 'EUR', 'FJD', 'FKP', 'FOK', 'GBP', 'GEL', 'GGP', 'GHS', 
  'GIP', 'GMD', 'GNF', 'GTQ', 'GYD', 'HKD', 'HNL', 'HRK', 'HTG', 'HUF', 
  'IDR', 'ILS', 'IMP', 'INR', 'IQD', 'IRR', 'ISK', 'JMD', 'JOD', 'JPY', 
  'KES', 'KGS', 'KHR', 'KMF', 'KRW', 'KWD', 'KYD', 'KZT', 'LAK', 'LBP', 
  'LKR', 'LRD', 'LSL', 'LYD', 'MAD', 'MDL', 'MGA', 'MKD', 'MMK', 'MNT', 
  'MOP', 'MRU', 'MUR', 'MVR', 'MWK', 'MXN', 'MYR', 'MZN', 'NAD', 'NGN', 
  'NIO', 'NOK', 'NPR', 'NZD', 'OMR', 'PAB', 'PEN', 'PGK', 'PHP', 'PKR', 
  'PLN', 'PYG', 'QAR', 'RON', 'RSD', 'RUB', 'RWF', 'SAR', 'SBD', 'SCR', 
  'SDG', 'SEK', 'SGD', 'SHP', 'SLE', 'SOS', 'SRD', 'SSP', 'STN', 'SYP', 
  'SZL', 'THB', 'TJS', 'TMT', 'TND', 'TOP', 'TRY', 'TTD', 'TVD', 'TWD', 
  'TZS', 'UAH', 'UGX', 'USD', 'UYU', 'UZS', 'VES', 'VND', 'VUV', 'WST', 
  'XAF', 'XCD', 'XOF', 'XPF', 'YER', 'ZAR', 'ZMW', 'ZWL'
};

const Set<String> cryptoCurrencies = {
  'BTC', // Bitcoin
  'BCH', // Bitcoin Cash
  'LTC', // Litecoin
  'ETH', // Ethereum
  'XMR' // Monero
};

enum PaymentMethodType {
  CRYPTO,
  FIAT,
  UNKNOWN,
}

// Payment Method Mappings
const Map<String, String> fiatPaymentMethodLabels = {
  'AUSTRALIA_PAYID': 'Australia PayID',
  'CASH_APP': 'Cash App',
  'CASH_AT_ATM': 'Cash at ATM',
  'F2F': 'Face to Face',
  'FASTER_PAYMENTS': 'Faster Payments',
  'MONEY_GRAM': 'MoneyGram',
  'PAXUM': 'Paxum',
  'PAYPAL': 'PayPal',
  'PAY_BY_MAIL': 'Pay by Mail',
  'REVOLUT': 'Revolut',
  'SEPA': 'SEPA',
  'SEPA_INSTANT': 'SEPA Instant',
  'STRIKE': 'Strike',
  'SWIFT': 'SWIFT',
  'TRANSFERWISE': 'TransferWise',
  'UPHOLD': 'Uphold',
  'VENMO': 'Venmo',
  'ZELLE': 'Zelle',
};

const Map<String, String> cryptoPaymentMethodLabels = {
  'BLOCK_CHAINS': 'Blockchains'
};

// Combine both maps for easy lookup
const Map<String, String> paymentMethodLabels = {
  ...fiatPaymentMethodLabels,
  ...cryptoPaymentMethodLabels,
};

String getPaymentMethodLabel(String id) {
  return paymentMethodLabels[id] ?? 'Unknown Payment Method';
}

PaymentMethodType getPaymentMethodType(String paymentMethodId) {
  if (cryptoPaymentMethodLabels.containsKey(paymentMethodId)) {
    return PaymentMethodType.CRYPTO;
  } else if (fiatPaymentMethodLabels.containsKey(paymentMethodId)) {
    return PaymentMethodType.FIAT;
  } else {
    return PaymentMethodType.UNKNOWN;
  }
}

dynamic formatXmr(Int64? atomicUnits, {bool returnString = true}) {
  if (atomicUnits == null) {
    return returnString ? 'N/A' : null;
  }
  double value = atomicUnits.toInt() / 1e12;
  return returnString ? value.toStringAsFixed(5) : value;
}


String formatFiat(double amount) {
  return amount.toStringAsFixed(2);
}

String autoFormatCurrency(dynamic amount, String currencyCode, {bool includeCurrencyCode = true}) {
  // Check if the currency is fiat
  if (isFiatCurrency(currencyCode)) {
    double fiatAmount;

    // Convert amount to double if it isn't already
    if (amount is Int64) {
      fiatAmount = amount.toDouble();
    } else if (amount is String) {
      fiatAmount = double.tryParse(amount) ?? 0.0;
    } else if (amount is double) {
      fiatAmount = amount;
    } else {
      return 'N/A'; // Return 'N/A' if the type is unexpected
    }

    // Format for fiat: 2 decimal places
    String formattedAmount = formatFiat(fiatAmount);

    // Append currency code if required
    return includeCurrencyCode ? '$formattedAmount $currencyCode' : formattedAmount;
  } 

  // Check if the currency is crypto
  else if (isCryptoCurrency(currencyCode)) {
    double cryptoAmount;

    // Convert amount to double if it isn't already
    if (amount is Int64) {
      cryptoAmount = formatXmr(amount, returnString: false) as double;
    } else if (amount is String) {
      cryptoAmount = double.tryParse(amount) ?? 0.0;
    } else if (amount is double) {
      cryptoAmount = amount;
    } else {
      return 'N/A'; // Return 'N/A' if the type is unexpected
    }

    // Format for crypto: 5 decimal places, but strip unnecessary zeros
    String formattedAmount = cryptoAmount.toStringAsFixed(5);
    formattedAmount = formattedAmount.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');

    return includeCurrencyCode ? '$formattedAmount $currencyCode' : formattedAmount;
  } 

  // If the currency is neither fiat nor crypto, return unknown
  else {
    return 'Unknown Currency';
  }
}
