import 'package:flutter/material.dart';

class CommonAppBar extends AppBar {

	CommonAppBar({ VoidCallback? onRefresh, super.key })
		: super(
				title: Row(
				children: [
					Text("My App", style: TextStyle(color: Colors.white)),
					Expanded(child: SizedBox()),
					IconButton(
						icon: Icon(Icons.refresh, color: Colors.white),
						onPressed: onRefresh,
					),
				]
			),
			backgroundColor: Colors.deepPurple[700],
		);
}
