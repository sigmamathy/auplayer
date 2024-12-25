import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

class FileInfo {
	String path;
	String name;
	bool isDir;
	FileInfo(this.path, this.name, this.isDir);
}

class LabelInfo {
	String name;
	int color;
	LabelInfo(this.name, this.color);
}

class FileManager {

	static late FileManager instance;

	final _DatabaseHandler _db = _DatabaseHandler();

	late String homeDir;
	late String crntDir;
	List<FileInfo> fileList = [];

	late List<LabelInfo> labels;

	Future<void> init() async {
		// load config files first
		Directory dir = await getApplicationDocumentsDirectory();
		File f = File('${dir.path}/config.txt');
		if (await f.exists()) {
			homeDir = await f.readAsString();
		} else {
			homeDir = '/storage/emulated/0';
			setHomeDirectory(homeDir);
		}
		crntDir = homeDir;

		// load database
		await _db.init();
		labels = await _db.selectLabels();
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

	Future<bool> createLabel(String name, int color) async {
		if (labels.any((l) => l.name == name) || _db.hasSQLInjection(name) || name.isEmpty) return false;
		await _db.insertLabel(name, color);
		labels.add(LabelInfo(name, color));
		return true;
	}

	Future<void> assignLabelToFiles(String label, List<FileInfo> paths) async {
		_db.insertMatches(label, paths);
	}

}

class _DatabaseHandler {

	late Database _db;
	
	Future<void> init() async {
		Directory dir = await getApplicationDocumentsDirectory();
		_db = await openDatabase('$dir/userdata.db');
		_createTablesIfNotExists();
	}

	Future<void> _createTablesIfNotExists() async {
		await _db.execute('CREATE TABLE IF NOT EXISTS labels'
			' (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, color INT UNSIGNED);');
		await _db.execute('CREATE TABLE IF NOT EXISTS songs'
			' (id INTEGER PRIMARY KEY AUTOINCREMENT, path TEXT);');
		await _db.execute('CREATE TABLE IF NOT EXISTS matches'
			' (sid INTEGER, lid INTEGER, FOREIGN KEY (sid) REFERENCES songs(id) ON DELETE CASCADE);');
	}

	bool hasSQLInjection(String sql) {
		return sql.contains("'") || sql.contains('"') || sql.contains('\\');
	}

	Future<List<LabelInfo>> selectLabels() async {
		List<Map> records = await _db.rawQuery('SELECT name, color FROM labels');
		return records.map((m) => LabelInfo(m['name'].toString(), m['color'] as int)).toList();
	}

	Future<void> insertLabel(String name, int color) async {
		await _db.execute('INSERT INTO labels (name, color) VALUES (\'$name\', $color);');
	}

	Future<void> insertMatches(String label, List<FileInfo> fis) async {
		List<Map> m = await _db.rawQuery('SELECT id FROM labels WHERE name == \'$label\';');
		int lid = m[0]['id'] as int;
		for (final fi in fis) {
			String path = fi.path;
			m = await _db.rawQuery('SELECT id FROM songs WHERE path == \'$path\';');
			if (m.isEmpty) {
				await _db.execute('INSERT INTO songs (path) VALUES (\'$path\');');
				m = await _db.rawQuery('SELECT id FROM songs WHERE path == \'$path\';');
			}
			int sid = m[0]['id'] as int;
			if ((await _db.rawQuery('SELECT * FROM matches WHERE sid == $sid AND lid == $lid;')).isEmpty) {
				await _db.execute('INSERT INTO matches VALUES ($sid, $lid);');
			}
		}
	}

}
