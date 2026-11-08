import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// A picture the user chose, already shrunk to a size that suits a shop screen.
class PickedImage {
  const PickedImage(this.bytes, this.name);
  final Uint8List bytes;
  final String name;
}

typedef ImagePickFn = Future<PickedImage?> Function(BuildContext context);

bool get _hasCamera => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

/// Picks from the gallery or files; on a phone the user may also take a photo. Replaced in tests.
final imagePickerProvider = Provider<ImagePickFn>((ref) => (context) async {
      var source = ImageSource.gallery;
      if (_hasCamera) {
        final choice = await showModalBottomSheet<ImageSource>(
          context: context,
          showDragHandle: true,
          builder: (c) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(leading: const Icon(Icons.photo_camera_rounded), title: const Text('Camera'), onTap: () => Navigator.pop(c, ImageSource.camera)),
              ListTile(leading: const Icon(Icons.photo_library_rounded), title: const Text('Gallery'), onTap: () => Navigator.pop(c, ImageSource.gallery)),
            ]),
          ),
        );
        if (choice == null) return null;
        source = choice;
      }
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (file == null) return null;
      return PickedImage(await file.readAsBytes(), file.name.isEmpty ? 'picture.jpg' : file.name);
    });
