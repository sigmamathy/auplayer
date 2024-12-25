import 'package:flutter/material.dart';

class CheckboxList extends StatefulWidget {

	final List<String> list;
	final List<String> checked;

	const CheckboxList(this.list, this.checked, {super.key});

	@override
  State<StatefulWidget> createState() => _CheckboxListState();
}

class _CheckboxListState extends State<CheckboxList> {
	@override
  Widget build(BuildContext context) {
    return ListView(
			children: widget.list.map((s) => CheckboxListTile(
				title: Text(s),
				value: widget.checked.contains(s),
				onChanged: (bool? nv) => setState(() => nv! ? widget.checked.add(s) : widget.checked.remove(s)),
				controlAffinity: ListTileControlAffinity.leading,
			)).toList()
		);
  }
}
