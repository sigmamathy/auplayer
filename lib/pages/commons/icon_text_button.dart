import 'package:flutter/material.dart';

class IconTextButton extends StatelessWidget {

	final IconData ic;
	final String text;
	final Color color;
	final VoidCallback onPressed;

	const IconTextButton(this.ic, this.text, this.color, this.onPressed, {super.key});

	@override
  Widget build(BuildContext context) {
    return TextButton(
			onPressed: onPressed,
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					Icon(ic, color: color, size: 25),
					Text(text, style: TextStyle(color: color, fontSize: 10))
				]
			),
		);
  }
}
