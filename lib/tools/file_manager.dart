import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileInfo {
	String path;
	String name;
	bool isDir;
	FileInfo(this.path, this.name, this.isDir);
}

class FileManager {

	static late FileManager instance;

	late String homeDir;
	late String crntDir;
	List<FileInfo> fileList = [];

	Future<void> init() async {
		Directory dir = await getApplicationDocumentsDirectory();
		File f = File('${dir.path}/config.txt');
		if (await f.exists()) {
			homeDir = await f.readAsString();
		} else {
			homeDir = '/storage/emulated/0';
			setHomeDirectory(homeDir);
		}
		crntDir = homeDir;
	}

	Future<void> setHomeDirectory(String home) async {
		Directory dir = await getApplicationDocumentsDirectory();
		File f = File('${dir.path}/config.txt');
		await f.writeAsString(home);
	}
	
	Future<void> requestPermission() async {
		var status = await Permission.audio.status;
		if (status.isGranted) {
			await refreshFileList();
			return;
		}
		status = await Permission.audio.request();
		if (status.isGranted) {
			await refreshFileList();
		}
	}

	Future<void> refreshFileList({ String? newDir }) async {

		if (newDir != null) {
			crntDir = newDir;
		}

		Directory dir = Directory(crntDir);
		Stream<FileSystemEntity> fileStream = dir.list();
		fileList.clear(); // Clear the existing files list
		if (crntDir != '/storage/emulated/0') {
			fileList.add(FileInfo(crntDir.substring(0, crntDir.lastIndexOf('/')), "..", true));
		}
		await for (FileSystemEntity entity in fileStream) {
			switch (extension(entity.path)) {
				case "":
				case ".mp3":
				case ".m4a":
				case ".wav":
					fileList.add(FileInfo(entity.path, basename(entity.path), entity is Directory));
			}
		}
		fileList.sort((a, b) {
			if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
			return a.name.compareTo(b.name);
		});
	}
}
