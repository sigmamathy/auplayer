import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'navigate_panel.dart';
import 'app_bar.dart';
import 'package:permission_handler/permission_handler.dart';

class AlbumPage extends StatefulWidget {
	const AlbumPage({ super.key });
	@override State<StatefulWidget> createState() => AlbumPageState();
}

class FileInfo {

	String filename;
	bool isDir;
	
	FileInfo(this.filename, this.isDir);
}

class AlbumPageState extends State<AlbumPage> {

	static String crntDir = "/storage/emulated/0/Music/Songs";
	static List<FileInfo> files = [];

	@override
  void initState() {
    super.initState();
		askPermission().then((ok) {
			if (ok) refreshFiles();
		});
  }
	
  static Future<void> refreshFiles() async {
		Directory directory = Directory(crntDir);
		Stream<FileSystemEntity> fileStream = directory.list();
		files.clear(); // Clear the existing files list
		if (crntDir != '/storage/emulated/0') files.add(FileInfo("..", true));
		await for (FileSystemEntity entity in fileStream) {
			switch (extension(entity.path)) {
				case "":
				case ".mp3":
				case ".m4a":
				case ".wav":
					files.add(FileInfo(basename(entity.path), entity is Directory));
			}
		}
		files.sort((a, b) {
			if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
			return a.filename.compareTo(b.filename);
		});
  }

	// only return true if permission is not granted before and accepted upon request.
	Future<bool> askPermission() async {
		var status = await Permission.audio.status;
		if (status.isGranted) return false;
		status = await Permission.audio.request();
		return status.isGranted;
	}

  @override
  Widget build(BuildContext context) {
		List<Widget> list = [];
		for (FileInfo fi in files) {
			list.add(_FileInfoCard(fi, () async {
				crntDir = fi.filename == '..' ? crntDir.substring(0, crntDir.lastIndexOf('/')) : '$crntDir/${fi.filename}';
				await refreshFiles();
				setState((){});
			}));
		}
		list.add(SizedBox(height: 10.0));
    return Scaffold(
			backgroundColor: Colors.grey[800],
			appBar: CommonAppBar(onRefresh: () async {
				await askPermission();
				await refreshFiles();
				setState((){});
			}),
			body: Column(
				children: [
					Expanded(
						child: SingleChildScrollView(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: list,
							)
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
			child: Padding(
				padding: EdgeInsets.all(10.0),
				child: Row(
					children: [
						Icon(Icons.audiotrack, color: Colors.white),
						Expanded(
							child: Text(
								fi.filename,
								style: TextStyle(
									color: Colors.white,
									fontSize: 18.0
								),
								softWrap: true,
								overflow: TextOverflow.ellipsis,
							)
						),
						IconButton(icon: Icon(Icons.add, color: Colors.white), onPressed: (){})
					]
				),
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
				child: Padding(
					padding: EdgeInsets.all(15.0),
					child: Row(
						children: [
							Icon(Icons.folder, color: Colors.amber),
							SizedBox(width: 8),
							Expanded(
								child: Text(
									fi.filename,
									style: TextStyle(
										color: Colors.amber,
										fontSize: 18.0
									),
									softWrap: true,
									overflow: TextOverflow.ellipsis,
								)
							),
						]
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
