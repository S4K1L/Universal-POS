import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../i18n/lang.dart';
import '../theme/tokens.dart';

/// Camera scanning works in the browser and on Android, iOS and macOS. Elsewhere (Windows, Linux) the plugin has no
/// camera backend, so the buttons stay hidden and a USB/Bluetooth scanner typing into the search box does the job.
bool get cameraScanSupported => kIsWeb || const {TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS}.contains(defaultTargetPlatform);

const _formats = [
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.itf14,
  BarcodeFormat.itf2of5,
  BarcodeFormat.codabar,
  BarcodeFormat.qrCode,
  BarcodeFormat.dataMatrix,
];

/// Opens the camera, returns the first code it reads (or whatever was typed in), and closes. `null` if dismissed.
Future<String?> scanBarcode(BuildContext context, {String? title}) =>
    showDialog<String>(context: context, builder: (_) => _ScannerDialog(title: title));

/// Opens the camera and keeps it open, handing every new code to [onCode] — for ringing up a basket item after item.
/// [onCode] returns the line to show under the viewfinder (what was added, or why not) and whether it worked.
Future<void> scanBarcodes(BuildContext context, {required Future<ScanFeedback?> Function(String code) onCode, String? title}) =>
    showDialog<void>(context: context, builder: (_) => _ScannerDialog(title: title, onCode: onCode));

class ScanFeedback {
  const ScanFeedback(this.text, {this.ok = true});
  final String text;
  final bool ok;
}

class _ScannerDialog extends StatefulWidget {
  const _ScannerDialog({this.title, this.onCode});
  final String? title;
  final Future<ScanFeedback?> Function(String code)? onCode;

  @override
  State<_ScannerDialog> createState() => _ScannerDialogState();
}

class _ScannerDialogState extends State<_ScannerDialog> {
  final _controller = MobileScannerController(formats: _formats, detectionTimeoutMs: 250);
  final _typed = TextEditingController();
  bool _typing = false;
  bool _finished = false;
  bool _busy = false;
  String? _lastCode;
  DateTime _lastSeen = DateTime.fromMillisecondsSinceEpoch(0);
  ScanFeedback? _feedback;
  Timer? _clear;

  bool get _continuous => widget.onCode != null;
  bool get _hasTorch => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void dispose() {
    _clear?.cancel();
    _typed.dispose();
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.map((b) => b.rawValue).whereType<String>().where((c) => c.isNotEmpty).firstOrNull;
    if (code == null) return;
    final now = DateTime.now();
    final sameAsBefore = code == _lastCode && now.difference(_lastSeen).inMilliseconds < 1200; // still in front of the lens
    _lastSeen = now;
    if (sameAsBefore) return;
    _lastCode = code;
    unawaited(_accept(code));
  }

  Future<void> _accept(String code) async {
    if (_finished || _busy) return;
    final handler = widget.onCode;
    if (handler == null) {
      _finished = true;
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context, code);
      return;
    }
    _busy = true;
    try {
      final fb = await handler(code);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      setState(() => _feedback = fb);
      _clear?.cancel();
      _clear = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _feedback = null);
      });
    } finally {
      _busy = false;
    }
  }

  void _submitTyped() {
    final code = _typed.text.trim();
    if (code.isEmpty) return;
    _typed.clear();
    unawaited(_accept(code));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final phone = MediaQuery.sizeOf(context).width < 600;
    final body = Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
        child: Row(children: [
          Icon(Icons.qr_code_scanner_rounded, color: t.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.title ?? context.tr('Scan a barcode'), style: tt.titleMedium)),
          if (_hasTorch)
            IconButton(
              tooltip: context.tr('Torch'),
              icon: const Icon(Icons.flashlight_on_rounded),
              onPressed: () async {
                try {
                  await _controller.toggleTorch();
                } catch (_) {}
              },
            ),
          IconButton(
            tooltip: context.tr('Switch camera'),
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: () async {
              try {
                await _controller.switchCamera();
              } catch (_) {}
            },
          ),
          IconButton(tooltip: context.tr('Done'), icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
        ]),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(fit: StackFit.expand, children: [
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                errorBuilder: (context, error) => _CameraProblem(onType: () => setState(() => _typing = true)),
              ),
              IgnorePointer(
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.72,
                    heightFactor: 0.42,
                    child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(16))),
                  ),
                ),
              ),
              if (_feedback != null)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Material(
                    color: _feedback!.ok ? t.success : t.danger,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(children: [
                        Icon(_feedback!.ok ? Icons.check_circle_rounded : Icons.error_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_feedback!.text, style: tt.bodyMedium!.copyWith(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        child: _typing
            ? Row(children: [
                Expanded(
                  child: TextField(
                    controller: _typed,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitTyped(),
                    decoration: InputDecoration(labelText: context.tr('Barcode'), isDense: true),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(onPressed: _submitTyped, child: Text(context.tr('Use this code'))),
              ])
            : Row(children: [
                Expanded(child: Text(context.tr(_continuous ? 'Point the camera at each item. Scanning stays on until you close it.' : 'Point the camera at a barcode or QR code.'), style: tt.bodySmall!.copyWith(color: t.muted))),
                TextButton(onPressed: () => setState(() => _typing = true), child: Text(context.tr('Type the code'))),
              ]),
      ),
    ]);
    return phone
        ? Dialog.fullscreen(child: SafeArea(child: body))
        : Dialog(
            insetPadding: const EdgeInsets.all(24),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680), child: body),
          );
  }
}

class _CameraProblem extends StatelessWidget {
  const _CameraProblem({required this.onType});
  final VoidCallback onType;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.no_photography_rounded, color: Colors.white70, size: 44),
            const SizedBox(height: 12),
            Text(
              context.tr('The camera is not available. Allow camera access in your browser or system settings, or type the code.'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onType,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: t.outline)),
              child: Text(context.tr('Type the code')),
            ),
          ]),
        ),
      ),
    );
  }
}
