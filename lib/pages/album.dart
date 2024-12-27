import 'package:auplayer/pages/commons/checkbox_list.dart';
import 'package:auplayer/pages/commons/mini_color_picker.dart';
import 'package:auplayer/pages/commons/three_dots_button.dart';
import 'package:flutter/material.dart';
import 'package:auplayer/pages/commons/icon_text_button.dart';

import 'package:auplayer/pages/commons/navigate_panel.dart';
import 'package:auplayer/tools/audio_player_handler.dart';
import 'package:auplayer/tools/file_manager.dart';

bool _folderViewMode = true;
List<FileInfo> _selectedFiles = [];

bool _isSelected(FileInfo fi) => _selectedFiles.any((f) => f.path == fi.path);
VoidCallback _pageSetState = () => throw UnimplementedError();

class AlbumPage extends StatefulWidget {
	const AlbumPage({ super.key });
	@override State<StatefulWidget> createState() => AlbumPageState();
}

class AlbumPageState extends State<AlbumPage> {

	static bool _firstExecution = true;
	void _executeOnStartOnly() {
		if (!_firstExecution)	return;
		FileManager.instance.requestPermission().then((_) => setState(() {}));
		_firstExecution = false;
	}

	@override
  void initState() {
    super.initState();
		_pageSetState = () => setState(() {});
		_executeOnStartOnly();
  }

	AppBar _appBar(BuildContext ctx) {
		final fm = FileManager.instance;
		return AppBar(
			title: Row(
				children: [
					Text("auplayer",
						style: TextStyle(
							color: Colors.white,
							fontFamily: 'RougeScript', 
							fontWeight: FontWeight.bold,
							fontSize: 30.0
						)
					),
					Expanded(child: SizedBox()),
					if (_selectedFiles.isEmpty) IconButton(
						icon: Icon(
							!_folderViewMode ? Icons.perm_media : Icons.bookmarks,
							color: Colors.white
						),
						onPressed: () {
							setState(() { _folderViewMode = !_folderViewMode; });
						},
					),
					ThreeDotsButton(
						items: [
							ThreeDotsItem(Icons.refresh, "Refresh",
								() async { await fm.refreshFileList(); setState((){}); }),
							ThreeDotsItem(Icons.home, "Set as Home",
								() async { await fm.setHomeDirectory(fm.crntDir); setState(() {}); }),
							ThreeDotsItem(Icons.help, "Help", (){}),
							ThreeDotsItem(Icons.new_label, "Add Label",
								() async { await _userCreateOrEditLabel(context, null); setState(() {}); }),
						],
						indices: _folderViewMode ? [0, 1, 2] : [3, 2],
					),
				]
			),
			backgroundColor: Colors.deepPurple[700],
		);
	}

  @override
  Widget build(BuildContext context) {
    return PopScope(
			canPop: _selectedFiles.isEmpty,
			onPopInvokedWithResult: (bool didPop, Object? _) {
				_selectedFiles.clear();
				_pageSetState();
			},
			child: Scaffold(
				backgroundColor: Colors.grey[800],
				resizeToAvoidBottomInset: false,
				appBar: _appBar(context),
				body: _folderViewMode ? _FolderViewWidget() : _LabelViewWidget()
			)
		);
  }
}

class _FolderViewWidget extends StatefulWidget {
	@override
  State<StatefulWidget> createState() => _FolderViewWidgetState();
}

class _FolderViewWidgetState extends State<_FolderViewWidget> {

	void _setState() => setState(() {});

