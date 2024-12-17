import 'package:flutter/material.dart';
import 'app_bar.dart';
import 'navigate_panel.dart';

class QueuePage extends StatefulWidget {
	const QueuePage({ super.key });
	@override State<StatefulWidget> createState() => QueuePageState();
}

class QueuePageState extends State<QueuePage> {



	@override
  Widget build(BuildContext context) {
    return Scaffold(
			backgroundColor: Colors.grey[800],
			appBar: CommonAppBar(onRefresh: (){}),
			body: Column(
				children: [
					Expanded(
						child: Container()
					),
					NavigatePanel(1)
				]
			),
		);
  }
}
