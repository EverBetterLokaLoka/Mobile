import 'package:flutter/material.dart';

import '../models/Feeling.dart';

class FeelingSelector extends StatefulWidget {
  @override
  _FeelingSelectorState createState() => _FeelingSelectorState();
}

class _FeelingSelectorState extends State<FeelingSelector> {
  Feeling? selectedFeeling;

  void _showFeelings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(10),
          child: Wrap(
            children: feelings.map((feeling) {
              return ListTile(
                leading: Text(feeling.emoji, style: TextStyle(fontSize: 24)),
                title: Text("Feeling ${feeling.name}"),
                onTap: () {
                  setState(() {
                    selectedFeeling = feeling;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFeelings(context),
      child: Row(
        children: [
          Text(selectedFeeling != null
              ? "${selectedFeeling!.emoji} Feeling ${selectedFeeling!.name}"
              : "How are you feeling?"),
          Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}
