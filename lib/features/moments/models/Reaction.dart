import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ReactionButton extends StatefulWidget {
  @override
  _ReactionButtonState createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton> {
  String selectedReaction = "Like"; // Mặc định là Like

  void _showReactions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _reactionIcon("👍", "Like"),
              _reactionIcon("❤️", "Love"),
              _reactionIcon("😂", "Haha"),
              _reactionIcon("😢", "Sad"),
              _reactionIcon("😡", "Angry"),
            ],
          ),
        );
      },
    );
  }

  Widget _reactionIcon(String emoji, String name) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedReaction = name;
        });
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 24)),
          Text(name, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showReactions(context),
      child: Row(
        children: [
          Text(selectedReaction),
          Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}
