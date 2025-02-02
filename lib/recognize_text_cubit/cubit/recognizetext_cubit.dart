// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:bloc/bloc.dart';
// import 'package:meta/meta.dart';
// import 'package:image/image.dart' as img;
// import 'package:flutter/material.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:path_provider/path_provider.dart';
// part 'recognizetext_state.dart';

// class RecognizetextCubit extends Cubit<RecognizetextState> {
//   RecognizetextCubit() : super(RecognizetextInitial());
//   Future<void> recognizeText(String base64Image) async {
//     emit(Recognizingtext());
//     try {
//       String concatenatedRecognizedText = "";
//       // Decode the Base64 string into Uint8List (binary data)
//       Uint8List imageBytes = base64Decode(base64Image);
//       // Save the image to a temporary file
//       final tempDir = await getTemporaryDirectory();
//       final tempFile = File('${tempDir.path}/temp_image.jpg');
//       await tempFile.writeAsBytes(imageBytes);

//       // Create InputImage from file path
//       final inputImage = InputImage.fromFilePath(tempFile.path);

//       // Create text recognizer
//       final textRecognizer = TextRecognizer();

//       // Process the image and extract text
//       final RecognizedText recognizedText =
//           await textRecognizer.processImage(inputImage);

//       // Print the recognized text
//       for (TextBlock block in recognizedText.blocks) {
//         for (TextLine line in block.lines) {
//           concatenatedRecognizedText += "${line.text}\n";
//         }
//       }
//       emit(RecognizetextSuccess(text: concatenatedRecognizedText));
//       // Dispose of the text recognizer to free resources
//       textRecognizer.close();
//     } catch (e) {
//       emit(RecognizetextFailed(message: e.toString()));
//     }
//   }

//   Future<void> recognizeText1(String base64Image) async {
//     emit(Recognizingtext());
//     try {
//       // Decode the Base64 string into Uint8List (binary data)
//       Uint8List imageBytes = base64Decode(base64Image);

//       // Decode the image using the 'image' package
//       img.Image? image = img.decodeImage(imageBytes);

//       if (image == null) {
//         throw 'Image decoding failed';
//       }
//       // Convert the image to grayscale to improve recognition
//       img.Image grayImage = img.grayscale(image);

//       // Optional: Apply thresholding to make the text clearer
//       img.Image thresholdedImage = img.luminanceThreshold(grayImage);

//       // Save the processed image to a temporary file for further processing
//       final tempDir = await getTemporaryDirectory();
//       final tempFile = File('${tempDir.path}/processed_image.jpg');
//       tempFile.writeAsBytesSync(img.encodeJpg(thresholdedImage));

//       // Create InputImage from the processed image file
//       final inputImage = InputImage.fromFilePath(tempFile.path);

//       // Create a text recognizer
//       final textRecognizer = TextRecognizer();

//       // Process the image and extract text
//       final RecognizedText recognizedText =
//           await textRecognizer.processImage(inputImage);

//       // Output the recognized text
//       String recognizedTextResult = '';
//       for (TextBlock block in recognizedText.blocks) {
//         for (TextLine line in block.lines) {
//           recognizedTextResult += "${line.text}\n";
//         }
//       }
//       print("xxxx$recognizedTextResult");
//       emit(RecognizetextSuccess(text: recognizedTextResult));
//       textRecognizer.close();
//     } catch (e) {
//       emit(RecognizetextFailed(message: e.toString()));
//     }
//   }
// }
