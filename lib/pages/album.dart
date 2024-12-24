import 'package:flutter/material.dart';

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
					PopupMenuButton<int>(
						onSelected: (int value) async {
							switch (value) {
								case 0:
									await fm.refreshFileList();
									setState(() {});
									break;
								case 1:
									await fm.setHomeDirectory(fm.crntDir);
									setState(() {});
									break;
								case 3: 
									await _userCreateNewLabel(ctx);
									setState(() {});
								case 4:
									for (FileInfo fi in _selectedFiles) {
										AudioPlayerHandler.instance.addMusic(fi);
									}
									break;
							}
						},
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

							final items = [
								makeItem(0, Icons.refresh, "Refresh"),
								makeItem(1, Icons.home, "Set as Home"),
								makeItem(2, Icons.help, "Help"),
								makeItem(3, Icons.add, "Add Label"),
								makeItem(4, Icons.add, "Add to queue"),
							];

							if (_folderViewMode) {
								if (_selectedFiles.isNotEmpty)
									return [0, 1, 4, 2].map((i) => items[i]).toList();

								return [0, 1, 2].map((i) => items[i]).toList();
							}

							return [3, 2].map((i) => items[i]).toList();
						},
						color: Colors.grey[850],
						child: Icon(Icons.more_vert, color: Colors.white),
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
							fi.isDir ? _DirectoryCard(fi, _setState) : _AudioFileCard(fi, _setState)), SizedBox(height: 10.0)]
					)
				),
				_selectedFiles.isEmpty ? NavigatePanel(0) : Container(
					height: 70,
					// color: const Color(0xFF13283B),
					decoration: BoxDecoration(
						border: Border(top: BorderSide(color: Colors.cyan)),
						color: const Color(0xFF13283B),
					),
					child: Row(
						mainAxisAlignment: MainAxisAlignment.spaceEvenly,
						children: [
							TextButton(
								child: Column(
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										Icon(Icons.select_all, color: Colors.white),
										Text("Select All", style: TextStyle(color: Colors.white))
									]
								),
								onPressed: () {
									for (FileInfo fi in fm.fileList) {
										if (!_isSelected(fi)) {
											_selectedFiles.add(fi);
										}
									}
									_pageSetState();
								}
							),
							TextButton(
								child: Column(
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										Icon(Icons.deselect, color: Colors.white),
										Text("Cancel", style: TextStyle(color: Colors.white))
									]
								),
								onPressed: () {
									_selectedFiles.clear();
									_pageSetState();
								}
							),
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
						children: [...fm.labels.map((l) => Card(
							color: Color(l.color),
							child: ListTile(
								title: Text(l.name)
							)
						))]
					)
				),
				NavigatePanel(0)
			]
		);
  }
}

Future<void> _userCreateNewLabel(BuildContext ctx) async {
	final fm = FileManager.instance;
	String input = '';
	bool ok = false;

	await showDialog(
		context: ctx,
		builder: (ctx) => AlertDialog(
			title: Text('New Label'),
			content: TextField(
				decoration: InputDecoration(
					border: OutlineInputBorder(),
					labelText: 'name',
				),
				onChanged: (str) => input = str
			),
			actions: [
				TextButton(
					child: Text('CANCEL'),
					onPressed: () {
						ok = false;
						Navigator.pop(ctx);
					}
				),
				TextButton(
					child: Text('CONFIRM'),
					onPressed: () {
						ok = true;
						Navigator.pop(ctx);
					}
				)
			]
		)
	);

	if (ok) {
		await fm.createLabel(input, 0xFFFF0000);
	}
}

class _AudioFileCard extends StatelessWidget {

	final FileInfo fi;
	final VoidCallback updateState;
	const _AudioFileCard(this.fi, this.updateState);

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


