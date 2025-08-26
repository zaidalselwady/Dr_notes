import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vector_math/vector_math.dart' as vmath;

// ==================== ENUMS ====================
enum DrawingTool {
  pen,
  eraser,
  circle,
  arrow,
  line,
  rectangle,
  text,
  stamp,
  ruler,
  highlighter,
  freeform
}

enum DentalTemplate {
  none,
  adultOdontogram,
  pediatricOdontogram,
  periodontalChart,
  oralCavityFrontal,
  oralCavityLateral,
  bitewing,
  panoramic
}

enum LayerType {
  background('Background', 0),
  drawing('Drawing', 1),
  annotation('Annotation', 2),
  overlay('Overlay', 3),
  template('Template', -1);

  const LayerType(this.displayName, this.order);
  final String displayName;
  final int order;
}

// ==================== DATA MODELS ====================
abstract class DrawingElement {
  final String id;
  final DrawingTool tool;
  final Paint paint;
  final LayerType layer;
  final DateTime timestamp;

  DrawingElement({
    required this.id,
    required this.tool,
    required this.paint,
    required this.layer,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson();

  static DrawingElement fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'path':
        return PathElement.fromJson(json);
      case 'shape':
        return ShapeElement.fromJson(json);
      case 'stamp':
        return StampElement.fromJson(json);
      case 'text':
        return TextElement.fromJson(json);
      default:
        throw Exception('Unknown element type: ${json['type']}');
    }
  }
}

class PathElement extends DrawingElement {
  final Path path;
  final List<Offset> points;

