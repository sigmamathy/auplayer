import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class MiniColorPicker extends StatefulWidget {

	final BuildContext ctx;
	final Color? initColor;
	final Function(Color) callback;

	const MiniColorPicker(this.ctx, this.initColor, this.callback, {super.key});

	@override
  State<StatefulWidget> createState() => _MiniColorPickerState();
}

class _MiniColorPickerState extends State<MiniColorPicker> {

	late Color crnt;

	@override
  void initState() {
    super.initState();
		crnt = widget.initColor ?? Colors.red;
  }

	@override
  Widget build(BuildContext context) {
		int radius = 20;
    return TextButton(
			onPressed: _colorPickerDialog,
			child: Container(
				width: radius * 2,
				height: radius * 2,
				decoration: BoxDecoration(
					shape: BoxShape.circle,
					color: crnt,
					border: Border.all(color: Colors.white, width: 1.0),
				),
			)
		);
  }

	void _colorPickerDialog() {
		showDialog(
			context: widget.ctx,
			builder: (ctx) => AlertDialog(
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(0.0),
				),
				title: Text('Choose a color:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
				content: SingleChildScrollView(
					child: ColorPicker(
						pickerColor: crnt,
						onColorChanged: (Color c) {
							widget.callback(c);
							setState(() => crnt = c);
						},
						colorPickerWidth: 300,
						pickerAreaHeightPercent: 0.5,
						enableAlpha: false,
						displayThumbColor: true,
						paletteType: PaletteType.hsvWithHue,
						// labelTypes: const [],
					)
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(ctx),
						child: Text('DONE'),
					)
				],
			)
		);
	}
}
