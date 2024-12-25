import 'package:flutter/material.dart';

class NavigatePanel extends StatelessWidget {

	final int crnt;

	const NavigatePanel(this.crnt, { super.key });

	@override
  Widget build(BuildContext context) {
		return Container(
			height: 70,
			color: Color.fromARGB(255, 63, 43, 92),
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceEvenly,
				children: [
					Expanded(
						child: TextButton(
							child: Column(
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									Icon(Icons.album, color: (crnt == 0 ? Colors.white : Colors.grey)),
									Text("Album", style: TextStyle(color: (crnt == 0 ? Colors.white : Colors.grey)))
								]
							),
							onPressed: () {
								if (crnt != 0) {
									Navigator.pushReplacementNamed(context, '/album');
								}
							}
						)
					),
					Expanded(
						child: TextButton(
							child: Column(
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									Icon(Icons.library_music, color: (crnt == 1 ? Colors.white : Colors.grey)),
									Text("Queue", style: TextStyle(color: (crnt == 1 ? Colors.white : Colors.grey)))
								]
							),
							onPressed: () {
								if (crnt != 1) {
									Navigator.pushReplacementNamed(context, '/queue');
								}
							}
						)
					),
				]
			)
		);
  }
}
