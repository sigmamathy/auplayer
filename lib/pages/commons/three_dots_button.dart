import 'package:flutter/material.dart';

class ThreeDotsItem {
	IconData ic;
	String text;
	VoidCallback onPressed;
	ThreeDotsItem(this.ic, this.text, this.onPressed);
}

class ThreeDotsButton extends StatelessWidget {

	final List<ThreeDotsItem> items;
	final List<int>? indices;
	final Widget? child;
	final Offset? offset;

	const ThreeDotsButton({ super.key, required this.items, this.indices, this.child, this.offset });

	@override
  Widget build(BuildContext context) {
		return PopupMenuButton<int>(
			onSelected: (int value) => items[value].onPressed(),
			itemBuilder: (BuildContext context) {
				PopupMenuItem<int> makeItem(int n, IconData ic, String text) => PopupMenuItem<int>(
					value: n,
					child: Row(
						children: [
							Icon(ic, color: Colors.white),
							SizedBox(width: 6.0),
							Text(text, style: TextStyle(color: Colors.white)),
						]
					)
				);
				return (indices ?? List<int>.generate(items.length, (i) => i))
					.map((i) => makeItem(i, items[i].ic, items[i].text)).toList();
			},
			color: const Color(0xFF303030),
			offset: offset ?? const Offset(0, 0),
			child: child ?? Icon(Icons.more_vert, color: Colors.white, size: 30.0),
		);
  }
}
