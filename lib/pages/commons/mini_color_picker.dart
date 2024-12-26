import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class MiniColorPicker extends StatefulWidget {
	final BuildContext ctx;
	final Function(Color) callback;
	const MiniColorPicker(this.ctx, this.callback, {super.key});
	@override
  State<StatefulWidget> createState() => _MiniColorPickerState();
}

class _MiniColorPickerState extends State<MiniColorPicker> {

	Color crnt = Colors.red;

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
						labelTypes: const [],
						pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10)),
					)
				)
			)
		);
	}
}
