import 'package:flutter/material.dart';

import 'package:auplayer/pages/commons/navigate_panel.dart';
import 'package:auplayer/tools/audio_player_handler.dart';
import 'package:auplayer/tools/file_manager.dart';

class AlbumPage extends StatefulWidget {
	const AlbumPage({ super.key });
	@override State<StatefulWidget> createState() => AlbumPageState();
}

bool _selectMode = false;
bool _folderViewMode = true;

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
					IconButton(
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
								case 3: {
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
												onSubmitted: (str) => input = str
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
									print('$ok: $input');
									await fm.createLabel(input, 0xFFFF0000);
									setState(() {});
								}
							}
						},
						itemBuilder: (BuildContext context) {
							final items = [
								PopupMenuItem<int>(
									value: 0,
									child: Row(
										children: [
											Icon(Icons.refresh, color: Colors.white),
											SizedBox(width: 6.0),
											Text('Refresh', style: TextStyle(color: Colors.white)),
										]
									)
								),
								PopupMenuItem<int>(
									value: 1,
									child: Row(
										children: [
											Icon(Icons.home, color: Colors.white),
											SizedBox(width: 6.0),
											Text('Set as Home', style: TextStyle(color: Colors.white)),
										]
									)
								),
								PopupMenuItem<int>(
									value: 2,
									child: Row(
										children: [
											Icon(Icons.help, color: Colors.white),
											SizedBox(width: 6.0),
											Text('Help', style: TextStyle(color: Colors.white)),
										]
									)
								),
								PopupMenuItem<int>(
									value: 3,
									child: Row(
										children: [
											Icon(Icons.add, color: Colors.white),
											SizedBox(width: 6.0),
											Text('Add Label', style: TextStyle(color: Colors.white)),
										]
									)
								),
							];

							if (_folderViewMode) {
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
    return Scaffold(
			backgroundColor: Colors.grey[800],
			appBar: _appBar(context),
			body: _folderViewMode ? _FolderViewWidget() : _LabelViewWidget()
		);
  }
}

class _FolderViewWidget extends StatefulWidget {
	@override
  State<StatefulWidget> createState() => _FolderViewWidgetState();
}

class _FolderViewWidgetState extends State<_FolderViewWidget> {

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
						children: [...fm.fileList.map((fi) => _FileInfoCard(fi, () async {
							await fm.refreshFileList(newDir: fi.path);
							setState(() {});
						})), SizedBox(height: 10.0)]
					)
				),
				NavigatePanel(0)
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

class _FileInfoCard extends StatelessWidget {

	final FileInfo fi;
	final VoidCallback onDirTapped;

	const _FileInfoCard(this.fi, this.onDirTapped);

	Widget audioFileBuild() {
		return Card(
			margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
			color: Colors.grey[900],
			child: ListTile(
				leading: Icon(Icons.audiotrack, color: Colors.white),
				title: Text(
					fi.name,
					style: TextStyle(
						color: Colors.white,
						fontSize: 14.0
					),
				),
				trailing: IconButton(
					icon: Icon(Icons.add, color: Colors.white),
					onPressed: () {
						AudioPlayerHandler.instance.addMusic(fi);
					}
				)
			)
		);
	}

	Widget directoryBuild()
	{	
		return GestureDetector(
			onTap: onDirTapped,
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

	@override
  Widget build(BuildContext context) {
		return fi.isDir ? directoryBuild() : audioFileBuild();
  }
}
