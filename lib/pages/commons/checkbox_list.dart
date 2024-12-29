import 'package:flutter/material.dart';

class CheckboxList extends StatefulWidget {

	final Map<String, bool?> labelMap;

	const CheckboxList(this.labelMap, {super.key});

	@override
  State<StatefulWidget> createState() => _CheckboxListState();
}

class _CheckboxListState extends State<CheckboxList> {
	@override
  Widget build(BuildContext context) {
    return Scrollbar(
			thumbVisibility: true,
			child: ListView(
				children: widget.labelMap.keys.map((s) => CheckboxListTile(
					tristate: widget.labelMap[s] == null,
					title: Text(s),
					value: widget.labelMap[s],
					onChanged: (bool? nv) => setState(() => widget.labelMap[s] = nv),
					controlAffinity: ListTileControlAffinity.leading,
				)).toList()
			)
		);
  }
}
