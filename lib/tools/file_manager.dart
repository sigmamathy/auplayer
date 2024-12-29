import 'dart:io';
import 'package:collection/collection.dart';
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
	LabelInfo? crntLabel;
	List<FileInfo> labelItems = [];

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

	Future<void> setCurrentLabel(String? name) async {
		crntLabel = labels.firstWhereOrNull((l) => l.name == name);
		if (crntLabel == null) {
			labelItems.clear();
			return;
		}
		labelItems = await _db.findMatches(name!);
	}

	Future<bool> createLabel(String name, int color) async {
		if (labels.any((l) => l.name == name) || name.isEmpty) return false;
		await _db.insertLabel(name, color);
		labels.add(LabelInfo(name, color));
		labels.sort((a, b) => a.name.compareTo(b.name));
		return true;
	}

	Future<bool> editLabel(LabelInfo ol, LabelInfo nl) async {
		if (labels.any((l) => ol.name != nl.name && l.name == nl.name) || nl.name.isEmpty) return false;
		await _db.updateLabel(ol, nl);
		final li = labels.firstWhere((l) => l.name == ol.name);
		li.name = nl.name;
		li.color = nl.color;
		labels.sort((a, b) => a.name.compareTo(b.name));
		return true;
	}

	Future<void> deleteLabel(String name) async {
		await _db.deleteLabel(name);
		labels.removeWhere((l) => l.name == name);
	}

	Future<void> assignLabelToFiles(String label, List<FileInfo> paths) async => _db.insertMatches(label, paths);

	Future<void> removeLabelFromFiles(String label, List<FileInfo> files) async => _db.deleteMatches(label, files);

	Future<Map<String, bool?>> labelsContainFiles(List<FileInfo> files) async {
		Map<String, bool?> ret = {};
		for (final li in labels) {
			List<FileInfo> matches = await _db.findMatches(li.name);
			int count = 0;
			for (final fi in files) {
				if (matches.any((f) => f.path == fi.path)) {
					count++;
				}
			}
			ret[li.name] = (count == files.length ? true : (count == 0 ? false : null));
		}
		return ret;
	}
}

class _DatabaseHandler {

	late Database _db;
	
	Future<void> init() async {
		Directory dir = await getApplicationDocumentsDirectory();
		_db = await openDatabase('$dir/userdata.db');
		await _createTablesIfNotExists();
	}

	Future<void> _createTablesIfNotExists() async {
		await _db.execute('PRAGMA foreign_keys = ON;');
		await _db.execute('CREATE TABLE IF NOT EXISTS labels (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, color INT);');
		await _db.execute('CREATE TABLE IF NOT EXISTS songs (id INTEGER PRIMARY KEY AUTOINCREMENT, path TEXT);');
		await _db.execute('CREATE TABLE IF NOT EXISTS matches (sid INTEGER, lid INTEGER, '
		'FOREIGN KEY (sid) REFERENCES songs(id) ON DELETE CASCADE, FOREIGN KEY (lid) REFERENCES labels(id) ON DELETE CASCADE);');
	}

	Future<List<LabelInfo>> selectLabels() async {
		List<Map> records = await _db.rawQuery('SELECT name, color FROM labels');
		final r = records.map((m) => LabelInfo(m['name'].toString(), m['color'] as int)).toList();
		r.sort((a, b) => a.name.compareTo(b.name));
		return r;
	}

	Future<void> insertLabel(String name, int color) async {
		name = _preventSQLInjection(name);
		await _db.execute('INSERT INTO labels (name, color) VALUES (\'$name\', $color);');
	}

	Future<void> updateLabel(LabelInfo ol, LabelInfo nl) async {
		ol.name = _preventSQLInjection(ol.name);
		nl.name = _preventSQLInjection(nl.name);
		await _db.execute('UPDATE labels SET name = \'${nl.name}\', color = ${nl.color} WHERE name = \'${ol.name}\'');
	}

	Future<void> deleteLabel(String name) async {
		int id = (await _db.rawQuery('SELECT id FROM labels WHERE name = \'$name\';'))[0]['id'] as int;
		await _db.execute('DELETE FROM labels WHERE id == $id;');
	}

	Future<void> insertMatches(String label, List<FileInfo> fis) async {
		label = _preventSQLInjection(label);
		List<Map> m = await _db.rawQuery('SELECT id FROM labels WHERE name == \'$label\';');
		int lid = m[0]['id'] as int;
		for (final fi in fis) {
			String path = fi.path;
			path = _preventSQLInjection(path);
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
	
	Future<void> deleteMatches(String label, List<FileInfo> fis) async {
		label = _preventSQLInjection(label);
		List<Map> m = await _db.rawQuery('SELECT id FROM labels WHERE name == \'$label\';');
		int lid = m[0]['id'] as int;
		for (final fi in fis) {
			String path = fi.path;
			path = _preventSQLInjection(path);
			m = await _db.rawQuery('SELECT id FROM songs WHERE path == \'$path\';');
			if (m.isEmpty) continue;
			int sid = m[0]['id'] as int;
			await _db.execute('DELETE FROM matches WHERE sid == $sid AND lid == $lid;');
		}
	}

	Future<List<FileInfo>> findMatches(String label) async {
		label = _preventSQLInjection(label);
		List<FileInfo> result = [];
		List<Map> lm = await _db.rawQuery('SELECT id FROM labels WHERE name == \'$label\';');
		int lid = lm[0]['id'] as int;
		lm = await _db.rawQuery('SELECT sid FROM matches WHERE lid == $lid');
		for (final m in lm) {
			final sid = m['sid'] as int;
			String path = (await _db.rawQuery('SELECT path FROM songs WHERE id == $sid'))[0]['path'].toString();
			result.add(FileInfo(path, basename(path), false));
		}
		result.sort((a, b) => a.name.compareTo(b.name));
		return result;
	}

	String _preventSQLInjection(String s) => s.replaceAll("'", "''");
	
}
