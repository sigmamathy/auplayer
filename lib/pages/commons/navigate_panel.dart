import 'package:auplayer/pages/commons/icon_text_button.dart';
import 'package:flutter/material.dart';

class NavigatePanel extends StatelessWidget {

	final String crnt;

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
						child: IconTextButton(Icons.album, "Album",
							_color("/album"), () => _routeTo(context, "/album")),
					),
					Expanded(
						child: IconTextButton(Icons.library_music, "Queue",
							_color("/queue"), () => _routeTo(context, "/queue"))
					),
				]
			)
		);
  }
	
	void _routeTo(BuildContext ctx, String route) {
		if (crnt != route) {
			Navigator.pushReplacementNamed(ctx, route);
		}
	}

	Color _color(String route) => crnt == route ? Colors.white : Colors.grey;
}
