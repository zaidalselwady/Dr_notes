part of 'convert_canvas_b64_cubit.dart';

@immutable
sealed class ConvertCanvasB64State {}

final class ConvertCanvasB64Initial extends ConvertCanvasB64State {}

class CanvasLoading extends ConvertCanvasB64State {}

class CanvasConversionSuccess extends ConvertCanvasB64State {
  final String base64Image;
  final List<dynamic> procedures;

  CanvasConversionSuccess(this.base64Image, this.procedures);
}

class CanvasConversionError extends ConvertCanvasB64State {
  final String errorMessage;
  CanvasConversionError(this.errorMessage);
}
