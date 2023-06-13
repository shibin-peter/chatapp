import 'dart:io';
import 'package:abcd/video.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'camera.dart';

class Chat extends StatefulWidget {
  const Chat({Key? key}) : super(key: key);

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  late FilePickerResult? result;
  late PlatformFile file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('SHIBIN'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              // Handle the selected option here
              print('Selected option: $value');
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'time-last',
                  child: Text('Sort by time Last to First'),
                ),
                const PopupMenuItem(
                  value: 'time-first',
                  child: Text('cleare'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: 0, // Replace with the actual count of chat messages
                itemBuilder: (context, index) {
                  return const ListTile(
                    title: Text('Chat message'),
                  );
                },
              ),
            ),
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    keyboardType: TextInputType.multiline,
                    maxLines: 8,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () {
                    // Handle the send button pressed
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (builder) => bottomSheet(context),
                      backgroundColor: Colors.transparent,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // Handle the send button pressed
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget bottomSheet(BuildContext context) {
    return Container(
      height: 300,
      width: MediaQuery
          .of(context)
          .size
          .width,
      child: Card(
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                iconCreation(
                  Icons.camera_alt_rounded,
                  Colors.blue,
                  'Camera',
                      () async {
                    await availableCameras().then((value) =>
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) =>
                                CameraPage(cameras: value))));
                  },
                ),
                iconCreation(
                  Icons.photo,
                  Colors.green,
                  'Image',
                      () => pickFiles(FileType.image),
                ),
                iconCreation(
                  Icons.insert_drive_file,
                  Colors.orange,
                  'File',
                      () => pickFiles(FileType.any),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                iconCreation(
                  Icons.video_camera_front,
                  Colors.red,
                  'Video',
                      () async {
                    await availableCameras().then((value) =>
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) =>
                                Video(cameras: value))));
                  },
                ),
                iconCreation(
                  Icons.person,
                  Colors.purple,
                  'Contact',
                      () {
                    // Handle Contact icon tap
                  },
                ),
                iconCreation(
                  Icons.music_note,
                  Colors.yellow,
                  'Audio',
                      () => pickFiles(FileType.audio),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget iconCreation(IconData icon,
      Color color,
      String text,
      VoidCallback onTap,) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(text),
        ],
      ),
    );
  }

  Future<List<PlatformFile>?> pickFiles(FileType type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      allowCompression: true,
      type: type,
    );
    if (result != null) {
      List<File> files = result.paths.map((path) => File(path!)).toList();

      for (int i = 0; i < files.length; i++) {
        copyFile(files[i].path, '/storage/emulated/0/Download/abcd');
      }
      int len = files.length;
      if (result != null && len > 1) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(' $len FILES SELECTED '),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('SEND'),
                ),
              ],
            );
          },
        );
      }
    }
    else {
      print("No file selected");
    }
    return result?.files;
  }

//copy file from one destination to another
  void copyFile(String sourcePath, String destinationDirectory) {
    final File sourceFile = File(sourcePath);

    // Check if the source file exists
    if (!sourceFile.existsSync()) {
      print('Source file does not exist.');
      return;
    }

    // Extract the file name from the source path
    final String fileName = sourceFile.path.split('/').last;

    // Construct the destination path by combining the destination directory and the file name
    final String destinationPath = '$destinationDirectory/$fileName';

    // Check if the destination file already exists
    final File destinationFile = File(destinationPath);
    if (destinationFile.existsSync()) {
      print('Destination file already exists.');
      return;
    }

    try {
      // Read the content of the source file
      final List<int> content = sourceFile.readAsBytesSync();

      // Write the content to the destination file
      destinationFile.writeAsBytesSync(content);

      print('File copied successfully.');
    } catch (e) {
      print('An error occurred while copying the file: $e');
    }
  }
}