	@override
  Widget build(BuildContext context) {
		final fm = FileManager.instance;
		return Column(
			children: [
				Container(
					color: Color.fromARGB(255, 65, 51, 94),
					child: Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							Text(
								fm.crntDir,
								textAlign: TextAlign.left,
								style: TextStyle(color: Colors.white, fontSize: 10.0)
							),
						]
					)
				),
				Expanded(
					child: ListView (
						children: [...fm.fileList.map((fi) =>
							fi.isDir ? _DirectoryCard(fi, _setState) : _AudioFileCard(fi)), SizedBox(height: 10.0)]
					)
				),
				_selectedFiles.isEmpty ? NavigatePanel('/album') : Container(
					height: 70,
					decoration: BoxDecoration(
						border: Border(top: BorderSide(color: Colors.cyan)),
						color: const Color(0xFF13283B),
					),
					child: Row(
						mainAxisAlignment: MainAxisAlignment.spaceEvenly,
						children: [
							IconTextButton(Icons.select_all, "Select All", Colors.white, () {
								for (FileInfo fi in fm.fileList) {
									if (!_isSelected(fi)) {
										_selectedFiles.add(fi);
									}
								}
								_pageSetState();
							}),
							IconTextButton(Icons.deselect, "Cancel", Colors.white, () {
								_selectedFiles.clear();
								_pageSetState();
							}),
							IconTextButton(Icons.playlist_add, "Add to Queue", Colors.white,
								() => _selectedFiles.forEach(AudioPlayerHandler.instance.addMusic)),
							IconTextButton(Icons.bookmark_add, "Add to Label", Colors.white, () async {
								List<String> lbs = [];
								bool? ok = await showDialog(
									context: context,
									builder: (ctx) => AlertDialog(
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(0.0),
										),
										title: Text('Select labels to add:', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
										content: SizedBox(
											width: 300,
											height: 500,
											child: CheckboxList(fm.labels.map((l) => l.name).toList(), lbs)
										),
										actions: [
											TextButton( child: Text('CANCEL'), onPressed: () => Navigator.pop(ctx, false)),
											TextButton( child: Text('CONFIRM'), onPressed: () => Navigator.pop(ctx, true))
										]
									)
								);
								if (ok ?? false) {
									for (final label in lbs) {
										await fm.assignLabelToFiles(label, _selectedFiles);
									}
								}
							}),
						]
					)
				)
			]
		);
  }
}

class _LabelViewWidget extends StatefulWidget {
	@override
  State<StatefulWidget> createState() => _LabelViewWidgetState();
}

class _LabelViewWidgetState extends State<_LabelViewWidget> {

	@override
  Widget build(BuildContext context) {
		final fm = FileManager.instance;
    return Column(
			children: [
				Expanded(
					child: ListView(
						children: [
							if (fm.crntLabel != null) _LabelCard(null),
							...(fm.crntLabel == null ?
								fm.labels.map((l) => _LabelCard(l))
								: fm.labelItems.map((f) => _AudioFileCard(f))),
							SizedBox(height: 10.0)
						]
					)
				),
				NavigatePanel('/album')
			]
		);
  }
}

Future<void> _userCreateOrEditLabel(BuildContext ctx, LabelInfo? label) async {
	final fm = FileManager.instance;
	String input = '';
	Color color = Colors.red;
	bool? ok = await showDialog(
		context: ctx,
		builder: (ctx) => AlertDialog(
			shape: RoundedRectangleBorder(
				borderRadius: BorderRadius.circular(0.0),
			),
			title: Text(label == null ? 'New Label' : "Edit Label", style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
			content: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					MiniColorPicker(ctx, label != null ? Color(label.color) : null, (c) => color = c),
					SizedBox(
						width: 200,
						height: 50,
						child: TextField(
							decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Enter Name'),
							onChanged: (str) => input = str
						)
					),
				]
			),
			actions: [
				TextButton(
					child: Text('CANCEL'),
					onPressed: () => Navigator.pop(ctx, false)
				),
				TextButton(
					child: Text('CONFIRM'),
					onPressed: () => Navigator.pop(ctx, true)
				)
			]
		)
	);

	if (ok ?? false) {
		int cv = 0xFF000000 | ((color.r * 255).toInt() << 16) | ((color.g * 255).toInt() << 8) | (color.b * 255).toInt();
		await (label == null ? fm.createLabel(input, cv) : fm.editLabel(label, LabelInfo(input, cv)));
	}
}

class _AudioFileCard extends StatelessWidget {

	final FileInfo fi;
	const _AudioFileCard(this.fi);

	void toggleSelection() {
		if (_isSelected(fi)) {
			_selectedFiles.removeWhere((f) => f.path == fi.path);
		} else {
			_selectedFiles.add(fi);
		}
	}

