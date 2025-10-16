import 'dart:convert';
import 'dart:ui' as ui;

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../../canvas_screen/presentation/view/widgets/hand_writing_painter.dart';

part 'convert_canvas_b64_state.dart';

class ConvertCanvasB64Cubit extends Cubit<ConvertCanvasB64State> {
  ConvertCanvasB64Cubit(
      /*this.paths, this.currentPath, this.isErasing, this.context*/)
      : super(ConvertCanvasB64Initial());
  // final List<MapEntry<Path, Paint>> paths;
  // final Path currentPath;
  // final bool isErasing;
  // final BuildContext context;

  // Future<void> convertCanvasToB64(
  //     BuildContext context,
  //     List<MapEntry<Path, Paint>> paths,
  //     Path currentPath,
  //     bool isErasing,
  //     List<dynamic> procedures,
  //     String strokesJson) async {
  //   try {
  //     emit(CanvasLoading());
  //     final img =
  //         await _getRenderedImage(context, paths, currentPath, isErasing);
  //     final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
  //     final imgBase64 = base64Encode(pngBytes!.buffer.asUint8List());
  //     emit(CanvasConversionSuccess(imgBase64, procedures, strokesJson));
  //   } catch (e) {
  //     emit(CanvasConversionError(
  //         "Failed to convert canvas: ${e.toString()}")); // Emit error state
  //   }
  // }

  // Future<ui.Image> _getRenderedImage(
  //     BuildContext context,
  //     List<MapEntry<Path, Paint>> paths,
  //     Path currentPath,
  //     bool isErasing) async {
  //   final size = context.size;
  //   if (size == null) throw Exception("Canvas size is null.");

  //   ui.PictureRecorder recorder = ui.PictureRecorder();
  //   Canvas canvas = Canvas(recorder);
  //   final painter = HandwritingPainter(
  //       paths,
  //       currentPath,
  //       isErasing,
  //       Paint()
  //         ..color = Colors.black
  //         ..strokeWidth = 2.5
  //         ..style = PaintingStyle.stroke
  //         ..strokeCap = StrokeCap.round);
  //   painter.paint(canvas, size);

  //   return recorder
  //       .endRecording()
  //       .toImage(size.width.floor(), size.height.floor());
  // }

  // Future<ui.Image> get rendered {
  //   var size = context.size;
  //   if (size == null) throw Exception("Canvas size is null.");
  //   ui.PictureRecorder recorder = ui.PictureRecorder();
  //   Canvas canvas = Canvas(recorder);
  //   final painter = HandwritingPainter(paths, currentPath, isErasing);
  //   painter.paint(canvas, size);
  //   return recorder
  //       .endRecording()
  //       .toImage(size.width.floor(), size.height.floor());
  // }
}
