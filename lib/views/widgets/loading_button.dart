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


import 'package:flutter/material.dart';

class LoadingButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final Widget child;
  final ButtonStyle? style;
  final double? width;
  final double? height;

  const LoadingButton({
    required this.onPressed,
    required this.child,
    this.style,
    this.width,
    this.height,
    super.key,
  });

  @override
  _LoadingButtonState createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool _isLoading = false;

  void _handlePressed() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onPressed();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define the default style with a minimum height of 48
    final defaultStyle = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(48), // Default minimum height
    );

    return SizedBox(
      width: widget.width,
      height: widget.height, // Optionally provide custom height or leave null
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handlePressed,
        style: widget.style ?? defaultStyle, // Apply custom style or fallback to default
        child: _isLoading
            ? const SizedBox(
                width: 24, 
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : widget.child,
      ),
    );
  }
}