	@override
  Widget build(BuildContext context) {
		bool isSelected = _isSelected(fi);
		return GestureDetector(
			onTap: () { 
				if (_selectedFiles.isNotEmpty) {
					toggleSelection();
					_pageSetState();
				}
			},
			onLongPress: () {
				toggleSelection();
				_pageSetState();
			},
			child: Card(
				margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
				color: Colors.grey[900],
				shape: isSelected ? RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(10.0),
					side: BorderSide(
						color: Colors.cyan,
						width: 2.0,
					),
				) : null,
				child: ListTile(
					leading: Icon(Icons.audiotrack, color: isSelected ? Colors.cyan : Colors.white),
					title: Text(
						fi.name,
						style: TextStyle(
							color: isSelected ? Colors.cyan : Colors.white,
							fontSize: 14.0
						),
					),
					trailing: _selectedFiles.isEmpty ? IconButton(
						icon: Icon(Icons.add, color: Colors.white),
						onPressed: () {
							AudioPlayerHandler.instance.addMusic(fi);
						}
					) : null
				)
			)
		);
  }
}

class _DirectoryCard extends StatelessWidget {
	
	final FileInfo fi;
	final VoidCallback updateState;
	const _DirectoryCard(this.fi, this.updateState);

	@override
  Widget build(BuildContext context) {
		return GestureDetector(
			onTap: () async {
				await FileManager.instance.refreshFileList(newDir: fi.path);
				updateState();
			},
			child: Card(
				margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
				color: Colors.grey[900],
				child: ListTile(
					leading: Icon(Icons.folder, color: Colors.amber),
					title: Text(
						fi.name,
						style: TextStyle(
							color: Colors.amber,
							fontSize: 14.0
						),
					),
				)
			)
		);
  }
}

class _LabelCard extends StatelessWidget {
	
	final LabelInfo? li;
	const _LabelCard(this.li);

	@override
  Widget build(BuildContext context) {
		return li != null ? _nonNullBuild(context) : _nullBuild(context);
  }

	Widget _nonNullBuild(BuildContext context) {
		return GestureDetector(
			onTap: () async {
				FileManager.instance.setCurrentLabel(li!.name);
				_pageSetState();
			},
			child: Card(
				margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
				color: Colors.grey[900],
				elevation: 2.0,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(10.0),
					side: BorderSide(
						color: Color(li!.color),
						width: 1.0,
					),
				),
				child: ListTile(
					leading: Icon(Icons.bookmark, color: Color(li!.color)),
					title: Text(
						li!.name,
						style: TextStyle(
							color: Color(li!.color),
							fontSize: 14.0
						),
					),
					trailing: _trailingButton(context),
				)
			)
		);
	}

	Widget _nullBuild(BuildContext context) {
		final fm = FileManager.instance;
		return GestureDetector(
			onTap: () async {
				FileManager.instance.setCurrentLabel(null);
				_pageSetState();
			},
			child: Card(
				margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
				color: Colors.grey[900],
				elevation: 2.0,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(10.0),
					side: BorderSide(
						color: Color(fm.crntLabel!.color),
						width: 1.0,
					),
				),
				child: ListTile(
					leading: Icon(Icons.bookmark, color: Color(fm.crntLabel!.color)),
					title: Text(
						"..",
						style: TextStyle(
							color: Color(fm.crntLabel!.color),
							fontSize: 14.0
						),
					),
				)
			)
		);
	}

	Widget _trailingButton(BuildContext context) {
		return ThreeDotsButton(
			items: [
				ThreeDotsItem(Icons.edit, "Edit", () async { await _userCreateOrEditLabel(context, li); _pageSetState(); }),
				ThreeDotsItem(Icons.delete, "Delete", () async {
					bool? ok = await showDialog(
						context: context,
						builder: (ctx) => AlertDialog(
							shape: RoundedRectangleBorder(
								borderRadius: BorderRadius.circular(0.0),
							),
							title: Text(
								'Alert',
								style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)
							),
							content: Text('Are you sure you want to delete "${li!.name}"? This action cannot be undone.'),
							actions: [
								TextButton(
									onPressed: () => Navigator.pop(ctx, false),
									child: Text('NO'),
								),
								TextButton(
									onPressed: () => Navigator.pop(ctx, true),
									child: Text('YES'),
								)
							]
						)
					);
					if (ok ?? false) {
						await FileManager.instance.deleteLabel(li!.name);
						_pageSetState();
					}
				}),
			],
			child: Icon(Icons.more_vert, color: Color(li!.color)),
		);
	}
}
