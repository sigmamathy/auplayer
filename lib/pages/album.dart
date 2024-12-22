import 'package:flutter/material.dart';

import 'package:auplayer/navigate_panel.dart';
import 'package:auplayer/tools/audio_player_handler.dart';
import 'package:auplayer/tools/file_manager.dart';

class AlbumPage extends StatefulWidget {
	const AlbumPage({ super.key });
	@override State<StatefulWidget> createState() => AlbumPageState();
}

enum AlbumReadMode {
	FOLDER_VIEW,
	LABEL_VIEW,
	FOLDER_SELECT_VIEW;

	static AlbumReadMode crntMode = FOLDER_VIEW;
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
		_executeOnStartOnly();
  }

  @override
  Widget build(BuildContext context) {
		final fm = FileManager.instance;
    return Scaffold(
			backgroundColor: Colors.grey[800],
			appBar: AppBar(
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
								AlbumReadMode.crntMode == AlbumReadMode.FOLDER_VIEW ? Icons.perm_media : Icons.bookmarks,
								color: Colors.white
							),
							onPressed: () {
								
								AlbumReadMode.crntMode = AlbumReadMode.crntMode == AlbumReadMode.FOLDER_VIEW ? AlbumReadMode.LABEL_VIEW : AlbumReadMode.FOLDER_VIEW;
								setState((){});
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
								}
							},
							itemBuilder: (BuildContext context) {
								return <PopupMenuEntry<int>>[
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
								];
							},
							color: Colors.grey[800],
							child: Icon(Icons.more_vert, color: Colors.white),
						),
					]
				),
				backgroundColor: Colors.deepPurple[700],
			),
			body: Column(
				children: [
					Container(
						color: Color.fromARGB(255, 65, 51, 94),
						child: Row(
							mainAxisAlignment: MainAxisAlignment.spaceBetween,
							children: [
								Text(fm.crntDir, style: TextStyle(color: Colors.white, fontSize: 10.0)),
								SizedBox(
									width: 25.0,
									height: 25.0,
									child: IconButton(
										padding: EdgeInsets.all(0.0),
										icon: Icon(Icons.folder),
										onPressed: () {},
										color: Colors.white,
										iconSize: 15.0,
									)
								)
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
			),
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
