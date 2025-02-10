// import 'dart:typed_data';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:image/image.dart' as img;
// import 'dart:convert';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';

// Future<void> recognizeText(String base64Image) async {
//   try {
//     String concatenatedRecognizedText = "";

//     // Decode the Base64 string into Uint8List (binary data)
//     Uint8List imageBytes = base64Decode(base64Image);

//     // Decode the image using the 'image' package
//     img.Image? image = img.decodeImage(imageBytes);

//     if (image == null) {
//       throw 'Image decoding failed';
//     }

//     // 1. Convert the image to grayscale
//     img.Image grayImage = img.grayscale(image);

//     // 2. Apply thresholding to make the text clearer
//     img.Image thresholdedImage = img.luminanceThreshold(grayImage);

//     // 3. Optionally apply some noise reduction (smoothing)
//     img.Image smoothedImage = img.gaussianBlur(thresholdedImage,  radius: 2);

//     // 4. Save the processed image to a temporary file
//     final tempDir = await getTemporaryDirectory();
//     final tempFile = File('${tempDir.path}/processed_image.jpg');
//     tempFile.writeAsBytesSync(img.encodeJpg(smoothedImage));

//     // 5. Upload the processed image to Firebase Storage (Optional)

//     // 6. Create InputImage from the processed image file
//     final inputImage = InputImage.fromFilePath(tempFile.path);

//     // 7. Create a text recognizer
//     final textRecognizer = TextRecognizer();

//     // 8. Process the image and extract text
//     final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

//     // 9. Output the recognized text and clean it
//     String recognizedTextResult = '';
//     for (TextBlock block in recognizedText.blocks) {
//       for (TextLine line in block.lines) {
//         recognizedTextResult += "${line.text}\n";
//       }
//     }

//     // Clean up recognized text (remove unnecessary characters or spaces)
//     String cleanedText = cleanExtractedText(recognizedTextResult);

//     // Emit success event with cleaned text

//     // Dispose of the text recognizer to free resources
//     textRecognizer.close();
//   } catch (e) {
//     print('Error recognizing text: $e');
//   }
// }

// // Function to clean extracted text (remove unnecessary spaces or characters)
// String cleanExtractedText(String text) {
//   text = text.trim(); // Remove leading/trailing spaces
//   text = text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ''); // Remove non-alphanumeric characters
//   text = text.replaceAll(RegExp(r'\s+'), ' '); // Remove extra spaces
//   return text;
// }

// // Function to upload image to Firebase Storage





// // import 'dart:convert';
// // import 'dart:io';
// // import 'dart:typed_data';
// // import 'package:bloc/bloc.dart';
// // import 'package:meta/meta.dart';
// // import 'package:image/image.dart' as img;
// // import 'package:flutter/material.dart';

// // import 'package:path_provider/path_provider.dart';
// // part 'recognizetext_state.dart';

// // class RecognizetextCubit extends Cubit<RecognizetextState> {
// //   RecognizetextCubit() : super(RecognizetextInitial());
// //   Future<void> recognizeText(String base64Image) async {
// //     emit(Recognizingtext());
// //     try {
// //       String concatenatedRecognizedText = "";
// //       // Decode the Base64 string into Uint8List (binary data)
// //       Uint8List imageBytes = base64Decode(base64Image);
// //       // Save the image to a temporary file
// //       final tempDir = await getTemporaryDirectory();
// //       final tempFile = File('${tempDir.path}/temp_image.jpg');
// //       await tempFile.writeAsBytes(imageBytes);

// //       // Create InputImage from file path
// //       final inputImage = InputImage.fromFilePath(tempFile.path);

// //       // Create text recognizer
// //       final textRecognizer = TextRecognizer();

// //       // Process the image and extract text
// //       final RecognizedText recognizedText =
// //           await textRecognizer.processImage(inputImage);

// //       // Print the recognized text
// //       for (TextBlock block in recognizedText.blocks) {
// //         for (TextLine line in block.lines) {
// //           concatenatedRecognizedText += "${line.text}\n";
// //         }
// //       }
// //       emit(RecognizetextSuccess(text: concatenatedRecognizedText));
// //       // Dispose of the text recognizer to free resources
// //       textRecognizer.close();
// //     } catch (e) {
// //       emit(RecognizetextFailed(message: e.toString()));
// //     }
// //   }

// //   Future<void> recognizeText1(String base64Image) async {
// //     emit(Recognizingtext());
// //     try {
// //       // Decode the Base64 string into Uint8List (binary data)
// //       Uint8List imageBytes = base64Decode(base64Image);

// //       // Decode the image using the 'image' package
// //       img.Image? image = img.decodeImage(imageBytes);

// //       if (image == null) {
// //         throw 'Image decoding failed';
// //       }
// //       // Convert the image to grayscale to improve recognition
// //       img.Image grayImage = img.grayscale(image);

// //       // Optional: Apply thresholding to make the text clearer
// //       img.Image thresholdedImage = img.luminanceThreshold(grayImage);

// //       // Save the processed image to a temporary file for further processing
// //       final tempDir = await getTemporaryDirectory();
// //       final tempFile = File('${tempDir.path}/processed_image.jpg');
// //       tempFile.writeAsBytesSync(img.encodeJpg(thresholdedImage));

// //       // Create InputImage from the processed image file
// //       final inputImage = InputImage.fromFilePath(tempFile.path);

// //       // Create a text recognizer
// //       final textRecognizer = TextRecognizer();

// //       // Process the image and extract text
// //       final RecognizedText recognizedText =
// //           await textRecognizer.processImage(inputImage);

// //       // Output the recognized text
// //       String recognizedTextResult = '';
// //       for (TextBlock block in recognizedText.blocks) {
// //         for (TextLine line in block.lines) {
// //           recognizedTextResult += "${line.text}\n";
// //         }
// //       }
// //       print("xxxx$recognizedTextResult");
// //       emit(RecognizetextSuccess(text: recognizedTextResult));
// //       textRecognizer.close();
// //     } catch (e) {
// //       emit(RecognizetextFailed(message: e.toString()));
// //     }
// //   }
// // }