  PathElement({
    required super.id,
    required super.tool,
    required super.paint,
    required super.layer,
    required this.path,
    required this.points,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'path',
        'id': id,
        'tool': tool.name,
        'layer': layer.name,
        'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        'color': paint.color.value,
        'strokeWidth': paint.strokeWidth,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  static PathElement fromJson(Map<String, dynamic> json) {
    final points =
        (json['points'] as List).map((p) => Offset(p['x'], p['y'])).toList();
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    return PathElement(
      id: json['id'],
      tool: DrawingTool.values.byName(json['tool']),
      paint: Paint()
        ..color = Color(json['color'])
        ..strokeWidth = json['strokeWidth']
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
      layer: LayerType.values.byName(json['layer']),
      path: path,
      points: points,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}

class ShapeElement extends DrawingElement {
  final Offset startPoint;
  final Offset endPoint;
  final String? text;

  ShapeElement({
    required super.id,
    required super.tool,
    required super.paint,
    required super.layer,
    required this.startPoint,
    required this.endPoint,
    this.text,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'shape',
        'id': id,
        'tool': tool.name,
        'layer': layer.name,
        'startPoint': {'x': startPoint.dx, 'y': startPoint.dy},
        'endPoint': {'x': endPoint.dx, 'y': endPoint.dy},
        'text': text,
        'color': paint.color.value,
        'strokeWidth': paint.strokeWidth,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  static ShapeElement fromJson(Map<String, dynamic> json) => ShapeElement(
        id: json['id'],
        tool: DrawingTool.values.byName(json['tool']),
        paint: Paint()
          ..color = Color(json['color'])
          ..strokeWidth = json['strokeWidth']
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
        layer: LayerType.values.byName(json['layer']),
        startPoint: Offset(json['startPoint']['x'], json['startPoint']['y']),
        endPoint: Offset(json['endPoint']['x'], json['endPoint']['y']),
        text: json['text'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      );
}

class StampElement extends DrawingElement {
  final Offset position;
  final String symbol;
  final double size;
  final String description;

  StampElement({
    required super.id,
    required super.tool,
    required super.paint,
    required super.layer,
    required this.position,
    required this.symbol,
    required this.size,
    required this.description,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'stamp',
        'id': id,
        'tool': tool.name,
        'layer': layer.name,
        'position': {'x': position.dx, 'y': position.dy},
        'symbol': symbol,
        'size': size,
        'description': description,
        'color': paint.color.value,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  static StampElement fromJson(Map<String, dynamic> json) => StampElement(
        id: json['id'],
        tool: DrawingTool.values.byName(json['tool']),
        paint: Paint()
          ..color = Color(json['color'])
          ..style = PaintingStyle.fill,
        layer: LayerType.values.byName(json['layer']),
        position: Offset(json['position']['x'], json['position']['y']),
        symbol: json['symbol'],
        size: json['size'],
        description: json['description'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      );
}

class TextElement extends DrawingElement {
  final Offset position;
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  TextElement({
    required super.id,
    required super.tool,
    required super.paint,
    required super.layer,
    required this.position,
    required this.text,
    required this.fontSize,
    this.fontWeight = FontWeight.normal,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'id': id,
        'tool': tool.name,
        'layer': layer.name,
        'position': {'x': position.dx, 'y': position.dy},
        'text': text,
        'fontSize': fontSize,
        'fontWeight': fontWeight.index,
        'color': paint.color.value,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  static TextElement fromJson(Map<String, dynamic> json) => TextElement(
        id: json['id'],
        tool: DrawingTool.values.byName(json['tool']),
        paint: Paint()..color = Color(json['color']),
        layer: LayerType.values.byName(json['layer']),
        position: Offset(json['position']['x'], json['position']['y']),
        text: json['text'],
        fontSize: json['fontSize'],
        fontWeight: FontWeight.values[json['fontWeight']],
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      );
}

// ==================== SERVICES ====================
class CanvasService {
  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  static Future<String> exportToBase64(GlobalKey canvasKey) async {
    try {
      final RenderRepaintBoundary boundary =
          canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      return base64Encode(pngBytes);
    } catch (e) {
      throw Exception('Failed to export canvas: $e');
    }
  }

  static bool isPointNearPath(Path path, Offset point, double tolerance) {
    final bounds = path.getBounds();
    return bounds.inflate(tolerance).contains(point);
  }

  static bool isPointNearElement(
      DrawingElement element, Offset point, double tolerance) {
    if (element is PathElement) {
      return isPointNearPath(element.path, point, tolerance);
    } else if (element is ShapeElement) {
      final distance1 = (element.startPoint - point).distance;
      final distance2 = (element.endPoint - point).distance;
      return distance1 < tolerance || distance2 < tolerance;
    } else if (element is StampElement) {
      return (element.position - point).distance < tolerance;
    } else if (element is TextElement) {
      return (element.position - point).distance < tolerance;
    }
    return false;
  }
}

class DentalConstants {
  static const Map<String, Color> dentalColors = {
    'Black': Colors.black,
    'Red': Colors.red,
    'Blue': Colors.blue,
    'Green': Colors.green,
    'Yellow': Colors.yellow,
    'Orange': Colors.orange,
    'Purple': Colors.purple,
    'Brown': Color(0xFF8B4513),
    'Pink': Colors.pink,
    'Cyan': Colors.cyan,
  };

  static const Map<String, String> dentalSymbols = {
    'Extraction': '✗',
    'Missing': '□',
    'Crown': '♔',
    'Root Canal': '⚡',
    'Cavity': '●',
    'Filling': '■',
    'Implant': '⚈',
    'Bridge': '═',
    'Mesial': '/',
    'Distal': '\\',
    'Buccal': ')',
    'Lingual': '(',
    'Occlusal': '○',
    'Periapical': '◊',
    'Abscess': '※',
    'Fracture': '⚡',
  };

  static const List<String> adultTeeth = [
    '18',
    '17',
    '16',
    '15',
    '14',
    '13',
    '12',
    '11',
    '21',
    '22',
    '23',
    '24',
    '25',
    '26',
    '27',
    '28',
    '48',
    '47',
    '46',
    '45',
    '44',
    '43',
    '42',
    '41',
    '31',
    '32',
    '33',
    '34',
    '35',
    '36',
    '37',
    '38'
  ];

  static const List<String> pediatricTeeth = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T'
  ];
}

// ==================== STATE MANAGEMENT ====================
class CanvasState extends ChangeNotifier {
  final List<DrawingElement> _elements = [];
  final List<List<DrawingElement>> _undoStack = [];
  final List<List<DrawingElement>> _redoStack = [];
  final Map<LayerType, bool> _layerVisibility = {};

  DrawingTool _currentTool = DrawingTool.pen;
  LayerType _currentLayer = LayerType.drawing;
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 2.5;
  double _currentFontSize = 16.0;
  DentalTemplate _currentTemplate = DentalTemplate.none;
  DateTime _selectedDateTime = DateTime.now();
  bool _showGrid = false;
  bool _autoSave = true;

  // Getters
  List<DrawingElement> get elements => List.unmodifiable(_elements);
  List<DrawingElement> get visibleElements =>
      _elements.where((e) => _layerVisibility[e.layer] == true).toList();

  DrawingTool get currentTool => _currentTool;
  LayerType get currentLayer => _currentLayer;
  Color get currentColor => _currentColor;
  double get currentStrokeWidth => _currentStrokeWidth;
  double get currentFontSize => _currentFontSize;
  DentalTemplate get currentTemplate => _currentTemplate;
  DateTime get selectedDateTime => _selectedDateTime;
  bool get showGrid => _showGrid;
  bool get autoSave => _autoSave;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  Map<LayerType, bool> get layerVisibility =>
      Map.unmodifiable(_layerVisibility);

  CanvasState() {
    _initializeLayerVisibility();
  }

  void _initializeLayerVisibility() {
    for (final layer in LayerType.values) {
      _layerVisibility[layer] = true;
    }
  }

  void _saveStateForUndo() {
    _undoStack.add(_elements.map((e) => e).toList());
    _redoStack.clear();
    if (_undoStack.length > 30) {
      _undoStack.removeAt(0);
    }
  }

  // Tool and settings methods
  void setCurrentTool(DrawingTool tool) {
    if (_currentTool != tool) {
      _currentTool = tool;
      notifyListeners();
    }
  }

  void setCurrentLayer(LayerType layer) {
    if (_currentLayer != layer) {
      _currentLayer = layer;
      notifyListeners();
    }
  }

  void setCurrentColor(Color color) {
    if (_currentColor != color) {
      _currentColor = color;
      notifyListeners();
    }
  }

  void setCurrentStrokeWidth(double width) {
    if (_currentStrokeWidth != width) {
      _currentStrokeWidth = width;
      notifyListeners();
    }
  }

  void setCurrentFontSize(double size) {
    if (_currentFontSize != size) {
      _currentFontSize = size;
      notifyListeners();
    }
  }

  void setCurrentTemplate(DentalTemplate template) {
    if (_currentTemplate != template) {
      _currentTemplate = template;
      notifyListeners();
    }
  }

  void setSelectedDateTime(DateTime dateTime) {
    if (_selectedDateTime != dateTime) {
      _selectedDateTime = dateTime;
      notifyListeners();
    }
  }

  void toggleGrid() {
    _showGrid = !_showGrid;
    notifyListeners();
  }

  void toggleAutoSave() {
    _autoSave = !_autoSave;
    notifyListeners();
  }

  void toggleLayerVisibility(LayerType layer) {
    _layerVisibility[layer] = !(_layerVisibility[layer] ?? true);
    notifyListeners();
  }

  // Element management
  void addElement(DrawingElement element) {
    _saveStateForUndo();
    _elements.add(element);
    notifyListeners();

    if (_autoSave) {
      _autoSaveCanvas();
    }
  }

  void removeElement(String id) {
    _saveStateForUndo();
    _elements.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void clearCanvas() {
    if (_elements.isNotEmpty) {
      _saveStateForUndo();
      _elements.clear();
      notifyListeners();
    }
  }

  void clearLayer(LayerType layer) {
    final layerElements = _elements.where((e) => e.layer == layer).toList();
    if (layerElements.isNotEmpty) {
      _saveStateForUndo();
      _elements.removeWhere((e) => e.layer == layer);
      notifyListeners();
    }
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_elements.map((e) => e).toList());
      _elements.clear();
      if (_undoStack.isNotEmpty) {
        _elements.addAll(_undoStack.removeLast());
      }
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_elements.map((e) => e).toList());
      _elements.clear();
      _elements.addAll(_redoStack.removeLast());
      notifyListeners();
    }
  }

  void eraseAtPoint(Offset point, double radius) {
    final elementsToRemove = <DrawingElement>[];

    for (final element in _elements) {
      if (CanvasService.isPointNearElement(element, point, radius)) {
        elementsToRemove.add(element);
      }
    }

    if (elementsToRemove.isNotEmpty) {
      _saveStateForUndo();
      _elements.removeWhere((e) => elementsToRemove.contains(e));
      notifyListeners();
    }
  }

  Paint createPaint({Color? color, double? strokeWidth, PaintingStyle? style}) {
    return Paint()
      ..color = color ?? _currentColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth ?? _currentStrokeWidth
      ..style = style ?? PaintingStyle.stroke;
  }

  void _autoSaveCanvas() {
    // Implement auto-save logic here
    // This could save to local storage, send to server, etc.
  }

  // Serialization
  Map<String, dynamic> toJson() => {
        'elements': _elements.map((e) => e.toJson()).toList(),
        'currentTool': _currentTool.name,
        'currentLayer': _currentLayer.name,
        'currentColor': _currentColor.value,
        'currentStrokeWidth': _currentStrokeWidth,
        'currentFontSize': _currentFontSize,
        'currentTemplate': _currentTemplate.name,
        'selectedDateTime': _selectedDateTime.millisecondsSinceEpoch,
        'layerVisibility': _layerVisibility.map((k, v) => MapEntry(k.name, v)),
        'showGrid': _showGrid,
        'autoSave': _autoSave,
      };

  void fromJson(Map<String, dynamic> json) {
    _elements.clear();
    _elements.addAll(
      (json['elements'] as List)
          .map((e) => DrawingElement.fromJson(e))
          .toList(),
    );

    _currentTool = DrawingTool.values.byName(json['currentTool']);
    _currentLayer = LayerType.values.byName(json['currentLayer']);
    _currentColor = Color(json['currentColor']);
    _currentStrokeWidth = json['currentStrokeWidth'];
    _currentFontSize = json['currentFontSize'];
    _currentTemplate = DentalTemplate.values.byName(json['currentTemplate']);
    _selectedDateTime =
        DateTime.fromMillisecondsSinceEpoch(json['selectedDateTime']);
    _showGrid = json['showGrid'];
    _autoSave = json['autoSave'];

    final layerVisibilityJson = json['layerVisibility'] as Map<String, dynamic>;
    for (final entry in layerVisibilityJson.entries) {
      _layerVisibility[LayerType.values.byName(entry.key)] = entry.value;
    }

    notifyListeners();
  }
}

// ==================== MAIN WIDGET ====================
class HandwritingScreen2 extends StatefulWidget {
  const HandwritingScreen2({super.key, required this.patientId});
  final int patientId;

  @override
  State<HandwritingScreen2> createState() => _HandwritingScreen2State();
}

class _HandwritingScreen2State extends State<HandwritingScreen2>
    with TickerProviderStateMixin {
  late final CanvasState _canvasState;
  final GlobalKey _canvasKey = GlobalKey();
  final TransformationController _transformationController =
      TransformationController();

  // Current drawing state
  Path? _currentPath;
  List<Offset> _currentPoints = [];
  Offset? _startPoint;
  Offset? _currentPoint;
  bool _isDrawing = false;

  // Animation controllers
  late AnimationController _toolPanelController;
  late Animation<double> _toolPanelAnimation;

  // UI state
  bool _showToolPanel = false;

  @override
  void initState() {
    super.initState();
    _canvasState = CanvasState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _toolPanelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toolPanelAnimation = CurvedAnimation(
      parent: _toolPanelController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _toolPanelController.dispose();
    _canvasState.dispose();
    super.dispose();
  }

  // ==================== COORDINATE TRANSFORMATION ====================
  Offset _transformGlobalToCanvas(Offset globalPosition) {
    // Transform the global position to canvas coordinates considering zoom and pan
    final Matrix4 transform = _transformationController.value;
    final vmath.Matrix4 vTransform = vmath.Matrix4.fromList(transform.storage);
    final vmath.Matrix4 inverse = vmath.Matrix4.inverted(vTransform);
    final vmath.Vector3 transformed = inverse.transform3(vmath.Vector3(globalPosition.dx, globalPosition.dy, 0));
    return Offset(transformed.x, transformed.y);
  }

  // ==================== GESTURE HANDLERS ====================
  void _handlePanStart(DragStartDetails details) {
    // Transform coordinates to account for zoom/pan
    final canvasPosition = _transformGlobalToCanvas(details.localPosition);
    
    _startPoint = canvasPosition;
    _currentPoint = canvasPosition;
    _isDrawing = true;

    switch (_canvasState.currentTool) {
      case DrawingTool.pen:
      case DrawingTool.highlighter:
        _currentPath = Path();
        _currentPoints = [canvasPosition];
        _currentPath!.moveTo(canvasPosition.dx, canvasPosition.dy);
        break;
      case DrawingTool.eraser:
        _canvasState.eraseAtPoint(canvasPosition, 20.0);
        break;
      default:
        // For shape tools, we'll handle in onPanEnd
        break;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;

    // Transform coordinates to account for zoom/pan
    final canvasPosition = _transformGlobalToCanvas(details.localPosition);
    _currentPoint = canvasPosition;

    setState(() {
      switch (_canvasState.currentTool) {
        case DrawingTool.pen:
        case DrawingTool.highlighter:
          _currentPoints.add(canvasPosition);
          _currentPath?.lineTo(canvasPosition.dx, canvasPosition.dy);
          break;
        case DrawingTool.eraser:
          _canvasState.eraseAtPoint(canvasPosition, 20.0);
          break;
        default:
          // For shapes, we'll draw preview in the painter
          break;
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isDrawing || _startPoint == null) return;

    switch (_canvasState.currentTool) {
      case DrawingTool.pen:
      case DrawingTool.highlighter:
        if (_currentPath != null && _currentPoints.isNotEmpty) {
          Paint paint = _canvasState.createPaint();
          if (_canvasState.currentTool == DrawingTool.highlighter) {
            paint = paint
              ..color = _canvasState.currentColor.withOpacity(0.3)
              ..strokeWidth = _canvasState.currentStrokeWidth * 2;
          }

          _canvasState.addElement(PathElement(
            id: CanvasService.generateId(),
            tool: _canvasState.currentTool,
            paint: paint,
            layer: _canvasState.currentLayer,
            path: _currentPath!,
            points: _currentPoints,
          ));
        }
        break;

      case DrawingTool.circle:
      case DrawingTool.rectangle:
      case DrawingTool.line:
      case DrawingTool.arrow:
      case DrawingTool.ruler:
        if (_currentPoint != null) {
          _canvasState.addElement(ShapeElement(
            id: CanvasService.generateId(),
            tool: _canvasState.currentTool,
            paint: _canvasState.createPaint(),
            layer: _canvasState.currentLayer,
            startPoint: _startPoint!,
            endPoint: _currentPoint!,
          ));
        }
        break;

      default:
        break;
    }

    _isDrawing = false;
    _currentPath = null;
    _currentPoints.clear();
    _startPoint = null;
    _currentPoint = null;
    setState(() {});
  }

  void _handleTap(TapUpDetails details) {
    // Transform coordinates to account for zoom/pan
    final canvasPosition = _transformGlobalToCanvas(details.localPosition);
    
    switch (_canvasState.currentTool) {
      case DrawingTool.text:
        _showTextDialog(canvasPosition);
        break;
      case DrawingTool.stamp:
        _showStampDialog(canvasPosition);
        break;
      default:
        break;
    }
  }

  // ==================== DIALOGS ====================
  void _showTextDialog(Offset position) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Text'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Enter text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Size: '),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: _canvasState,
                      builder: (context, child) => Slider(
                        value: _canvasState.currentFontSize,
                        min: 8,
                        max: 48,
                        divisions: 20,
                        label: _canvasState.currentFontSize.round().toString(),
                        onChanged: (value) {
                          _canvasState.setCurrentFontSize(value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              // Color picker
              ListenableBuilder(
                listenable: _canvasState,
                builder: (context, child) => Wrap(
                  children: DentalConstants.dentalColors.entries
                      .take(8)
                      .map((entry) => GestureDetector(
                            onTap: () {
                              _canvasState.setCurrentColor(entry.value);
                            },
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: entry.value,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _canvasState.currentColor == entry.value
                                      ? Colors.black
                                      : Colors.grey,
                                  width: 2,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _canvasState.addElement(TextElement(
                    id: CanvasService.generateId(),
                    tool: DrawingTool.text,
                    paint: _canvasState.createPaint(),
                    layer: _canvasState.currentLayer,
                    position: position,
                    text: controller.text,
                    fontSize: _canvasState.currentFontSize,
                  ));
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStampDialog(Offset position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Symbol'),
        content: SizedBox(
          width: 350,
          height: 450,
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Symbols'),
                    Tab(text: 'Adult'),
                    Tab(text: 'Pediatric'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSymbolGrid(position, DentalConstants.dentalSymbols),
                      _buildToothGrid(
                          position, DentalConstants.adultTeeth, 'Tooth'),
                      _buildToothGrid(
                          position, DentalConstants.pediatricTeeth, 'Tooth'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSymbolGrid(Offset position, Map<String, String> symbols) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: symbols.length,
      itemBuilder: (context, index) {
        final entry = symbols.entries.elementAt(index);
        return Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              _addStamp(position, entry.value, entry.key);
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.value,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToothGrid(Offset position, List<String> teeth, String prefix) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: teeth.length,
      itemBuilder: (context, index) {
        final tooth = teeth[index];
        return Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          color: Colors.blue.withOpacity(0.1),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              _addStamp(position, tooth, '$prefix $tooth');
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tooth,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    prefix,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _addStamp(Offset position, String symbol, String description) {
    _canvasState.addElement(StampElement(
      id: CanvasService.generateId(),
      tool: DrawingTool.stamp,
      paint: _canvasState.createPaint(),
      layer: _canvasState.currentLayer,
      position: position,
      symbol: symbol,
      size: _canvasState.currentStrokeWidth * 4,
      description: description,
    ));
  }

  // ==================== UI BUILDERS ====================
  Widget _buildMainToolbar() {
    return ListenableBuilder(
      listenable: _canvasState,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isPhone = constraints.maxWidth < 600;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Primary tools group
                  Wrap(
                    spacing: 4,
                    children: [
                      _buildToolButton(
                        icon: Icons.undo,
                        onPressed: _canvasState.canUndo ? _canvasState.undo : null,
                        tooltip: 'Undo',
                        color: _canvasState.canUndo ? null : Colors.grey,
                      ),
                      _buildToolButton(
                        icon: Icons.redo,
                        onPressed: _canvasState.canRedo ? _canvasState.redo : null,
                        tooltip: 'Redo',
                        color: _canvasState.canRedo ? null : Colors.grey,
                      ),
                    ],
                  ),

                  // Current tool display
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isPhone ? 8 : 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getToolIcon(_canvasState.currentTool),
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        if (!isPhone) ...[
                          const SizedBox(width: 8),
                          Text(
                            _canvasState.currentTool.name.toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Stroke width slider
                  SizedBox(
                    width: isPhone ? 100 : 120,
                    height: 40,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isPhone)
                          Text(
                            'Size: ${_canvasState.currentStrokeWidth.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        Expanded(
                          child: Slider(
                            value: _canvasState.currentStrokeWidth,
                            min: 1.0,
                            max: 20.0,
                            divisions: 19,
                            onChanged: _canvasState.setCurrentStrokeWidth,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Color picker button
                  GestureDetector(
                    onTap: () => _showColorPicker(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _canvasState.currentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (!isPhone) const Spacer(),

                  // Layer indicator (only on tablets)
                  if (!isPhone)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _canvasState.currentLayer.displayName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),

                  // Action buttons
                  Wrap(
                    spacing: 4,
                    children: [
                      _buildToolButton(
                        icon: Icons.grid_on,
                        onPressed: _canvasState.toggleGrid,
                        tooltip: 'Toggle Grid',
                        isActive: _canvasState.showGrid,
                      ),
                      _buildToolButton(
                        icon: Icons.layers,
                        onPressed: _toggleToolPanel,
                        tooltip: 'Layers & Tools',
                      ),
                      _buildToolButton(
                        icon: Icons.clear_all,
                        onPressed: _canvasState.elements.isEmpty ? null : _showClearDialog,
                        tooltip: 'Clear Canvas',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    Color? color,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: color ?? (onPressed != null ? null : Colors.grey),
          iconSize: 20,
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: ListenableBuilder(
          listenable: _canvasState,
          builder: (context, child) => Wrap(
            children: DentalConstants.dentalColors.entries.map((entry) {
              final isSelected = _canvasState.currentColor == entry.value;
              return GestureDetector(
                onTap: () {
                  _canvasState.setCurrentColor(entry.value);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: entry.value,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Canvas'),
        content: const Text(
            'Are you sure you want to clear all drawings? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _canvasState.clearCanvas();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildSideToolPanel() {
    return AnimatedBuilder(
      animation: _toolPanelAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(-320 * (1 - _toolPanelAnimation.value), 0),
          child: Container(
            width: 320,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPanelHeader(),
                  _buildToolSelection(),
                  _buildLayerControls(),
                  _buildTemplateSelection(),
                  _buildAdvancedSettings(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPanelHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.palette,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Text(
            'Tools & Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _toggleToolPanel,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildToolSelection() {
    return ListenableBuilder(
      listenable: _canvasState,
      builder: (context, child) {
        return ExpansionTile(
          title: const Text('Drawing Tools'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: DrawingTool.values.length,
                itemBuilder: (context, index) {
                  final tool = DrawingTool.values[index];
                  final isSelected = _canvasState.currentTool == tool;

                  return Material(
                    elevation: isSelected ? 4 : 2,
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[100],
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _canvasState.setCurrentTool(tool),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getToolIcon(tool),
                            color: isSelected ? Colors.white : Colors.grey[700],
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tool.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLayerControls() {
    return ListenableBuilder(
      listenable: _canvasState,
      builder: (context, child) {
        return ExpansionTile(
          title: Text('Layers (${_canvasState.elements.length} elements)'),
          children: [
            ...LayerType.values.map((layer) {
              final elementCount =
                  _canvasState.elements.where((e) => e.layer == layer).length;
              final isVisible = _canvasState.layerVisibility[layer] ?? true;
              final isActive = _canvasState.currentLayer == layer;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  dense: true,
                  leading: IconButton(
                    onPressed: () => _canvasState.toggleLayerVisibility(layer),
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: isVisible ? null : Colors.grey,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        layer.displayName,
                        style: TextStyle(
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          elementCount.toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _canvasState.setCurrentLayer(layer),
                  trailing: elementCount > 0
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => _showClearLayerDialog(layer),
                        )
                      : null,
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildTemplateSelection() {
    return ListenableBuilder(
      listenable: _canvasState,
      builder: (context, child) {
        return ExpansionTile(
          title: const Text('Dental Templates'),
          children: [
            ...DentalTemplate.values.map((template) => ListTile(
                  dense: true,
                  leading: Icon(
                    _getTemplateIcon(template),
                    color: _canvasState.currentTemplate == template
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                  title: Text(_getTemplateName(template)),
                  selected: _canvasState.currentTemplate == template,
                  onTap: () => _canvasState.setCurrentTemplate(template),
                )),
          ],
        );
      },
    );
  }

  Widget _buildAdvancedSettings() {
    return ListenableBuilder(
      listenable: _canvasState,
      builder: (context, child) {
        return ExpansionTile(
          title: const Text('Settings'),
          children: [
            SwitchListTile(
              title: const Text('Auto-save'),
              subtitle: const Text('Automatically save changes'),
              value: _canvasState.autoSave,
              onChanged: (_) => _canvasState.toggleAutoSave(),
            ),
            SwitchListTile(
              title: const Text('Show Grid'),
              subtitle: const Text('Display grid overlay'),
              value: _canvasState.showGrid,
              onChanged: (_) => _canvasState.toggleGrid(),
            ),
            ListTile(
              leading: const Icon(Icons.zoom_out_map),
              title: const Text('Reset Zoom'),
              subtitle: const Text('Reset canvas zoom and position'),
              onTap: () {
                _transformationController.value = Matrix4.identity();
              },
            ),
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('Export Canvas'),
              subtitle: const Text('Save current work'),
              onTap: _exportCanvas,
            ),
          ],
        );
      },
    );
  }

  void _showClearLayerDialog(LayerType layer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear ${layer.displayName} Layer'),
        content: Text(
            'Are you sure you want to clear all elements from the ${layer.displayName} layer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _canvasState.clearLayer(layer);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear Layer'),
          ),
        ],
      ),
    );
  }

  void _toggleToolPanel() {
    setState(() {
      _showToolPanel = !_showToolPanel;
    });

    if (_showToolPanel) {
      _toolPanelController.forward();
    } else {
      _toolPanelController.reverse();
    }
  }

  // ==================== HELPER METHODS ====================
  IconData _getToolIcon(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.pen:
        return Icons.edit;
      case DrawingTool.eraser:
        return Icons.cleaning_services;
      case DrawingTool.circle:
        return Icons.radio_button_unchecked;
      case DrawingTool.arrow:
        return Icons.arrow_forward;
      case DrawingTool.line:
        return Icons.remove;
      case DrawingTool.rectangle:
        return Icons.crop_din;
      case DrawingTool.text:
        return Icons.text_fields;
      case DrawingTool.stamp:
        return Icons.star;
      case DrawingTool.ruler:
        return Icons.straighten;
      case DrawingTool.highlighter:
        return Icons.highlight;
      case DrawingTool.freeform:
        return Icons.gesture;
    }
  }

  IconData _getTemplateIcon(DentalTemplate template) {
    switch (template) {
      case DentalTemplate.none:
        return Icons.clear;
      case DentalTemplate.adultOdontogram:
        return Icons.grid_on;
      case DentalTemplate.pediatricOdontogram:
        return Icons.child_care;
      case DentalTemplate.periodontalChart:
        return Icons.timeline;
      case DentalTemplate.oralCavityFrontal:
        return Icons.face;
      case DentalTemplate.oralCavityLateral:
        return Icons.face_retouching_natural;
      case DentalTemplate.bitewing:
        return Icons.view_sidebar;
      case DentalTemplate.panoramic:
        return Icons.panorama;
    }
  }

  String _getTemplateName(DentalTemplate template) {
    switch (template) {
      case DentalTemplate.none:
        return 'None';
      case DentalTemplate.adultOdontogram:
        return 'Adult Odontogram';
      case DentalTemplate.pediatricOdontogram:
        return 'Pediatric Odontogram';
      case DentalTemplate.periodontalChart:
        return 'Periodontal Chart';
      case DentalTemplate.oralCavityFrontal:
        return 'Oral Cavity (Front)';
      case DentalTemplate.oralCavityLateral:
        return 'Oral Cavity (Side)';
      case DentalTemplate.bitewing:
        return 'Bitewing X-ray';
      case DentalTemplate.panoramic:
        return 'Panoramic X-ray';
    }
  }

  // ==================== ASYNC OPERATIONS ====================
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _canvasState.selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_canvasState.selectedDateTime),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _canvasState.setSelectedDateTime(newDateTime);
      }
    }
  }

  Future<void> _captureAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        final File imageFile = File(photo.path);
        final Uint8List imageBytes = await imageFile.readAsBytes();
        final String base64Image = base64Encode(imageBytes);

        // Here you would typically upload to your server
        _showSuccessMessage('Photo captured successfully');
      }
    } catch (e) {
      _showErrorMessage('Failed to capture image: ${e.toString()}');
    }
  }

  Future<void> _exportCanvas() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Exporting canvas...'),
            ],
          ),
        ),
      );

      final base64Image = await CanvasService.exportToBase64(_canvasKey);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSuccessMessage('Canvas exported successfully');
        _showExportDialog(base64Image);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorMessage('Failed to export canvas: ${e.toString()}');
      }
    }
  }

  void _showExportDialog(String base64Image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('Save to Gallery'),
              onTap: () {
                Navigator.pop(context);
                // Implement save to gallery
                _showSuccessMessage('Saved to gallery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // Implement sharing
                _showSuccessMessage('Sharing...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('Upload to Server'),
              onTap: () {
                Navigator.pop(context);
                _uploadToServer(base64Image);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadToServer(String base64Image) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Uploading...'),
            ],
          ),
        ),
      );

      // Simulate upload process
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSuccessMessage('Canvas uploaded successfully');

        // Return to previous screen after successful upload
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorMessage('Failed to upload canvas: ${e.toString()}');
      }
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  // ==================== BUILD METHOD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 2,
        title: Text(
          'Patient ${widget.patientId} Dental Notes',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _toggleToolPanel,
        ),
        actions: [
          ListenableBuilder(
            listenable: _canvasState,
            builder: (context, child) => TextButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(_formatDateTime(_canvasState.selectedDateTime)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          IconButton(
            onPressed: _captureAndUploadImage,
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Take Photo',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildMainToolbar(),
              Expanded(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.3,
                  maxScale: 5.0,
                  boundaryMargin: const EdgeInsets.all(100),
                  // Disable panning when drawing tools are active
                  panEnabled: !_isDrawing && 
                    ![DrawingTool.pen, DrawingTool.highlighter, DrawingTool.eraser]
                      .contains(_canvasState.currentTool),
                  child: GestureDetector(
                    onPanStart: _handlePanStart,
                    onPanUpdate: _handlePanUpdate,
                    onPanEnd: _handlePanEnd,
                    onTapUp: _handleTap,
                    child: Container(
                      key: _canvasKey,
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.white,
                      child: ListenableBuilder(
                        listenable: _canvasState,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: EnhancedDentalPainter(
                              elements: _canvasState.visibleElements,
                              currentPath: _currentPath,
                              currentTool: _canvasState.currentTool,
                              currentPaint: _canvasState.createPaint(),
                              startPoint: _startPoint,
                              currentPoint: _currentPoint,
                              template: _canvasState.currentTemplate,
                              showGrid: _canvasState.showGrid,
                              isDrawing: _isDrawing,
                            ),
                            size: Size.infinite,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showToolPanel) _buildSideToolPanel(),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _canvasState,
        builder: (context, child) {
          return _canvasState.elements.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => _uploadToServer(''),
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Notes'),
                  backgroundColor: Theme.of(context).primaryColor,
                )
              : FloatingActionButton(
                  onPressed: () =>
                      _showErrorMessage('No notes available to upload'),
                  backgroundColor: Colors.grey,
                  child: const Icon(Icons.upload),
                );
        },
      ),
    );
  }
}


// ==================== ENHANCED PAINTER ====================
class EnhancedDentalPainter extends CustomPainter {
  final List<DrawingElement> elements;
  final Path? currentPath;
  final DrawingTool currentTool;
  final Paint currentPaint;
  final Offset? startPoint;
  final Offset? currentPoint;
  final DentalTemplate template;
  final bool showGrid;
  final bool isDrawing;

  EnhancedDentalPainter({
    required this.elements,
    this.currentPath,
    required this.currentTool,
    required this.currentPaint,
    this.startPoint,
    this.currentPoint,
    required this.template,
    required this.showGrid,
    required this.isDrawing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Get the visible clip bounds for performance optimization
    final clipBounds = canvas.getDestinationClipBounds();
    
    // Draw grid if enabled
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // Draw template background
    _drawTemplate(canvas, size);

    // Sort elements by layer order and timestamp
    final sortedElements = List<DrawingElement>.from(elements);
    sortedElements.sort((a, b) {
      final layerComparison = a.layer.order.compareTo(b.layer.order);
      if (layerComparison != 0) return layerComparison;
      return a.timestamp.compareTo(b.timestamp);
    });

    // Draw all elements with culling optimization
    for (final element in sortedElements) {
      if (_isElementVisible(element, clipBounds)) {
        _drawElement(canvas, element);
      }
    }

    // Draw current drawing action
    _drawCurrentAction(canvas, size);
  }

  // Performance optimization: Check if element is visible in current viewport
  bool _isElementVisible(DrawingElement element, Rect clipBounds) {
    Rect? elementBounds;
    
    if (element is PathElement) {
      elementBounds = element.path.getBounds();
    } else if (element is ShapeElement) {
      elementBounds = Rect.fromPoints(element.startPoint, element.endPoint);
    } else if (element is StampElement) {
      final size = element.size;
      elementBounds = Rect.fromCenter(
        center: element.position,
        width: size,
        height: size,
      );
    } else if (element is TextElement) {
      // Approximate text bounds
      final size = element.fontSize * element.text.length * 0.6;
      elementBounds = Rect.fromLTWH(
        element.position.dx,
        element.position.dy,
        size,
        element.fontSize * 1.2,
      );
    }
    
    if (elementBounds == null) return true;
    
    // Add some padding to account for stroke width
    final padding = element.paint.strokeWidth + 10;
    elementBounds = elementBounds.inflate(padding);
    
    return clipBounds.overlaps(elementBounds);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const gridSize = 20.0;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawTemplate(Canvas canvas, Size size) {
    if (template == DentalTemplate.none) return;

    final templatePaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    switch (template) {
      case DentalTemplate.adultOdontogram:
        _drawAdultOdontogram(canvas, size, templatePaint, fillPaint);
        break;
      case DentalTemplate.pediatricOdontogram:
        _drawPediatricOdontogram(canvas, size, templatePaint, fillPaint);
        break;
      case DentalTemplate.periodontalChart:
        _drawPeriodontalChart(canvas, size, templatePaint, fillPaint);
        break;
      case DentalTemplate.oralCavityFrontal:
        _drawOralCavityFrontal(canvas, size, templatePaint, fillPaint);
        break;
      case DentalTemplate.oralCavityLateral:
        _drawOralCavityLateral(canvas, size, templatePaint, fillPaint);
        break;
      case DentalTemplate.bitewing:
        _drawBitewingTemplate(canvas, size, templatePaint, fillPaint);
        break;
      case DentalTemplate.panoramic:
        _drawPanoramicTemplate(canvas, size, templatePaint, fillPaint);
        break;
      case DentalTemplate.none:
        break;
    }
  }

  void _drawAdultOdontogram(
      Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final baseToothSize = math.min(size.width / 20, size.height / 10);
    final toothSize = baseToothSize * (size.width / 800); // Scale with canvas size
    final spacing = toothSize * 1.2;

    // Upper arch (teeth 11-18, 21-28)
    final upperTeeth = [
      '18',
      '17',
      '16',
      '15',
      '14',
      '13',
      '12',
      '11',
      '21',
      '22',
      '23',
      '24',
      '25',
      '26',
      '27',
      '28'
    ];

    for (int i = 0; i < upperTeeth.length; i++) {
      final x = centerX - (8 * spacing) + (i * spacing);
      final y = centerY - toothSize * 2;
      _drawTooth(canvas, Offset(x, y), toothSize, strokePaint, fillPaint,
          upperTeeth[i]);
    }

    // Lower arch (teeth 41-48, 31-38)
    final lowerTeeth = [
      '48',
      '47',
      '46',
      '45',
      '44',
      '43',
      '42',
      '41',
      '31',
      '32',
      '33',
      '34',
      '35',
      '36',
      '37',
      '38'
    ];

    for (int i = 0; i < lowerTeeth.length; i++) {
      final x = centerX - (8 * spacing) + (i * spacing);
      final y = centerY + toothSize * 2;
      _drawTooth(canvas, Offset(x, y), toothSize, strokePaint, fillPaint,
          lowerTeeth[i]);
    }

    // Draw arch guides
    _drawArchGuides(
        canvas, centerX, centerY, spacing * 8, toothSize * 2, strokePaint);
  }

  void _drawPediatricOdontogram(
      Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final baseToothSize = math.min(size.width / 16, size.height / 8);
    final toothSize = baseToothSize * (size.width / 800); // Scale with canvas size
    final spacing = toothSize * 1.2;

    // Upper teeth
    const upperTeeth = ['E', 'D', 'C', 'B', 'A', 'A', 'B', 'C', 'D', 'E'];
    for (int i = 0; i < upperTeeth.length; i++) {
      final x = centerX - (5 * spacing) + (i * spacing);
      final y = centerY - toothSize * 1.5;
      _drawTooth(canvas, Offset(x, y), toothSize, strokePaint, fillPaint,
          upperTeeth[i]);
    }

    // Lower teeth
    const lowerTeeth = ['O', 'N', 'M', 'L', 'K', 'K', 'L', 'M', 'N', 'O'];
    for (int i = 0; i < lowerTeeth.length; i++) {
      final x = centerX - (5 * spacing) + (i * spacing);
      final y = centerY + toothSize * 1.5;
      _drawTooth(canvas, Offset(x, y), toothSize, strokePaint, fillPaint,
          lowerTeeth[i]);
    }

    // Draw smaller arch guides for pediatric
    _drawArchGuides(
        canvas, centerX, centerY, spacing * 5, toothSize * 1.5, strokePaint);
  }

  void _drawPeriodontalChart(
      Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {
    final startX = size.width * 0.1;
    final startY = size.height / 2;
    final toothWidth = (size.width * 0.8) / 32;
    final chartHeight = size.height * 0.6;

    // Draw measurement grid
    for (int i = 0; i < 32; i++) {
      final x = startX + (i * toothWidth);

      // Draw tooth column
      final rect =
          Rect.fromLTWH(x, startY - chartHeight / 2, toothWidth, chartHeight);
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);

      // Draw measurement lines (1-12mm scale)
      for (int j = 1; j < 12; j++) {
        final y = startY - chartHeight / 2 + (j * chartHeight / 12);
        final linePaint = Paint()
          ..color = j <= 3
              ? Colors.green.withOpacity(0.3)
              : j <= 5
                  ? Colors.yellow.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3)
          ..strokeWidth = 0.5;
        canvas.drawLine(Offset(x, y), Offset(x + toothWidth, y), linePaint);

        // Add measurement numbers
        if (i == 0) {
          _drawText(canvas, Offset(x - 20, y - 5), j.toString(), 8,
              Colors.grey[600]!);
        }
      }

      // Draw tooth number
      final toothNumber = i < 16 ? (18 - i).toString() : (i + 17).toString();
      _drawText(
          canvas,
          Offset(x + toothWidth / 2 - 8, startY + chartHeight / 2 + 10),
          toothNumber,
          10,
          Colors.black);
    }
  }

  void _drawOralCavityFrontal(
      Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw main oral cavity outline
    final oralPath = Path();
    final ovalRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: size.width * 0.7,
      height: size.height * 0.5,
    );
    oralPath.addOval(ovalRect);
    canvas.drawPath(oralPath, fillPaint);
    canvas.drawPath(oralPath, strokePaint);

    // Draw dental arches
    final upperArchPath = Path();
    upperArchPath.addArc(
      Rect.fromCenter(
        center: Offset(centerX, centerY - size.height * 0.1),
        width: size.width * 0.5,
        height: size.height * 0.15,
      ),
      0,
      math.pi,
    );
    canvas.drawPath(upperArchPath, strokePaint);

    final lowerArchPath = Path();
    lowerArchPath.addArc(
      Rect.fromCenter(
        center: Offset(centerX, centerY + size.height * 0.1),
        width: size.width * 0.5,
        height: size.height * 0.15,
      ),
      math.pi,
      math.pi,
    );
    canvas.drawPath(lowerArchPath, strokePaint);

    // Draw anatomical landmarks
    _drawAnatomicalLandmarks(canvas, centerX, centerY, size, strokePaint);
  }

  void _drawOralCavityLateral(
      Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw side profile of oral cavity
    final profilePath = Path();
    profilePath.moveTo(centerX - size.width * 0.2, centerY - size.height * 0.2);
    profilePath.quadraticBezierTo(
        centerX + size.width * 0.1,
        centerY - size.height * 0.25,
        centerX + size.width * 0.25,
        centerY - size.height * 0.15);
    profilePath.quadraticBezierTo(centerX + size.width * 0.27, centerY,
        centerX + size.width * 0.23, centerY + size.height * 0.15);
    profilePath.quadraticBezierTo(
        centerX + size.width * 0.1,
        centerY + size.height * 0.25,
        centerX - size.width * 0.2,
        centerY + size.height * 0.2);
    profilePath.quadraticBezierTo(centerX - size.width * 0.22, centerY,
        centerX - size.width * 0.2, centerY - size.height * 0.2);

    canvas.drawPath(profilePath, fillPaint);
    canvas.drawPath(profilePath, strokePaint);

    // Draw teeth profile
    for (int i = 0; i < 8; i++) {
      final x = centerX - size.width * 0.15 + (i * size.width * 0.04);
      final y1 = centerY - size.height * 0.1;
      final y2 = centerY + size.height * 0.1;
      canvas.drawLine(
          Offset(x, y1), Offset(x, y1 + size.height * 0.05), strokePaint);
      canvas.drawLine(
          Offset(x, y2), Offset(x, y2 - size.height * 0.05), strokePaint);
    }
  }

  void _drawBitewingTemplate(
      Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final sectionWidth = size.width * 0.4;
    final sectionHeight = size.height * 0.3;

    // Left bitewing
    final leftRect = Rect.fromCenter(
      center: Offset(centerX - size.width * 0.2, centerY),
      width: sectionWidth,
      height: sectionHeight,
    );
    canvas.drawRect(leftRect, fillPaint);
    canvas.drawRect(leftRect, strokePaint);
    _drawText(canvas, Offset(leftRect.left + 10, leftRect.top + 10),
        'LEFT BITEWING', 12, Colors.black);

    // Right bitewing
    final rightRect = Rect.fromCenter(
      center: Offset(centerX + size.width * 0.2, centerY),
      width: sectionWidth,
      height: sectionHeight,
    );
    canvas.drawRect(rightRect, fillPaint);
    canvas.drawRect(rightRect, strokePaint);
    _drawText(canvas, Offset(rightRect.left + 10, rightRect.top + 10),
        'RIGHT BITEWING', 12, Colors.black);

    // Draw crown and root separation lines
    final separationPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(leftRect.left, centerY),
        Offset(leftRect.right, centerY), separationPaint);
    canvas.drawLine(Offset(rightRect.left, centerY),
        Offset(rightRect.right, centerY), separationPaint);
  }

  void _drawPanoramicTemplate(
      Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw panoramic outline
    final panoramicPath = Path();
    panoramicPath.addArc(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: size.width * 0.9,
        height: size.height * 0.6,
      ),
      0,
      2 * math.pi,
    );
    canvas.drawPath(panoramicPath, fillPaint);
    canvas.drawPath(panoramicPath, strokePaint);

    // Draw anatomical reference lines
    final referencePaint = Paint()
      ..color = Colors.grey.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Maxillary line
    canvas.drawLine(Offset(size.width * 0.1, centerY - size.height * 0.1),
        Offset(size.width * 0.9, centerY - size.height * 0.1), referencePaint);

    // Mandibular line
    canvas.drawLine(Offset(size.width * 0.1, centerY + size.height * 0.1),
        Offset(size.width * 0.9, centerY + size.height * 0.1), referencePaint);

    // Add labels
    _drawText(canvas, Offset(10, centerY - size.height * 0.15), 'MAXILLA', 10,
        Colors.grey[600]!);
    _drawText(canvas, Offset(10, centerY + size.height * 0.05), 'MANDIBLE', 10,
        Colors.grey[600]!);
  }

  void _drawTooth(Canvas canvas, Offset center, double size, Paint strokePaint,
      Paint fillPaint, String number) {
    // Draw tooth shape with rounded corners
    final rect = Rect.fromCenter(center: center, width: size, height: size);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size * 0.15));

    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, strokePaint);

    // Draw tooth surfaces
    final surfacePaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Mesial and Distal lines
    canvas.drawLine(Offset(center.dx - size / 3, rect.top),
        Offset(center.dx - size / 3, rect.bottom), surfacePaint);
    canvas.drawLine(Offset(center.dx + size / 3, rect.top),
        Offset(center.dx + size / 3, rect.bottom), surfacePaint);

    // Buccal and Lingual lines
    canvas.drawLine(Offset(rect.left, center.dy - size / 3),
        Offset(rect.right, center.dy - size / 3), surfacePaint);
    canvas.drawLine(Offset(rect.left, center.dy + size / 3),
        Offset(rect.right, center.dy + size / 3), surfacePaint);

    // Draw tooth number
    _drawText(canvas, Offset(center.dx - 6, center.dy - 6), number, size * 0.25,
        Colors.black);
  }

  void _drawArchGuides(Canvas canvas, double centerX, double centerY,
      double width, double height, Paint paint) {
    final guidePaint = Paint()
      ..color = paint.color.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Upper arch guide
    final upperArchPath = Path();
    upperArchPath.addArc(
      Rect.fromCenter(
        center: Offset(centerX, centerY - height),
        width: width,
        height: height * 0.8,
      ),
      0,
      math.pi,
    );
    canvas.drawPath(upperArchPath, guidePaint);

    // Lower arch guide
    final lowerArchPath = Path();
    lowerArchPath.addArc(
      Rect.fromCenter(
        center: Offset(centerX, centerY + height),
        width: width,
        height: height * 0.8,
      ),
      math.pi,
      math.pi,
    );
    canvas.drawPath(lowerArchPath, guidePaint);
  }

  void _drawAnatomicalLandmarks(
      Canvas canvas, double centerX, double centerY, Size size, Paint paint) {
    final landmarkPaint = Paint()
      ..color = Colors.grey.withOpacity(0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw tongue outline
    final tongueRect = Rect.fromCenter(
      center: Offset(centerX, centerY + size.height * 0.05),
      width: size.width * 0.3,
      height: size.height * 0.2,
    );
    canvas.drawOval(tongueRect, landmarkPaint);

    // Draw lips
    canvas.drawLine(
        Offset(centerX - size.width * 0.35, centerY - size.height * 0.25),
        Offset(centerX + size.width * 0.35, centerY - size.height * 0.25),
        landmarkPaint);
    canvas.drawLine(
        Offset(centerX - size.width * 0.35, centerY + size.height * 0.25),
        Offset(centerX + size.width * 0.35, centerY + size.height * 0.25),
        landmarkPaint);
  }

  void _drawElement(Canvas canvas, DrawingElement element) {
    if (element is PathElement) {
      canvas.drawPath(element.path, element.paint);
    } else if (element is ShapeElement) {
      _drawShape(canvas, element);
    } else if (element is StampElement) {
      _drawStamp(canvas, element);
    } else if (element is TextElement) {
      _drawTextElement(canvas, element);
    }
  }

  void _drawShape(Canvas canvas, ShapeElement element) {
    switch (element.tool) {
      case DrawingTool.line:
        canvas.drawLine(element.startPoint, element.endPoint, element.paint);
        break;
      case DrawingTool.circle:
        final radius = (element.endPoint - element.startPoint).distance / 2;
        final center = Offset(
          (element.startPoint.dx + element.endPoint.dx) / 2,
          (element.startPoint.dy + element.endPoint.dy) / 2,
        );
        canvas.drawCircle(center, radius, element.paint);
        break;
      case DrawingTool.rectangle:
        final rect = Rect.fromPoints(element.startPoint, element.endPoint);
        canvas.drawRect(rect, element.paint);
        break;
      case DrawingTool.arrow:
        _drawArrow(canvas, element.startPoint, element.endPoint, element.paint);
        break;
      case DrawingTool.ruler:
        _drawRuler(canvas, element.startPoint, element.endPoint, element.paint);
        break;
      default:
        break;
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    // Draw main line
    canvas.drawLine(start, end, paint);

    // Calculate arrowhead
    final direction = end - start;
    final length = direction.distance;
    if (length == 0) return;

    final unitVector = direction / length;
    final arrowLength = math.min(20.0, length * 0.3);
    const arrowAngle = math.pi / 6;

    final arrowPoint1 = end -
        Offset(
          unitVector.dx * arrowLength * math.cos(arrowAngle) -
              unitVector.dy * arrowLength * math.sin(arrowAngle),
          unitVector.dy * arrowLength * math.cos(arrowAngle) +
              unitVector.dx * arrowLength * math.sin(arrowAngle),
        );

    final arrowPoint2 = end -
        Offset(
          unitVector.dx * arrowLength * math.cos(-arrowAngle) -
              unitVector.dy * arrowLength * math.sin(-arrowAngle),
          unitVector.dy * arrowLength * math.cos(-arrowAngle) +
              unitVector.dx * arrowLength * math.sin(-arrowAngle),
        );

    // Draw arrowhead
    canvas.drawLine(end, arrowPoint1, paint);
    canvas.drawLine(end, arrowPoint2, paint);

    // Fill arrowhead
    final arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(arrowPoint1.dx, arrowPoint1.dy);
    arrowPath.lineTo(arrowPoint2.dx, arrowPoint2.dy);
    arrowPath.close();
    
    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, fillPaint);
  }

  void _drawRuler(Canvas canvas, Offset start, Offset end, Paint paint) {
    // Draw main line
    canvas.drawLine(start, end, paint);

    final direction = end - start;
    final length = direction.distance;
    if (length == 0) return;

    final unitVector = direction / length;
    final perpVector = Offset(-unitVector.dy, unitVector.dx);

    const markLength = 8.0;
    final numMarks = (length / 10).round().clamp(2, 20);

    // Draw measurement marks
    for (int i = 0; i <= numMarks; i++) {
      final t = i / numMarks;
      final point = start + direction * t;
      final markStart = point - perpVector * markLength;
      final markEnd = point + perpVector * markLength;
      canvas.drawLine(markStart, markEnd, paint);
    }

    // Draw distance text
    final distance =
        (length / 10).toStringAsFixed(1); // Convert to cm approximation
    final center = (start + end) / 2;
    final textOffset = perpVector * (markLength + 15);
    _drawText(canvas, center + textOffset, '${distance}cm', 10, paint.color);
  }

  void _drawStamp(Canvas canvas, StampElement element) {
    _drawText(
      canvas,
      element.position - Offset(element.size / 4, element.size / 4),
      element.symbol,
      element.size,
      element.paint.color,
      FontWeight.bold,
    );
  }

  void _drawTextElement(Canvas canvas, TextElement element) {
    _drawText(
      canvas,
      element.position,
      element.text,
      element.fontSize,
      element.paint.color,
      element.fontWeight,
    );
  }

  void _drawText(
      Canvas canvas, Offset position, String text, double fontSize, Color color,
      [FontWeight fontWeight = FontWeight.normal]) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  void _drawCurrentAction(Canvas canvas, Size size) {
    if (!isDrawing) return;

    switch (currentTool) {
      case DrawingTool.pen:
      case DrawingTool.highlighter:
        if (currentPath != null) {
          final previewPaint = Paint()
            ..color = currentPaint.color.withOpacity(0.7)
            ..strokeWidth = currentPaint.strokeWidth
            ..strokeCap = currentPaint.strokeCap
            ..style = currentPaint.style;
          canvas.drawPath(currentPath!, previewPaint);
        }
        break;

      case DrawingTool.circle:
      case DrawingTool.rectangle:
      case DrawingTool.line:
      case DrawingTool.arrow:
      case DrawingTool.ruler:
        if (startPoint != null && currentPoint != null) {
          final previewPaint = Paint()
            ..color = currentPaint.color.withOpacity(0.5)
            ..strokeWidth = currentPaint.strokeWidth
            ..strokeCap = currentPaint.strokeCap
            ..style = currentPaint.style;

          final previewElement = ShapeElement(
            id: 'preview',
            tool: currentTool,
            paint: previewPaint,
            layer: LayerType.overlay,
            startPoint: startPoint!,
            endPoint: currentPoint!,
          );
          _drawShape(canvas, previewElement);
        }
        break;

      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! EnhancedDentalPainter ||
        oldDelegate.elements.length != elements.length ||
        oldDelegate.currentPath != currentPath ||
        oldDelegate.currentTool != currentTool ||
        oldDelegate.startPoint != startPoint ||
        oldDelegate.currentPoint != currentPoint ||
        oldDelegate.template != template ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.isDrawing != isDrawing ||
        !_listsEqual(oldDelegate.elements, elements);
  }

  bool _listsEqual(List<DrawingElement> a, List<DrawingElement> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}









// import 'dart:convert';
// import 'dart:io';
// import 'dart:math' as math;
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';

// // ==================== ENUMS ====================
// enum DrawingTool {
//   pen,
//   eraser,
//   circle,
//   arrow,
//   line,
//   rectangle,
//   text,
//   stamp,
//   ruler,
//   highlighter,
//   freeform
// }

// enum DentalTemplate {
//   none,
//   adultOdontogram,
//   pediatricOdontogram,
//   periodontalChart,
//   oralCavityFrontal,
//   oralCavityLateral,
//   bitewing,
//   panoramic
// }

// enum LayerType {
//   background('Background', 0),
//   drawing('Drawing', 1),
//   annotation('Annotation', 2),
//   overlay('Overlay', 3),
//   template('Template', -1);

//   const LayerType(this.displayName, this.order);
//   final String displayName;
//   final int order;
// }

// // ==================== DATA MODELS ====================
// abstract class DrawingElement {
//   final String id;
//   final DrawingTool tool;
//   final Paint paint;
//   final LayerType layer;
//   final DateTime timestamp;

//   DrawingElement({
//     required this.id,
//     required this.tool,
//     required this.paint,
//     required this.layer,
//     DateTime? timestamp,
//   }) : timestamp = timestamp ?? DateTime.now();

//   Map<String, dynamic> toJson();

//   static DrawingElement fromJson(Map<String, dynamic> json) {
//     switch (json['type']) {
//       case 'path':
//         return PathElement.fromJson(json);
//       case 'shape':
//         return ShapeElement.fromJson(json);
//       case 'stamp':
//         return StampElement.fromJson(json);
//       case 'text':
//         return TextElement.fromJson(json);
//       default:
//         throw Exception('Unknown element type: ${json['type']}');
//     }
//   }
// }

// class PathElement extends DrawingElement {
//   final Path path;
//   final List<Offset> points;

//   PathElement({
//     required super.id,
//     required super.tool,
//     required super.paint,
//     required super.layer,
//     required this.path,
//     required this.points,
//     super.timestamp,
//   });

//   @override
//   Map<String, dynamic> toJson() => {
//         'type': 'path',
//         'id': id,
//         'tool': tool.name,
//         'layer': layer.name,
//         'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
//         'color': paint.color.value,
//         'strokeWidth': paint.strokeWidth,
//         'timestamp': timestamp.millisecondsSinceEpoch,
//       };

//   static PathElement fromJson(Map<String, dynamic> json) {
//     final points =
//         (json['points'] as List).map((p) => Offset(p['x'], p['y'])).toList();
//     final path = Path();
//     if (points.isNotEmpty) {
//       path.moveTo(points.first.dx, points.first.dy);
//       for (int i = 1; i < points.length; i++) {
//         path.lineTo(points[i].dx, points[i].dy);
//       }
//     }

//     return PathElement(
//       id: json['id'],
//       tool: DrawingTool.values.byName(json['tool']),
//       paint: Paint()
//         ..color = Color(json['color'])
//         ..strokeWidth = json['strokeWidth']
//         ..style = PaintingStyle.stroke
//         ..strokeCap = StrokeCap.round,
//       layer: LayerType.values.byName(json['layer']),
//       path: path,
//       points: points,
//       timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
//     );
//   }
// }

// class ShapeElement extends DrawingElement {
//   final Offset startPoint;
//   final Offset endPoint;
//   final String? text;

//   ShapeElement({
//     required super.id,
//     required super.tool,
//     required super.paint,
//     required super.layer,
//     required this.startPoint,
//     required this.endPoint,
//     this.text,
//     super.timestamp,
//   });

//   @override
//   Map<String, dynamic> toJson() => {
//         'type': 'shape',
//         'id': id,
//         'tool': tool.name,
//         'layer': layer.name,
//         'startPoint': {'x': startPoint.dx, 'y': startPoint.dy},
//         'endPoint': {'x': endPoint.dx, 'y': endPoint.dy},
//         'text': text,
//         'color': paint.color.value,
//         'strokeWidth': paint.strokeWidth,
//         'timestamp': timestamp.millisecondsSinceEpoch,
//       };

//   static ShapeElement fromJson(Map<String, dynamic> json) => ShapeElement(
//         id: json['id'],
//         tool: DrawingTool.values.byName(json['tool']),
//         paint: Paint()
//           ..color = Color(json['color'])
//           ..strokeWidth = json['strokeWidth']
//           ..style = PaintingStyle.stroke
//           ..strokeCap = StrokeCap.round,
//         layer: LayerType.values.byName(json['layer']),
//         startPoint: Offset(json['startPoint']['x'], json['startPoint']['y']),
//         endPoint: Offset(json['endPoint']['x'], json['endPoint']['y']),
//         text: json['text'],
//         timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
//       );
// }

// class StampElement extends DrawingElement {
//   final Offset position;
//   final String symbol;
//   final double size;
//   final String description;

//   StampElement({
//     required super.id,
//     required super.tool,
//     required super.paint,
//     required super.layer,
//     required this.position,
//     required this.symbol,
//     required this.size,
//     required this.description,
//     super.timestamp,
//   });

//   @override
//   Map<String, dynamic> toJson() => {
//         'type': 'stamp',
//         'id': id,
//         'tool': tool.name,
//         'layer': layer.name,
//         'position': {'x': position.dx, 'y': position.dy},
//         'symbol': symbol,
//         'size': size,
//         'description': description,
//         'color': paint.color.value,
//         'timestamp': timestamp.millisecondsSinceEpoch,
//       };

//   static StampElement fromJson(Map<String, dynamic> json) => StampElement(
//         id: json['id'],
//         tool: DrawingTool.values.byName(json['tool']),
//         paint: Paint()
//           ..color = Color(json['color'])
//           ..style = PaintingStyle.fill,
//         layer: LayerType.values.byName(json['layer']),
//         position: Offset(json['position']['x'], json['position']['y']),
//         symbol: json['symbol'],
//         size: json['size'],
//         description: json['description'],
//         timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
//       );
// }

// class TextElement extends DrawingElement {
//   final Offset position;
//   final String text;
//   final double fontSize;
//   final FontWeight fontWeight;

//   TextElement({
//     required super.id,
//     required super.tool,
//     required super.paint,
//     required super.layer,
//     required this.position,
//     required this.text,
//     required this.fontSize,
//     this.fontWeight = FontWeight.normal,
//     super.timestamp,
//   });

//   @override
//   Map<String, dynamic> toJson() => {
//         'type': 'text',
//         'id': id,
//         'tool': tool.name,
//         'layer': layer.name,
//         'position': {'x': position.dx, 'y': position.dy},
//         'text': text,
//         'fontSize': fontSize,
//         'fontWeight': fontWeight.index,
//         'color': paint.color.value,
//         'timestamp': timestamp.millisecondsSinceEpoch,
//       };

//   static TextElement fromJson(Map<String, dynamic> json) => TextElement(
//         id: json['id'],
//         tool: DrawingTool.values.byName(json['tool']),
//         paint: Paint()..color = Color(json['color']),
//         layer: LayerType.values.byName(json['layer']),
//         position: Offset(json['position']['x'], json['position']['y']),
//         text: json['text'],
//         fontSize: json['fontSize'],
//         fontWeight: FontWeight.values[json['fontWeight']],
//         timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
//       );
// }

// // ==================== SERVICES ====================
// class CanvasService {
//   static String generateId() =>
//       DateTime.now().millisecondsSinceEpoch.toString();

//   static Future<String> exportToBase64(GlobalKey canvasKey) async {
//     final RenderRepaintBoundary boundary =
//         canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
//     final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
//     final ByteData? byteData =
//         await image.toByteData(format: ui.ImageByteFormat.png);
//     final Uint8List pngBytes = byteData!.buffer.asUint8List();
//     return base64Encode(pngBytes);
//   }

//   static bool isPointNearPath(Path path, Offset point, double tolerance) {
//     final bounds = path.getBounds();
//     return bounds.inflate(tolerance).contains(point);
//   }

//   static bool isPointNearElement(
//       DrawingElement element, Offset point, double tolerance) {
//     if (element is PathElement) {
//       return isPointNearPath(element.path, point, tolerance);
//     } else if (element is ShapeElement) {
//       final distance1 = (element.startPoint - point).distance;
//       final distance2 = (element.endPoint - point).distance;
//       return distance1 < tolerance || distance2 < tolerance;
//     } else if (element is StampElement) {
//       return (element.position - point).distance < tolerance;
//     } else if (element is TextElement) {
//       return (element.position - point).distance < tolerance;
//     }
//     return false;
//   }
// }

// class DentalConstants {
//   static const Map<String, Color> dentalColors = {
//     'Black': Colors.black,
//     'Red': Colors.red,
//     'Blue': Colors.blue,
//     'Green': Colors.green,
//     'Yellow': Colors.yellow,
//     'Orange': Colors.orange,
//     'Purple': Colors.purple,
//     'Brown': Color(0xFF8B4513),
//     'Pink': Colors.pink,
//     'Cyan': Colors.cyan,
//   };

//   static const Map<String, String> dentalSymbols = {
//     'Extraction': '✗',
//     'Missing': '□',
//     'Crown': '♔',
//     'Root Canal': '⚡',
//     'Cavity': '●',
//     'Filling': '■',
//     'Implant': '⚈',
//     'Bridge': '═',
//     'Mesial': '/',
//     'Distal': '\\',
//     'Buccal': ')',
//     'Lingual': '(',
//     'Occlusal': '○',
//     'Periapical': '◊',
//     'Abscess': '※',
//     'Fracture': '⚡',
//   };

//   static const List<String> adultTeeth = [
//     '18',
//     '17',
//     '16',
//     '15',
//     '14',
//     '13',
//     '12',
//     '11',
//     '21',
//     '22',
//     '23',
//     '24',
//     '25',
//     '26',
//     '27',
//     '28',
//     '48',
//     '47',
//     '46',
//     '45',
//     '44',
//     '43',
//     '42',
//     '41',
//     '31',
//     '32',
//     '33',
//     '34',
//     '35',
//     '36',
//     '37',
//     '38'
//   ];

//   static const List<String> pediatricTeeth = [
//     'A',
//     'B',
//     'C',
//     'D',
//     'E',
//     'F',
//     'G',
//     'H',
//     'I',
//     'J',
//     'K',
//     'L',
//     'M',
//     'N',
//     'O',
//     'P',
//     'Q',
//     'R',
//     'S',
//     'T'
//   ];
// }

// // ==================== STATE MANAGEMENT ====================
// class CanvasState extends ChangeNotifier {
//   final List<DrawingElement> _elements = [];
//   final List<List<DrawingElement>> _undoStack = [];
//   final List<List<DrawingElement>> _redoStack = [];
//   final Map<LayerType, bool> _layerVisibility = {};

//   DrawingTool _currentTool = DrawingTool.pen;
//   LayerType _currentLayer = LayerType.drawing;
//   Color _currentColor = Colors.black;
//   double _currentStrokeWidth = 2.5;
//   double _currentFontSize = 16.0;
//   DentalTemplate _currentTemplate = DentalTemplate.none;
//   DateTime _selectedDateTime = DateTime.now();
//   bool _showGrid = false;
//   bool _autoSave = true;

//   // Getters
//   List<DrawingElement> get elements => List.unmodifiable(_elements);
//   List<DrawingElement> get visibleElements =>
//       _elements.where((e) => _layerVisibility[e.layer] == true).toList();

//   DrawingTool get currentTool => _currentTool;
//   LayerType get currentLayer => _currentLayer;
//   Color get currentColor => _currentColor;
//   double get currentStrokeWidth => _currentStrokeWidth;
//   double get currentFontSize => _currentFontSize;
//   DentalTemplate get currentTemplate => _currentTemplate;
//   DateTime get selectedDateTime => _selectedDateTime;
//   bool get showGrid => _showGrid;
//   bool get autoSave => _autoSave;
//   bool get canUndo => _undoStack.isNotEmpty;
//   bool get canRedo => _redoStack.isNotEmpty;
//   Map<LayerType, bool> get layerVisibility =>
//       Map.unmodifiable(_layerVisibility);

//   CanvasState() {
//     _initializeLayerVisibility();
//   }

//   void _initializeLayerVisibility() {
//     for (final layer in LayerType.values) {
//       _layerVisibility[layer] = true;
//     }
//   }

//   void _saveStateForUndo() {
//     _undoStack.add(_elements.map((e) => e).toList());
//     _redoStack.clear();
//     if (_undoStack.length > 30) {
//       _undoStack.removeAt(0);
//     }
//   }

//   // Tool and settings methods
//   void setCurrentTool(DrawingTool tool) {
//     _currentTool = tool;
//     notifyListeners();
//   }

//   void setCurrentLayer(LayerType layer) {
//     _currentLayer = layer;
//     notifyListeners();
//   }

//   void setCurrentColor(Color color) {
//     _currentColor = color;
//     notifyListeners();
//   }

//   void setCurrentStrokeWidth(double width) {
//     _currentStrokeWidth = width;
//     notifyListeners();
//   }

//   void setCurrentFontSize(double size) {
//     _currentFontSize = size;
//     notifyListeners();
//   }

//   void setCurrentTemplate(DentalTemplate template) {
//     _currentTemplate = template;
//     notifyListeners();
//   }

//   void setSelectedDateTime(DateTime dateTime) {
//     _selectedDateTime = dateTime;
//     notifyListeners();
//   }

//   void toggleGrid() {
//     _showGrid = !_showGrid;
//     notifyListeners();
//   }

//   void toggleAutoSave() {
//     _autoSave = !_autoSave;
//     notifyListeners();
//   }

//   void toggleLayerVisibility(LayerType layer) {
//     _layerVisibility[layer] = !(_layerVisibility[layer] ?? true);
//     notifyListeners();
//   }

//   // Element management
//   void addElement(DrawingElement element) {
//     _saveStateForUndo();
//     _elements.add(element);
//     notifyListeners();

//     if (_autoSave) {
//       _autoSaveCanvas();
//     }
//   }

//   void removeElement(String id) {
//     _saveStateForUndo();
//     _elements.removeWhere((e) => e.id == id);
//     notifyListeners();
//   }

//   void clearCanvas() {
//     if (_elements.isNotEmpty) {
//       _saveStateForUndo();
//       _elements.clear();
//       notifyListeners();
//     }
//   }

//   void clearLayer(LayerType layer) {
//     final layerElements = _elements.where((e) => e.layer == layer).toList();
//     if (layerElements.isNotEmpty) {
//       _saveStateForUndo();
//       _elements.removeWhere((e) => e.layer == layer);
//       notifyListeners();
//     }
//   }

//   void undo() {
//     if (_undoStack.isNotEmpty) {
//       _redoStack.add(_elements.map((e) => e).toList());
//       _elements.clear();
//       if (_undoStack.isNotEmpty) {
//         _elements.addAll(_undoStack.removeLast());
//       }
//       notifyListeners();
//     }
//   }

//   void redo() {
//     if (_redoStack.isNotEmpty) {
//       _undoStack.add(_elements.map((e) => e).toList());
//       _elements.clear();
//       _elements.addAll(_redoStack.removeLast());
//       notifyListeners();
//     }
//   }

//   void eraseAtPoint(Offset point, double radius) {
//     final elementsToRemove = <DrawingElement>[];

//     for (final element in _elements) {
//       if (CanvasService.isPointNearElement(element, point, radius)) {
//         elementsToRemove.add(element);
//       }
//     }

//     if (elementsToRemove.isNotEmpty) {
//       _saveStateForUndo();
//       _elements.removeWhere((e) => elementsToRemove.contains(e));
//       notifyListeners();
//     }
//   }

//   Paint createPaint({Color? color, double? strokeWidth, PaintingStyle? style}) {
//     return Paint()
//       ..color = color ?? _currentColor
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = strokeWidth ?? _currentStrokeWidth
//       ..style = style ?? PaintingStyle.stroke;
//   }

//   void _autoSaveCanvas() {
//     // Implement auto-save logic here
//     // This could save to local storage, send to server, etc.
//   }

//   // Serialization
//   Map<String, dynamic> toJson() => {
//         'elements': _elements.map((e) => e.toJson()).toList(),
//         'currentTool': _currentTool.name,
//         'currentLayer': _currentLayer.name,
//         'currentColor': _currentColor.value,
//         'currentStrokeWidth': _currentStrokeWidth,
//         'currentFontSize': _currentFontSize,
//         'currentTemplate': _currentTemplate.name,
//         'selectedDateTime': _selectedDateTime.millisecondsSinceEpoch,
//         'layerVisibility': _layerVisibility.map((k, v) => MapEntry(k.name, v)),
//         'showGrid': _showGrid,
//         'autoSave': _autoSave,
//       };

//   void fromJson(Map<String, dynamic> json) {
//     _elements.clear();
//     _elements.addAll(
//       (json['elements'] as List)
//           .map((e) => DrawingElement.fromJson(e))
//           .toList(),
//     );

//     _currentTool = DrawingTool.values.byName(json['currentTool']);
//     _currentLayer = LayerType.values.byName(json['currentLayer']);
//     _currentColor = Color(json['currentColor']);
//     _currentStrokeWidth = json['currentStrokeWidth'];
//     _currentFontSize = json['currentFontSize'];
//     _currentTemplate = DentalTemplate.values.byName(json['currentTemplate']);
//     _selectedDateTime =
//         DateTime.fromMillisecondsSinceEpoch(json['selectedDateTime']);
//     _showGrid = json['showGrid'];
//     _autoSave = json['autoSave'];

//     final layerVisibilityJson = json['layerVisibility'] as Map<String, dynamic>;
//     for (final entry in layerVisibilityJson.entries) {
//       _layerVisibility[LayerType.values.byName(entry.key)] = entry.value;
//     }

//     notifyListeners();
//   }
// }

// // ==================== MAIN WIDGET ====================
// class HandwritingScreen2 extends StatefulWidget {
//   const HandwritingScreen2({super.key, required this.patientId});
//   final int patientId;

//   @override
//   State<HandwritingScreen2> createState() => _HandwritingScreen2State();
// }

// class _HandwritingScreen2State extends State<HandwritingScreen2>
//     with TickerProviderStateMixin {
//   late final CanvasState _canvasState;
//   final GlobalKey _canvasKey = GlobalKey();
//   final TransformationController _transformationController =
//       TransformationController();

//   // Current drawing state
//   Path? _currentPath;
//   List<Offset> _currentPoints = [];
//   Offset? _startPoint;
//   Offset? _currentPoint;
//   bool _isDrawing = false;

//   // Animation controllers
//   late AnimationController _toolPanelController;
//   late Animation<double> _toolPanelAnimation;

//   // UI state
//   bool _showToolPanel = false;

//   @override
//   void initState() {
//     super.initState();
//     _canvasState = CanvasState();
//     _initializeAnimations();
//   }

//   void _initializeAnimations() {
//     _toolPanelController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _toolPanelAnimation = CurvedAnimation(
//       parent: _toolPanelController,
//       curve: Curves.easeInOut,
//     );
//   }

//   @override
//   void dispose() {
//     _toolPanelController.dispose();
//     _canvasState.dispose();
//     super.dispose();
//   }

//   // ==================== GESTURE HANDLERS ====================
//   void _handlePanStart(DragStartDetails details) {
//     _startPoint = details.localPosition;
//     _currentPoint = details.localPosition;
//     _isDrawing = true;

//     switch (_canvasState.currentTool) {
//       case DrawingTool.pen:
//       case DrawingTool.highlighter:
//         _currentPath = Path();
//         _currentPoints = [details.localPosition];
//         _currentPath!
//             .moveTo(details.localPosition.dx, details.localPosition.dy);
//         break;
//       case DrawingTool.eraser:
//         _canvasState.eraseAtPoint(details.localPosition, 20.0);
//         break;
//       default:
//         // For shape tools, we'll handle in onPanEnd
//         break;
//     }
//   }

//   void _handlePanUpdate(DragUpdateDetails details) {
//     if (!_isDrawing) return;

//     _currentPoint = details.localPosition;

//     setState(() {
//       switch (_canvasState.currentTool) {
//         case DrawingTool.pen:
//         case DrawingTool.highlighter:
//           _currentPoints.add(details.localPosition);
//           _currentPath?.lineTo(
//               details.localPosition.dx, details.localPosition.dy);
//           break;
//         case DrawingTool.eraser:
//           _canvasState.eraseAtPoint(details.localPosition, 20.0);
//           break;
//         default:
//           // For shapes, we'll draw preview in the painter
//           break;
//       }
//     });
//   }

//   void _handlePanEnd(DragEndDetails details) {
//     if (!_isDrawing || _startPoint == null) return;

//     switch (_canvasState.currentTool) {
//       case DrawingTool.pen:
//       case DrawingTool.highlighter:
//         if (_currentPath != null && _currentPoints.isNotEmpty) {
//           Paint paint = _canvasState.createPaint();
//           if (_canvasState.currentTool == DrawingTool.highlighter) {
//             paint = paint
//               ..color = _canvasState.currentColor.withOpacity(0.3)
//               ..strokeWidth = _canvasState.currentStrokeWidth * 2;
//           }

//           _canvasState.addElement(PathElement(
//             id: CanvasService.generateId(),
//             tool: _canvasState.currentTool,
//             paint: paint,
//             layer: _canvasState.currentLayer,
//             path: _currentPath!,
//             points: _currentPoints,
//           ));
//         }
//         break;

//       case DrawingTool.circle:
//       case DrawingTool.rectangle:
//       case DrawingTool.line:
//       case DrawingTool.arrow:
//       case DrawingTool.ruler:
//         if (_currentPoint != null) {
//           _canvasState.addElement(ShapeElement(
//             id: CanvasService.generateId(),
//             tool: _canvasState.currentTool,
//             paint: _canvasState.createPaint(),
//             layer: _canvasState.currentLayer,
//             startPoint: _startPoint!,
//             endPoint: _currentPoint!,
//           ));
//         }
//         break;

//       default:
//         break;
//     }

//     _isDrawing = false;
//     _currentPath = null;
//     _currentPoints.clear();
//     _startPoint = null;
//     _currentPoint = null;
//     setState(() {});
//   }

//   void _handleTap(TapUpDetails details) {
//     switch (_canvasState.currentTool) {
//       case DrawingTool.text:
//         _showTextDialog(details.localPosition);
//         break;
//       case DrawingTool.stamp:
//         _showStampDialog(details.localPosition);
//         break;
//       default:
//         break;
//     }
//   }

//   // ==================== DIALOGS ====================
//   void _showTextDialog(Offset position) {
//     final TextEditingController controller = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setDialogState) => AlertDialog(
//           title: const Text('Add Text'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: controller,
//                 decoration: const InputDecoration(
//                   hintText: 'Enter text',
//                   border: OutlineInputBorder(),
//                 ),
//                 maxLines: 3,
//                 autofocus: true,
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   const Text('Size: '),
//                   Expanded(
//                     child: Slider(
//                       value: _canvasState.currentFontSize,
//                       min: 8,
//                       max: 48,
//                       divisions: 20,
//                       label: _canvasState.currentFontSize.round().toString(),
//                       onChanged: (value) {
//                         setDialogState(() {
//                           _canvasState.setCurrentFontSize(value);
//                         });
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               // Color picker
//               Wrap(
//                 children: DentalConstants.dentalColors.entries
//                     .take(8)
//                     .map((entry) => GestureDetector(
//                           onTap: () {
//                             setDialogState(() {
//                               _canvasState.setCurrentColor(entry.value);
//                             });
//                           },
//                           child: Container(
//                             margin: const EdgeInsets.all(2),
//                             width: 30,
//                             height: 30,
//                             decoration: BoxDecoration(
//                               color: entry.value,
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                 color: _canvasState.currentColor == entry.value
//                                     ? Colors.black
//                                     : Colors.grey,
//                                 width: 2,
//                               ),
//                             ),
//                           ),
//                         ))
//                     .toList(),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 if (controller.text.isNotEmpty) {
//                   _canvasState.addElement(TextElement(
//                     id: CanvasService.generateId(),
//                     tool: DrawingTool.text,
//                     paint: _canvasState.createPaint(),
//                     layer: _canvasState.currentLayer,
//                     position: position,
//                     text: controller.text,
//                     fontSize: _canvasState.currentFontSize,
//                   ));
//                 }
//                 Navigator.pop(context);
//               },
//               child: const Text('Add'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showStampDialog(Offset position) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Select Symbol'),
//         content: SizedBox(
//           width: 350,
//           height: 450,
//           child: DefaultTabController(
//             length: 3,
//             child: Column(
//               children: [
//                 const TabBar(
//                   tabs: [
//                     Tab(text: 'Symbols'),
//                     Tab(text: 'Adult'),
//                     Tab(text: 'Pediatric'),
//                   ],
//                 ),
//                 Expanded(
//                   child: TabBarView(
//                     children: [
//                       _buildSymbolGrid(position, DentalConstants.dentalSymbols),
//                       _buildToothGrid(
//                           position, DentalConstants.adultTeeth, 'Tooth'),
//                       _buildToothGrid(
//                           position, DentalConstants.pediatricTeeth, 'Tooth'),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSymbolGrid(Offset position, Map<String, String> symbols) {
//     return GridView.builder(
//       padding: const EdgeInsets.all(8),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 4,
//         childAspectRatio: 1,
//         crossAxisSpacing: 8,
//         mainAxisSpacing: 8,
//       ),
//       itemCount: symbols.length,
//       itemBuilder: (context, index) {
//         final entry = symbols.entries.elementAt(index);
//         return Material(
//           elevation: 2,
//           borderRadius: BorderRadius.circular(8),
//           child: InkWell(
//             borderRadius: BorderRadius.circular(8),
//             onTap: () {
//               _addStamp(position, entry.value, entry.key);
//               Navigator.pop(context);
//             },
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     entry.value,
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                   const SizedBox(height: 4),
//                   Flexible(
//                     child: Text(
//                       entry.key,
//                       style: const TextStyle(fontSize: 10),
//                       textAlign: TextAlign.center,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildToothGrid(Offset position, List<String> teeth, String prefix) {
//     return GridView.builder(
//       padding: const EdgeInsets.all(8),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 6,
//         childAspectRatio: 1,
//         crossAxisSpacing: 8,
//         mainAxisSpacing: 8,
//       ),
//       itemCount: teeth.length,
//       itemBuilder: (context, index) {
//         final tooth = teeth[index];
//         return Material(
//           elevation: 2,
//           borderRadius: BorderRadius.circular(8),
//           color: Colors.blue.withOpacity(0.1),
//           child: InkWell(
//             borderRadius: BorderRadius.circular(8),
//             onTap: () {
//               _addStamp(position, tooth, '$prefix $tooth');
//               Navigator.pop(context);
//             },
//             child: Container(
//               padding: const EdgeInsets.all(4),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     tooth,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   Text(
//                     prefix,
//                     style: const TextStyle(
//                       fontSize: 8,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void _addStamp(Offset position, String symbol, String description) {
//     _canvasState.addElement(StampElement(
//       id: CanvasService.generateId(),
//       tool: DrawingTool.stamp,
//       paint: _canvasState.createPaint(),
//       layer: _canvasState.currentLayer,
//       position: position,
//       symbol: symbol,
//       size: _canvasState.currentStrokeWidth * 4,
//       description: description,
//     ));
//   }

//   // ==================== UI BUILDERS ====================
//   Widget _buildMainToolbar() {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isPhone =
//             constraints.maxWidth < 600; // Breakpoint for phone/tablet

//         return Container(
//           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
//           decoration: BoxDecoration(
//             color: Theme.of(context).cardColor,
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 4,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             alignment: WrapAlignment.start,
//             crossAxisAlignment: WrapCrossAlignment.center,
//             children: [
//               // Primary tools group
//               Wrap(
//                 spacing: 4,
//                 children: [
//                   _buildToolButton(
//                     icon: Icons.undo,
//                     onPressed: _canvasState.canUndo ? _canvasState.undo : null,
//                     tooltip: 'Undo',
//                     color: _canvasState.canUndo ? null : Colors.grey,
//                   ),
//                   _buildToolButton(
//                     icon: Icons.redo,
//                     onPressed: _canvasState.canRedo ? _canvasState.redo : null,
//                     tooltip: 'Redo',
//                     color: _canvasState.canRedo ? null : Colors.grey,
//                   ),
//                 ],
//               ),

//               // Current tool display
//               Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: isPhone ? 8 : 16,
//                   vertical: 8,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).primaryColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(
//                     color: Theme.of(context).primaryColor.withOpacity(0.3),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       _getToolIcon(_canvasState.currentTool),
//                       size: 16,
//                       color: Theme.of(context).primaryColor,
//                     ),
//                     if (!isPhone) ...[
//                       const SizedBox(width: 8),
//                       Text(
//                         _canvasState.currentTool.name.toUpperCase(),
//                         style: TextStyle(
//                           color: Theme.of(context).primaryColor,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),

//               // Stroke width slider
//               SizedBox(
//                 width: isPhone ? 100 : 120,
//                 height: 40,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     if (!isPhone)
//                       Text(
//                         'Size: ${_canvasState.currentStrokeWidth.toStringAsFixed(1)}',
//                         style:
//                             const TextStyle(fontSize: 10, color: Colors.grey),
//                       ),
//                     Expanded(
//                       child: Slider(
//                         value: _canvasState.currentStrokeWidth,
//                         min: 1.0,
//                         max: 20.0,
//                         divisions: 19,
//                         onChanged: _canvasState.setCurrentStrokeWidth,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Color picker button
//               GestureDetector(
//                 onTap: () => _showColorPicker(),
//                 child: Container(
//                   width: 32,
//                   height: 32,
//                   decoration: BoxDecoration(
//                     color: _canvasState.currentColor,
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.grey, width: 2),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.2),
//                         blurRadius: 4,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               if (!isPhone) const Spacer(),

//               // Layer indicator (only on tablets)
//               if (!isPhone)
//                 Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Text(
//                     _canvasState.currentLayer.displayName,
//                     style: const TextStyle(fontSize: 12),
//                   ),
//                 ),

//               // Action buttons
//               Wrap(
//                 spacing: 4,
//                 children: [
//                   _buildToolButton(
//                     icon: Icons.grid_on,
//                     onPressed: _canvasState.toggleGrid,
//                     tooltip: 'Toggle Grid',
//                     isActive: _canvasState.showGrid,
//                   ),
//                   _buildToolButton(
//                     icon: Icons.layers,
//                     onPressed: _toggleToolPanel,
//                     tooltip: 'Layers & Tools',
//                   ),
//                   _buildToolButton(
//                     icon: Icons.clear_all,
//                     onPressed:
//                         _canvasState.elements.isEmpty ? null : _showClearDialog,
//                     tooltip: 'Clear Canvas',
//                     color: Colors.red,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildToolButton({
//     required IconData icon,
//     required VoidCallback? onPressed,
//     required String tooltip,
//     Color? color,
//     bool isActive = false,
//   }) {
//     return Tooltip(
//       message: tooltip,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 2),
//         decoration: BoxDecoration(
//           color:
//               isActive ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: IconButton(
//           onPressed: onPressed,
//           icon: Icon(icon),
//           color: color ?? (onPressed != null ? null : Colors.grey),
//           iconSize: 20,
//         ),
//       ),
//     );
//   }

//   void _showColorPicker() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Select Color'),
//         content: Wrap(
//           children: DentalConstants.dentalColors.entries.map((entry) {
//             final isSelected = _canvasState.currentColor == entry.value;
//             return GestureDetector(
//               onTap: () {
//                 _canvasState.setCurrentColor(entry.value);
//                 setState(() {});
//                 Navigator.pop(context);
//               },
//               child: Container(
//                 margin: const EdgeInsets.all(4),
//                 width: 50,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: entry.value,
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: isSelected ? Colors.black : Colors.grey,
//                     width: isSelected ? 3 : 1,
//                   ),
//                 ),
//                 child: isSelected
//                     ? const Icon(Icons.check, color: Colors.white, size: 20)
//                     : null,
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   void _showClearDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Clear Canvas'),
//         content: const Text(
//             'Are you sure you want to clear all drawings? This action cannot be undone.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               _canvasState.clearCanvas();
//               Navigator.pop(context);
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text('Clear All'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSideToolPanel() {
//     return AnimatedBuilder(
//       animation: _toolPanelAnimation,
//       builder: (context, child) {
//         return Transform.translate(
//           offset: Offset(-320 * (1 - _toolPanelAnimation.value), 0),
//           child: Container(
//             width: 320,
//             height: double.infinity,
//             decoration: BoxDecoration(
//               color: Theme.of(context).cardColor,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.2),
//                   blurRadius: 8,
//                   offset: const Offset(4, 0),
//                 ),
//               ],
//             ),
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildPanelHeader(),
//                   _buildToolSelection(),
//                   _buildLayerControls(),
//                   _buildTemplateSelection(),
//                   _buildAdvancedSettings(),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildPanelHeader() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Theme.of(context).primaryColor.withOpacity(0.1),
//         border: Border(
//           bottom: BorderSide(
//             color: Colors.grey.withOpacity(0.3),
//           ),
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             Icons.palette,
//             color: Theme.of(context).primaryColor,
//           ),
//           const SizedBox(width: 12),
//           Text(
//             'Tools & Settings',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Theme.of(context).primaryColor,
//             ),
//           ),
//           const Spacer(),
//           IconButton(
//             onPressed: _toggleToolPanel,
//             icon: const Icon(Icons.close),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildToolSelection() {
//     return ExpansionTile(
//       title: const Text('Drawing Tools'),
//       initiallyExpanded: true,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 4,
//               childAspectRatio: 1,
//               crossAxisSpacing: 8,
//               mainAxisSpacing: 8,
//             ),
//             itemCount: DrawingTool.values.length,
//             itemBuilder: (context, index) {
//               final tool = DrawingTool.values[index];
//               final isSelected = _canvasState.currentTool == tool;

//               return Material(
//                 elevation: isSelected ? 4 : 2,
//                 borderRadius: BorderRadius.circular(12),
//                 color: isSelected
//                     ? Theme.of(context).primaryColor
//                     : Colors.grey[100],
//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(12),
//                   onTap: () => _canvasState.setCurrentTool(tool),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         _getToolIcon(tool),
//                         color: isSelected ? Colors.white : Colors.grey[700],
//                         size: 20,
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         tool.name,
//                         style: TextStyle(
//                           color: isSelected ? Colors.white : Colors.grey[700],
//                           fontSize: 10,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildLayerControls() {
//     return ListenableBuilder(
//       listenable: _canvasState,
//       builder: (context, child) {
//         return ExpansionTile(
//           title: Text('Layers (${_canvasState.elements.length} elements)'),
//           children: [
//             ...LayerType.values.map((layer) {
//               final elementCount =
//                   _canvasState.elements.where((e) => e.layer == layer).length;
//               final isVisible = _canvasState.layerVisibility[layer] ?? true;
//               final isActive = _canvasState.currentLayer == layer;

//               return Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: isActive
//                       ? Theme.of(context).primaryColor.withOpacity(0.1)
//                       : null,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: ListTile(
//                   dense: true,
//                   leading: IconButton(
//                     onPressed: () => _canvasState.toggleLayerVisibility(layer),
//                     icon: Icon(
//                       isVisible ? Icons.visibility : Icons.visibility_off,
//                       color: isVisible ? null : Colors.grey,
//                     ),
//                   ),
//                   title: Row(
//                     children: [
//                       Text(
//                         layer.displayName,
//                         style: TextStyle(
//                           fontWeight:
//                               isActive ? FontWeight.bold : FontWeight.normal,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 8, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: Colors.grey.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           elementCount.toString(),
//                           style: const TextStyle(fontSize: 10),
//                         ),
//                       ),
//                     ],
//                   ),
//                   onTap: () => _canvasState.setCurrentLayer(layer),
//                   trailing: elementCount > 0
//                       ? IconButton(
//                           icon: const Icon(Icons.clear, size: 16),
//                           onPressed: () => _showClearLayerDialog(layer),
//                         )
//                       : null,
//                 ),
//               );
//             }),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildTemplateSelection() {
//     return ListenableBuilder(
//       listenable: _canvasState,
//       builder: (context, child) {
//         return ExpansionTile(
//           title: const Text('Dental Templates'),
//           children: [
//             ...DentalTemplate.values.map((template) => ListTile(
//                   dense: true,
//                   leading: Icon(
//                     _getTemplateIcon(template),
//                     color: _canvasState.currentTemplate == template
//                         ? Theme.of(context).primaryColor
//                         : null,
//                   ),
//                   title: Text(_getTemplateName(template)),
//                   selected: _canvasState.currentTemplate == template,
//                   onTap: () => _canvasState.setCurrentTemplate(template),
//                 )),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildAdvancedSettings() {
//     return ListenableBuilder(
//       listenable: _canvasState,
//       builder: (context, child) {
//         return ExpansionTile(
//           title: const Text('Settings'),
//           children: [
//             SwitchListTile(
//               title: const Text('Auto-save'),
//               subtitle: const Text('Automatically save changes'),
//               value: _canvasState.autoSave,
//               onChanged: (_) => _canvasState.toggleAutoSave(),
//             ),
//             SwitchListTile(
//               title: const Text('Show Grid'),
//               subtitle: const Text('Display grid overlay'),
//               value: _canvasState.showGrid,
//               onChanged: (_) => _canvasState.toggleGrid(),
//             ),
//             ListTile(
//               leading: const Icon(Icons.zoom_out_map),
//               title: const Text('Reset Zoom'),
//               subtitle: const Text('Reset canvas zoom and position'),
//               onTap: () {
//                 _transformationController.value = Matrix4.identity();
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.save),
//               title: const Text('Export Canvas'),
//               subtitle: const Text('Save current work'),
//               onTap: _exportCanvas,
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showClearLayerDialog(LayerType layer) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Clear ${layer.displayName} Layer'),
//         content: Text(
//             'Are you sure you want to clear all elements from the ${layer.displayName} layer?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               _canvasState.clearLayer(layer);
//               Navigator.pop(context);
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text('Clear Layer'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _toggleToolPanel() {
//     setState(() {
//       _showToolPanel = !_showToolPanel;
//     });

//     if (_showToolPanel) {
//       _toolPanelController.forward();
//     } else {
//       _toolPanelController.reverse();
//     }
//   }

//   // ==================== HELPER METHODS ====================
//   IconData _getToolIcon(DrawingTool tool) {
//     switch (tool) {
//       case DrawingTool.pen:
//         return Icons.edit;
//       case DrawingTool.eraser:
//         return Icons.cleaning_services;
//       case DrawingTool.circle:
//         return Icons.radio_button_unchecked;
//       case DrawingTool.arrow:
//         return Icons.arrow_forward;
//       case DrawingTool.line:
//         return Icons.remove;
//       case DrawingTool.rectangle:
//         return Icons.crop_din;
//       case DrawingTool.text:
//         return Icons.text_fields;
//       case DrawingTool.stamp:
//         return Icons.star;
//       case DrawingTool.ruler:
//         return Icons.straighten;
//       case DrawingTool.highlighter:
//         return Icons.highlight;
//       case DrawingTool.freeform:
//         return Icons.gesture;
//     }
//   }

//   IconData _getTemplateIcon(DentalTemplate template) {
//     switch (template) {
//       case DentalTemplate.none:
//         return Icons.clear;
//       case DentalTemplate.adultOdontogram:
//         return Icons.grid_on;
//       case DentalTemplate.pediatricOdontogram:
//         return Icons.child_care;
//       case DentalTemplate.periodontalChart:
//         return Icons.timeline;
//       case DentalTemplate.oralCavityFrontal:
//         return Icons.face;
//       case DentalTemplate.oralCavityLateral:
//         return Icons.face_retouching_natural;
//       case DentalTemplate.bitewing:
//         return Icons.view_sidebar;
//       case DentalTemplate.panoramic:
//         return Icons.panorama;
//     }
//   }

//   String _getTemplateName(DentalTemplate template) {
//     switch (template) {
//       case DentalTemplate.none:
//         return 'None';
//       case DentalTemplate.adultOdontogram:
//         return 'Adult Odontogram';
//       case DentalTemplate.pediatricOdontogram:
//         return 'Pediatric Odontogram';
//       case DentalTemplate.periodontalChart:
//         return 'Periodontal Chart';
//       case DentalTemplate.oralCavityFrontal:
//         return 'Oral Cavity (Front)';
//       case DentalTemplate.oralCavityLateral:
//         return 'Oral Cavity (Side)';
//       case DentalTemplate.bitewing:
//         return 'Bitewing X-ray';
//       case DentalTemplate.panoramic:
//         return 'Panoramic X-ray';
//     }
//   }

//   // ==================== ASYNC OPERATIONS ====================
//   Future<void> _selectDate() async {
//     final pickedDate = await showDatePicker(
//       context: context,
//       initialDate: _canvasState.selectedDateTime,
//       firstDate: DateTime(2000),
//       lastDate: DateTime.now(),
//     );

//     if (pickedDate != null) {
//       final pickedTime = await showTimePicker(
//         context: context,
//         initialTime: TimeOfDay.fromDateTime(_canvasState.selectedDateTime),
//       );

//       if (pickedTime != null) {
//         final newDateTime = DateTime(
//           pickedDate.year,
//           pickedDate.month,
//           pickedDate.day,
//           pickedTime.hour,
//           pickedTime.minute,
//         );
//         _canvasState.setSelectedDateTime(newDateTime);
//       }
//     }
//   }

//   Future<void> _captureAndUploadImage() async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final XFile? photo = await picker.pickImage(
//         source: ImageSource.camera,
//         imageQuality: 85,
//       );

//       if (photo != null) {
//         final File imageFile = File(photo.path);
//         final Uint8List imageBytes = await imageFile.readAsBytes();
//         final String base64Image = base64Encode(imageBytes);

//         // Here you would typically upload to your server
//         _showSuccessMessage('Photo captured successfully');
//       }
//     } catch (e) {
//       _showErrorMessage('Failed to capture image: ${e.toString()}');
//     }
//   }

//   Future<void> _exportCanvas() async {
//     try {
//       final base64Image = await CanvasService.exportToBase64(_canvasKey);

//       // Here you would save or share the image
//       _showSuccessMessage('Canvas exported successfully');

//       // For demonstration, we'll show export options
//       _showExportDialog(base64Image);
//     } catch (e) {
//       _showErrorMessage('Failed to export canvas: ${e.toString()}');
//     }
//   }

//   void _showExportDialog(String base64Image) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Export Options'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.save),
//               title: const Text('Save to Gallery'),
//               onTap: () {
//                 Navigator.pop(context);
//                 // Implement save to gallery
//                 _showSuccessMessage('Saved to gallery');
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.share),
//               title: const Text('Share'),
//               onTap: () {
//                 Navigator.pop(context);
//                 // Implement sharing
//                 _showSuccessMessage('Sharing...');
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.cloud_upload),
//               title: const Text('Upload to Server'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _uploadToServer(base64Image);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _uploadToServer(String base64Image) async {
//     try {
//       // Show loading dialog
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const AlertDialog(
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(height: 16),
//               Text('Uploading...'),
//             ],
//           ),
//         ),
//       );

//       // Simulate upload process
//       await Future.delayed(const Duration(seconds: 2));

//       if (mounted) {
//         Navigator.pop(context); // Close loading dialog
//         _showSuccessMessage('Canvas uploaded successfully');

//         // Return to previous screen after successful upload
//         Future.delayed(const Duration(seconds: 1), () {
//           if (mounted) {
//             Navigator.of(context).pop(true);
//           }
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         Navigator.pop(context); // Close loading dialog
//         _showErrorMessage('Failed to upload canvas: ${e.toString()}');
//       }
//     }
//   }

//   void _showErrorMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.error, color: Colors.white),
//             const SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showSuccessMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.check_circle, color: Colors.white),
//             const SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   String _formatDateTime(DateTime dateTime) {
//     return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
//   }

//   // ==================== BUILD METHOD ====================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).cardColor,
//         elevation: 2,
//         title: Text(
//           'Patient ${widget.patientId} Dental Notes',
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.menu),
//           onPressed: _toggleToolPanel,
//         ),
//         actions: [
//           TextButton.icon(
//             onPressed: _selectDate,
//             icon: const Icon(Icons.calendar_today, size: 16),
//             label: Text(_formatDateTime(_canvasState.selectedDateTime)),
//             style: TextButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//             ),
//           ),
//           IconButton(
//             onPressed: _captureAndUploadImage,
//             icon: const Icon(Icons.camera_alt),
//             tooltip: 'Take Photo',
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               _buildMainToolbar(),
//               Expanded(
//                 child: InteractiveViewer(
//                   transformationController: _transformationController,
//                   minScale: 0.3,
//                   maxScale: 5.0,
//                   boundaryMargin: const EdgeInsets.all(100),
//                   child: GestureDetector(
//                     onPanStart: _handlePanStart,
//                     onPanUpdate: _handlePanUpdate,
//                     onPanEnd: _handlePanEnd,
//                     onTapUp: _handleTap,
//                     child: Container(
//                       key: _canvasKey,
//                       width: double.infinity,
//                       height: double.infinity,
//                       color: Colors.white,
//                       child: ListenableBuilder(
//                         listenable: _canvasState,
//                         builder: (context, child) {
//                           return CustomPaint(
//                             painter: EnhancedDentalPainter(
//                               elements: _canvasState.visibleElements,
//                               currentPath: _currentPath,
//                               currentTool: _canvasState.currentTool,
//                               currentPaint: _canvasState.createPaint(),
//                               startPoint: _startPoint,
//                               currentPoint: _currentPoint,
//                               template: _canvasState.currentTemplate,
//                               showGrid: _canvasState.showGrid,
//                               isDrawing: _isDrawing,
//                             ),
//                             size: Size.infinite,
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           if (_showToolPanel) _buildSideToolPanel(),
//         ],
//       ),
//       floatingActionButton: ListenableBuilder(
//         listenable: _canvasState,
//         builder: (context, child) {
//           return _canvasState.elements.isNotEmpty
//               ? FloatingActionButton.extended(
//                   onPressed: () => _uploadToServer(''),
//                   icon: const Icon(Icons.upload),
//                   label: const Text('Upload Notes'),
//                   backgroundColor: Theme.of(context).primaryColor,
//                 )
//               : FloatingActionButton(
//                   onPressed: () =>
//                       _showErrorMessage('No notes available to upload'),
//                   backgroundColor: Colors.grey,
//                   child: const Icon(Icons.upload),
//                 );
//         },
//       ),
//     );
//   }
// }

// // ==================== ENHANCED PAINTER ====================
// class EnhancedDentalPainter extends CustomPainter {
//   final List<DrawingElement> elements;
//   final Path? currentPath;
//   final DrawingTool currentTool;
//   final Paint currentPaint;
//   final Offset? startPoint;
//   final Offset? currentPoint;
//   final DentalTemplate template;
//   final bool showGrid;
//   final bool isDrawing;

//   EnhancedDentalPainter({
//     required this.elements,
//     this.currentPath,
//     required this.currentTool,
//     required this.currentPaint,
//     this.startPoint,
//     this.currentPoint,
//     required this.template,
//     required this.showGrid,
//     required this.isDrawing,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     // Draw grid if enabled
//     if (showGrid) {
//       _drawGrid(canvas, size);
//     }

//     // Draw template background
//     _drawTemplate(canvas, size);

//     // Sort elements by layer order and timestamp
//     final sortedElements = List<DrawingElement>.from(elements);
//     sortedElements.sort((a, b) {
//       final layerComparison = a.layer.order.compareTo(b.layer.order);
//       if (layerComparison != 0) return layerComparison;
//       return a.timestamp.compareTo(b.timestamp);
//     });

//     // Draw all elements
//     for (final element in sortedElements) {
//       _drawElement(canvas, element);
//     }

//     // Draw current drawing action
//     _drawCurrentAction(canvas, size);
//   }

//   void _drawGrid(Canvas canvas, Size size) {
//     final gridPaint = Paint()
//       ..color = Colors.grey.withOpacity(0.2)
//       ..strokeWidth = 0.5
//       ..style = PaintingStyle.stroke;

//     const gridSize = 20.0;

//     // Draw vertical lines
//     for (double x = 0; x <= size.width; x += gridSize) {
//       canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
//     }

//     // Draw horizontal lines
//     for (double y = 0; y <= size.height; y += gridSize) {
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
//     }
//   }

//   void _drawTemplate(Canvas canvas, Size size) {
//     if (template == DentalTemplate.none) return;

//     final templatePaint = Paint()
//       ..color = Colors.blue.withOpacity(0.3)
//       ..strokeWidth = 1.5
//       ..style = PaintingStyle.stroke;

//     final fillPaint = Paint()
//       ..color = Colors.blue.withOpacity(0.05)
//       ..style = PaintingStyle.fill;

//     switch (template) {
//       case DentalTemplate.adultOdontogram:
//         _drawAdultOdontogram(canvas, size, templatePaint, fillPaint);
//         break;
//       case DentalTemplate.pediatricOdontogram:
//         _drawPediatricOdontogram(canvas, size, templatePaint, fillPaint);
//         break;
//       case DentalTemplate.periodontalChart:
//         _drawPeriodontalChart(canvas, size, templatePaint, fillPaint);
//         break;
//       case DentalTemplate.oralCavityFrontal:
//         _drawOralCavityFrontal(canvas, size, templatePaint, fillPaint);
//         break;
//       case DentalTemplate.oralCavityLateral:
//         _drawOralCavityLateral(canvas, size, templatePaint, fillPaint);
//         break;
//       case DentalTemplate.bitewing:
//         _drawBitewingTemplate(canvas, size, templatePaint, fillPaint);
//         break;
//       case DentalTemplate.panoramic:
//         _drawPanoramicTemplate(canvas, size, templatePaint, fillPaint);
//         break;
//       case DentalTemplate.none:
//         break;
//     }
//   }

//   void _drawAdultOdontogram(
//       Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {
//     final centerX = size.width / 2;
//     final centerY = size.height / 2;
//     final toothSize = math.min(size.width / 20, size.height / 10);
//     final spacing = toothSize * 1.2;

//     // Upper arch (teeth 11-18, 21-28)
//     final upperTeeth = [
//       '18',
//       '17',
//       '16',
//       '15',
//       '14',
//       '13',
//       '12',
//       '11',
//       '21',
//       '22',
//       '23',
//       '24',
//       '25',
//       '26',
//       '27',
//       '28'
//     ];

//     for (int i = 0; i < upperTeeth.length; i++) {
//       final x = centerX - (8 * spacing) + (i * spacing);
//       final y = centerY - toothSize * 2;
//       _drawTooth(canvas, Offset(x, y), toothSize, strokePaint, fillPaint,
//           upperTeeth[i]);
//     }

//     // Lower arch (teeth 41-48, 31-38)
//     final lowerTeeth = [
//       '48',
//       '47',
//       '46',
//       '45',
//       '44',
//       '43',
//       '42',
//       '41',
//       '31',
//       '32',
//       '33',
//       '34',
//       '35',
//       '36',
//       '37',
//       '38'
//     ];

//     for (int i = 0; i < lowerTeeth.length; i++) {
//       final x = centerX - (8 * spacing) + (i * spacing);
//       final y = centerY + toothSize * 2;
//       _drawTooth(canvas, Offset(x, y), toothSize, strokePaint, fillPaint,
//           lowerTeeth[i]);
//     }

//     // Draw arch guides
//     _drawArchGuides(
//         canvas, centerX, centerY, spacing * 8, toothSize * 2, strokePaint);
//   }

//   void _drawPediatricOdontogram(
//       Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {
//     final centerX = size.width / 2;
//     final centerY = size.height / 2;
//     final toothSize = math.min(size.width / 16, size.height / 8);
//     final spacing = toothSize * 1.2;

//     // Upper teeth
//     const upperTeeth = ['E', 'D', 'C', 'B', 'A', 'A', 'B', 'C', 'D', 'E'];
//     for (int i = 0; i < upperTeeth.length; i++) {
//       final x = centerX - (5 * spacing) + (i * spacing);
//       final y = centerY - toothSize * 1.5;
//       _drawTooth(canvas, Offset(x, y), toothSize, strokePaint, fillPaint,
//           upperTeeth[i]);
//     }

//     // Lower teeth
//     const lowerTeeth = ['O', 'N', 'M', 'L', 'K', 'K', 'L', 'M', 'N', 'O'];
//     for (int i = 0; i < lowerTeeth.length; i++) {
//       final x = centerX - (5 * spacing) + (i * spacing);
//       final y = centerY + toothSize * 1.5;
//       _drawTooth(canvas, Offset(x, y), toothSize, strokePaint, fillPaint,
//           lowerTeeth[i]);
//     }

//     // Draw smaller arch guides for pediatric
//     _drawArchGuides(
//         canvas, centerX, centerY, spacing * 5, toothSize * 1.5, strokePaint);
//   }

//   void _drawPeriodontalChart(
//       Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {
//     final startX = size.width * 0.1;
//     final startY = size.height / 2;
//     final toothWidth = (size.width * 0.8) / 32;
//     final chartHeight = size.height * 0.6;

//     // Draw measurement grid
//     for (int i = 0; i < 32; i++) {
//       final x = startX + (i * toothWidth);

//       // Draw tooth column
//       final rect =
//           Rect.fromLTWH(x, startY - chartHeight / 2, toothWidth, chartHeight);
//       canvas.drawRect(rect, fillPaint);
//       canvas.drawRect(rect, strokePaint);

//       // Draw measurement lines (1-12mm scale)
//       for (int j = 1; j < 12; j++) {
//         final y = startY - chartHeight / 2 + (j * chartHeight / 12);
//         final linePaint = Paint()
//           ..color = j <= 3
//               ? Colors.green.withOpacity(0.3)
//               : j <= 5
//                   ? Colors.yellow.withOpacity(0.3)
//                   : Colors.red.withOpacity(0.3)
//           ..strokeWidth = 0.5;
//         canvas.drawLine(Offset(x, y), Offset(x + toothWidth, y), linePaint);

//         // Add measurement numbers
//         if (i == 0) {
//           _drawText(canvas, Offset(x - 20, y - 5), j.toString(), 8,
//               Colors.grey[600]!);
//         }
//       }

//       // Draw tooth number
//       final toothNumber = i < 16 ? (18 - i).toString() : (i + 17).toString();
//       _drawText(
//           canvas,
//           Offset(x + toothWidth / 2 - 8, startY + chartHeight / 2 + 10),
//           toothNumber,
//           10,
//           Colors.black);
//     }
//   }

//   void _drawOralCavityFrontal(
//       Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {
//     final centerX = size.width / 2;
//     final centerY = size.height / 2;

//     // Draw main oral cavity outline
//     final oralPath = Path();
//     final ovalRect = Rect.fromCenter(
//       center: Offset(centerX, centerY),
//       width: size.width * 0.7,
//       height: size.height * 0.5,
//     );
//     oralPath.addOval(ovalRect);
//     canvas.drawPath(oralPath, fillPaint);
//     canvas.drawPath(oralPath, strokePaint);

//     // Draw dental arches
//     final upperArchPath = Path();
//     upperArchPath.addArc(
//       Rect.fromCenter(
//         center: Offset(centerX, centerY - size.height * 0.1),
//         width: size.width * 0.5,
//         height: size.height * 0.15,
//       ),
//       0,
//       math.pi,
//     );
//     canvas.drawPath(upperArchPath, strokePaint);

//     final lowerArchPath = Path();
//     lowerArchPath.addArc(
//       Rect.fromCenter(
//         center: Offset(centerX, centerY + size.height * 0.1),
//         width: size.width * 0.5,
//         height: size.height * 0.15,
//       ),
//       math.pi,
//       math.pi,
//     );
//     canvas.drawPath(lowerArchPath, strokePaint);

//     // Draw anatomical landmarks
//     _drawAnatomicalLandmarks(canvas, centerX, centerY, size, strokePaint);
//   }

//   void _drawOralCavityLateral(
//       Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {
//     final centerX = size.width / 2;
//     final centerY = size.height / 2;

//     // Draw side profile of oral cavity
//     final profilePath = Path();
//     profilePath.moveTo(centerX - size.width * 0.2, centerY - size.height * 0.2);
//     profilePath.quadraticBezierTo(
//         centerX + size.width * 0.1,
//         centerY - size.height * 0.25,
//         centerX + size.width * 0.25,
//         centerY - size.height * 0.15);
//     profilePath.quadraticBezierTo(centerX + size.width * 0.27, centerY,
//         centerX + size.width * 0.23, centerY + size.height * 0.15);
//     profilePath.quadraticBezierTo(
//         centerX + size.width * 0.1,
//         centerY + size.height * 0.25,
//         centerX - size.width * 0.2,
//         centerY + size.height * 0.2);
//     profilePath.quadraticBezierTo(centerX - size.width * 0.22, centerY,
//         centerX - size.width * 0.2, centerY - size.height * 0.2);

//     canvas.drawPath(profilePath, fillPaint);
//     canvas.drawPath(profilePath, strokePaint);

//     // Draw teeth profile
//     for (int i = 0; i < 8; i++) {
//       final x = centerX - size.width * 0.15 + (i * size.width * 0.04);
//       final y1 = centerY - size.height * 0.1;
//       final y2 = centerY + size.height * 0.1;
//       canvas.drawLine(
//           Offset(x, y1), Offset(x, y1 + size.height * 0.05), strokePaint);
//       canvas.drawLine(
//           Offset(x, y2), Offset(x, y2 - size.height * 0.05), strokePaint);
//     }
//   }

//   void _drawBitewingTemplate(
//       Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {
//     final centerX = size.width / 2;
//     final centerY = size.height / 2;
//     final sectionWidth = size.width * 0.4;
//     final sectionHeight = size.height * 0.3;

//     // Left bitewing
//     final leftRect = Rect.fromCenter(
//       center: Offset(centerX - size.width * 0.2, centerY),
//       width: sectionWidth,
//       height: sectionHeight,
//     );
//     canvas.drawRect(leftRect, fillPaint);
//     canvas.drawRect(leftRect, strokePaint);
//     _drawText(canvas, Offset(leftRect.left + 10, leftRect.top + 10),
//         'LEFT BITEWING', 12, Colors.black);

//     // Right bitewing
//     final rightRect = Rect.fromCenter(
//       center: Offset(centerX + size.width * 0.2, centerY),
//       width: sectionWidth,
//       height: sectionHeight,
//     );
//     canvas.drawRect(rightRect, fillPaint);
//     canvas.drawRect(rightRect, strokePaint);
//     _drawText(canvas, Offset(rightRect.left + 10, rightRect.top + 10),
//         'RIGHT BITEWING', 12, Colors.black);

//     // Draw crown and root separation lines
//     final separationPaint = Paint()
//       ..color = Colors.grey.withOpacity(0.5)
//       ..strokeWidth = 1.0
//       ..style = PaintingStyle.stroke;

//     canvas.drawLine(Offset(leftRect.left, centerY),
//         Offset(leftRect.right, centerY), separationPaint);
//     canvas.drawLine(Offset(rightRect.left, centerY),
//         Offset(rightRect.right, centerY), separationPaint);
//   }

//   void _drawPanoramicTemplate(
//       Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {
//     final centerX = size.width / 2;
//     final centerY = size.height / 2;

//     // Draw panoramic outline
//     final panoramicPath = Path();
//     panoramicPath.addArc(
//       Rect.fromCenter(
//         center: Offset(centerX, centerY),
//         width: size.width * 0.9,
//         height: size.height * 0.6,
//       ),
//       0,
//       2 * math.pi,
//     );
//     canvas.drawPath(panoramicPath, fillPaint);
//     canvas.drawPath(panoramicPath, strokePaint);

//     // Draw anatomical reference lines
//     final referencePaint = Paint()
//       ..color = Colors.grey.withOpacity(0.4)
//       ..strokeWidth = 1.0
//       ..style = PaintingStyle.stroke;

//     // Maxillary line
//     canvas.drawLine(Offset(size.width * 0.1, centerY - size.height * 0.1),
//         Offset(size.width * 0.9, centerY - size.height * 0.1), referencePaint);

//     // Mandibular line
//     canvas.drawLine(Offset(size.width * 0.1, centerY + size.height * 0.1),
//         Offset(size.width * 0.9, centerY + size.height * 0.1), referencePaint);

//     // Add labels
//     _drawText(canvas, Offset(10, centerY - size.height * 0.15), 'MAXILLA', 10,
//         Colors.grey[600]!);
//     _drawText(canvas, Offset(10, centerY + size.height * 0.05), 'MANDIBLE', 10,
//         Colors.grey[600]!);
//   }

//   void _drawTooth(Canvas canvas, Offset center, double size, Paint strokePaint,
//       Paint fillPaint, String number) {
//     // Draw tooth shape with rounded corners
//     final rect = Rect.fromCenter(center: center, width: size, height: size);
//     final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size * 0.15));

//     canvas.drawRRect(rrect, fillPaint);
//     canvas.drawRRect(rrect, strokePaint);

//     // Draw tooth surfaces
//     final surfacePaint = Paint()
//       ..color = Colors.grey.withOpacity(0.2)
//       ..strokeWidth = 0.5
//       ..style = PaintingStyle.stroke;

//     // Mesial and Distal lines
//     canvas.drawLine(Offset(center.dx - size / 3, rect.top),
//         Offset(center.dx - size / 3, rect.bottom), surfacePaint);
//     canvas.drawLine(Offset(center.dx + size / 3, rect.top),
//         Offset(center.dx + size / 3, rect.bottom), surfacePaint);

//     // Buccal and Lingual lines
//     canvas.drawLine(Offset(rect.left, center.dy - size / 3),
//         Offset(rect.right, center.dy - size / 3), surfacePaint);
//     canvas.drawLine(Offset(rect.left, center.dy + size / 3),
//         Offset(rect.right, center.dy + size / 3), surfacePaint);

//     // Draw tooth number
//     _drawText(canvas, Offset(center.dx - 6, center.dy - 6), number, size * 0.25,
//         Colors.black);
//   }

//   void _drawArchGuides(Canvas canvas, double centerX, double centerY,
//       double width, double height, Paint paint) {
//     final guidePaint = Paint()
//       ..color = paint.color.withOpacity(0.5)
//       ..strokeWidth = 1.0
//       ..style = PaintingStyle.stroke;

//     // Upper arch guide
//     final upperArchPath = Path();
//     upperArchPath.addArc(
//       Rect.fromCenter(
//         center: Offset(centerX, centerY - height),
//         width: width,
//         height: height * 0.8,
//       ),
//       0,
//       math.pi,
//     );
//     canvas.drawPath(upperArchPath, guidePaint);

//     // Lower arch guide
//     final lowerArchPath = Path();
//     lowerArchPath.addArc(
//       Rect.fromCenter(
//         center: Offset(centerX, centerY + height),
//         width: width,
//         height: height * 0.8,
//       ),
//       math.pi,
//       math.pi,
//     );
//     canvas.drawPath(lowerArchPath, guidePaint);
//   }

//   void _drawAnatomicalLandmarks(
//       Canvas canvas, double centerX, double centerY, Size size, Paint paint) {
//     final landmarkPaint = Paint()
//       ..color = Colors.grey.withOpacity(0.6)
//       ..strokeWidth = 1.0
//       ..style = PaintingStyle.stroke;

//     // Draw tongue outline
//     final tongueRect = Rect.fromCenter(
//       center: Offset(centerX, centerY + size.height * 0.05),
//       width: size.width * 0.3,
//       height: size.height * 0.2,
//     );
//     canvas.drawOval(tongueRect, landmarkPaint);

//     // Draw lips
//     canvas.drawLine(
//         Offset(centerX - size.width * 0.35, centerY - size.height * 0.25),
//         Offset(centerX + size.width * 0.35, centerY - size.height * 0.25),
//         landmarkPaint);
//     canvas.drawLine(
//         Offset(centerX - size.width * 0.35, centerY + size.height * 0.25),
//         Offset(centerX + size.width * 0.35, centerY + size.height * 0.25),
//         landmarkPaint);
//   }

//   void _drawElement(Canvas canvas, DrawingElement element) {
//     if (element is PathElement) {
//       canvas.drawPath(element.path, element.paint);
//     } else if (element is ShapeElement) {
//       _drawShape(canvas, element);
//     } else if (element is StampElement) {
//       _drawStamp(canvas, element);
//     } else if (element is TextElement) {
//       _drawTextElement(canvas, element);
//     }
//   }

//   void _drawShape(Canvas canvas, ShapeElement element) {
//     switch (element.tool) {
//       case DrawingTool.line:
//         canvas.drawLine(element.startPoint, element.endPoint, element.paint);
//         break;
//       case DrawingTool.circle:
//         final radius = (element.endPoint - element.startPoint).distance / 2;
//         final center = Offset(
//           (element.startPoint.dx + element.endPoint.dx) / 2,
//           (element.startPoint.dy + element.endPoint.dy) / 2,
//         );
//         canvas.drawCircle(center, radius, element.paint);
//         break;
//       case DrawingTool.rectangle:
//         final rect = Rect.fromPoints(element.startPoint, element.endPoint);
//         canvas.drawRect(rect, element.paint);
//         break;
//       case DrawingTool.arrow:
//         _drawArrow(canvas, element.startPoint, element.endPoint, element.paint);
//         break;
//       case DrawingTool.ruler:
//         _drawRuler(canvas, element.startPoint, element.endPoint, element.paint);
//         break;
//       default:
//         break;
//     }
//   }

//   void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
//     // Draw main line
//     canvas.drawLine(start, end, paint);

//     // Calculate arrowhead
//     final direction = end - start;
//     final length = direction.distance;
//     if (length == 0) return;

//     final unitVector = direction / length;
//     final arrowLength = math.min(20.0, length * 0.3);
//     const arrowAngle = math.pi / 6;

//     final arrowPoint1 = end -
//         Offset(
//           unitVector.dx * arrowLength * math.cos(arrowAngle) -
//               unitVector.dy * arrowLength * math.sin(arrowAngle),
//           unitVector.dy * arrowLength * math.cos(arrowAngle) +
//               unitVector.dx * arrowLength * math.sin(arrowAngle),
//         );

//     final arrowPoint2 = end -
//         Offset(
//           unitVector.dx * arrowLength * math.cos(-arrowAngle) -
//               unitVector.dy * arrowLength * math.sin(-arrowAngle),
//           unitVector.dy * arrowLength * math.cos(-arrowAngle) +
//               unitVector.dx * arrowLength * math.sin(-arrowAngle),
//         );

//     // Draw arrowhead
//     canvas.drawLine(end, arrowPoint1, paint);
//     canvas.drawLine(end, arrowPoint2, paint);

//     // Fill arrowhead
//     final arrowPath = Path();
//     arrowPath.moveTo(end.dx, end.dy);
//     arrowPath.lineTo(arrowPoint1.dx, arrowPoint1.dy);
//     arrowPath.lineTo(arrowPoint2.dx, arrowPoint2.dy);
//     arrowPath.close();
//     canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
//   }

//   void _drawRuler(Canvas canvas, Offset start, Offset end, Paint paint) {
//     // Draw main line
//     canvas.drawLine(start, end, paint);

//     final direction = end - start;
//     final length = direction.distance;
//     if (length == 0) return;

//     final unitVector = direction / length;
//     final perpVector = Offset(-unitVector.dy, unitVector.dx);

//     const markLength = 8.0;
//     final numMarks = (length / 10).round().clamp(2, 20);

//     // Draw measurement marks
//     for (int i = 0; i <= numMarks; i++) {
//       final t = i / numMarks;
//       final point = start + direction * t;
//       final markStart = point - perpVector * markLength;
//       final markEnd = point + perpVector * markLength;
//       canvas.drawLine(markStart, markEnd, paint);
//     }

//     // Draw distance text
//     final distance =
//         (length / 10).toStringAsFixed(1); // Convert to cm approximation
//     final center = (start + end) / 2;
//     final textOffset = perpVector * (markLength + 15);
//     _drawText(canvas, center + textOffset, '${distance}cm', 10, paint.color);
//   }

//   void _drawStamp(Canvas canvas, StampElement element) {
//     _drawText(
//       canvas,
//       element.position - Offset(element.size / 4, element.size / 4),
//       element.symbol,
//       element.size,
//       element.paint.color,
//       FontWeight.bold,
//     );
//   }

//   void _drawTextElement(Canvas canvas, TextElement element) {
//     _drawText(
//       canvas,
//       element.position,
//       element.text,
//       element.fontSize,
//       element.paint.color,
//       element.fontWeight,
//     );
//   }

//   void _drawText(
//       Canvas canvas, Offset position, String text, double fontSize, Color color,
//       [FontWeight fontWeight = FontWeight.normal]) {
//     final textPainter = TextPainter(
//       text: TextSpan(
//         text: text,
//         style: TextStyle(
//           color: color,
//           fontSize: fontSize,
//           fontWeight: fontWeight,
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, position);
//   }

//   void _drawCurrentAction(Canvas canvas, Size size) {
//     if (!isDrawing) return;

//     switch (currentTool) {
//       case DrawingTool.pen:
//       case DrawingTool.highlighter:
//         if (currentPath != null) {
//           final previewPaint = Paint()
//             ..color = currentPaint.color.withOpacity(0.7)
//             ..strokeWidth = currentPaint.strokeWidth
//             ..strokeCap = currentPaint.strokeCap
//             ..style = currentPaint.style;
//           canvas.drawPath(currentPath!, previewPaint);
//         }
//         break;

//       case DrawingTool.circle:
//       case DrawingTool.rectangle:
//       case DrawingTool.line:
//       case DrawingTool.arrow:
//       case DrawingTool.ruler:
//         if (startPoint != null && currentPoint != null) {
//           final previewPaint = Paint()
//             ..color = currentPaint.color.withOpacity(0.5)
//             ..strokeWidth = currentPaint.strokeWidth
//             ..strokeCap = currentPaint.strokeCap
//             ..style = currentPaint.style;

//           final previewElement = ShapeElement(
//             id: 'preview',
//             tool: currentTool,
//             paint: previewPaint,
//             layer: LayerType.overlay,
//             startPoint: startPoint!,
//             endPoint: currentPoint!,
//           );
//           _drawShape(canvas, previewElement);
//         }
//         break;

//       default:
//         break;
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return oldDelegate is! EnhancedDentalPainter ||
//         oldDelegate.elements.length != elements.length ||
//         oldDelegate.currentPath != currentPath ||
//         oldDelegate.currentTool != currentTool ||
//         oldDelegate.startPoint != startPoint ||
//         oldDelegate.currentPoint != currentPoint ||
//         oldDelegate.template != template ||
//         oldDelegate.showGrid != showGrid ||
//         oldDelegate.isDrawing != isDrawing;
//   }
// }
