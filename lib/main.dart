import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'album.dart';
import 'queue.dart';

void grantPermisson() async
{
	var status = await Permission.audio.request();
	if (status.isGranted) {
		// Permission granted, perform your tasks
		print('permission granted');
	} else {
		// Permission denied, handle accordingly
		print('permission denied');
	}
}

void main() async
{
	await AlbumPageState.refreshFiles();	
  runApp(
		MaterialApp(
			debugShowCheckedModeBanner: false,
			initialRoute: '/album',
			routes: {
				'/album': (ctx) => AlbumPage(),
				'/queue': (ctx) => QueuePage(),
			}
		)
	);
}
