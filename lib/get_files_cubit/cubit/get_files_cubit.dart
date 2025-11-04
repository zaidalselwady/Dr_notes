import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:xml/xml.dart' as xml;
import 'package:image/image.dart' as img;
import '../../core/repos/data_repo.dart';
import '../../patient_visits_screen/data/image_model.dart';
part 'get_files_state.dart';

class GetFilesCubit extends Cubit<GetFilesState> {
  GetFilesCubit(this.dataRepo) : super(GetFilesInitial());
  final DataRepo dataRepo;

  List<ImageModel> newImages = [];
  List<ImageModel> cachedImages = [];

  // Custom cache manager with longer lifetime
  static final DefaultCacheManager _cacheManager = DefaultCacheManager();

  Future<void> getImages3(
      String folderName, int? isSignature, bool isNavigatingFromList) async {
    if (isClosed) return;
    emit(GettingFiles());

    final String cacheKey = "patient_$folderName";
    List<ImageModel> images = [];

    try {
      if (isNavigatingFromList) {
        // Load from cache first
        cachedImages = await _getCachedImagesOptimized(cacheKey);
        images = cachedImages;

        if (images.isEmpty) {
          images = await _fetchAndProcessImages(folderName, isSignature);
          if (isSignature == null) {
            await _cacheImagesOptimized(images, cacheKey);
          }
        }
      } else {
        // Fetch new images
        newImages = await _fetchAndProcessImages(folderName, isSignature);

        if (isSignature == null) {
          images = _mergeImagesOptimized(cachedImages, newImages);
          await _cacheImagesOptimized(images, cacheKey);
        } else {
          images = newImages;
        }
      }

      // Sort by date
      images.sort(
          (a, b) => _parseDate(b.imgName).compareTo(_parseDate(a.imgName)));

      emit(GetFilesSuccess(images: images));
    } catch (e) {
      debugPrint("Error in getImages3: $e");
      emit(GetFilesFaild(error: e.toString()));
    }
  }

  // ========== OPTIMIZED MERGE ==========
  List<ImageModel> _mergeImagesOptimized(
    List<ImageModel> cached,
    List<ImageModel> fresh,
  ) {
    final Map<String, ImageModel> merged = {
      for (var img in cached) img.imgName: img,
    };

    // Replace or add new images
    for (var newImg in fresh) {
      merged[newImg.imgName] = newImg;
    }

    return merged.values.toList();
  }

  // ========== OPTIMIZED CACHING (Separate Files) ==========
  Future<List<ImageModel>> _getCachedImagesOptimized(String cacheKey) async {
    try {
      // Load metadata file
      FileInfo? metadataFile =
          await _cacheManager.getFileFromCache("${cacheKey}_metadata");
      if (metadataFile == null) return [];

      final String metadataJson = await metadataFile.file.readAsString();
      final List<dynamic> metadataList = jsonDecode(metadataJson);

      // Load images in parallel
      final List<ImageModel> images = await Future.wait(
        metadataList.map((meta) async {
          final String imgName = meta['imgName'];
          final String type = meta['type']; // 'image' or 'json'

          if (type == 'image') {
            // Load image from separate cache file
            FileInfo? imgFile = await _cacheManager
                .getFileFromCache("${cacheKey}_img_$imgName");
            if (imgFile != null) {
              Uint8List imgBytes = await imgFile.file.readAsBytes();
              return ImageModel(imgName: imgName, imgBase64: imgBytes);
            }
          } else if (type == 'json') {
            // Load JSON strokes
            FileInfo? jsonFile = await _cacheManager
                .getFileFromCache("${cacheKey}_json_$imgName");
            if (jsonFile != null) {
              String strokesJson = await jsonFile.file.readAsString();
              return ImageModel(imgName: imgName, strokesJson: strokesJson);
            }
          }

          // Return an empty ImageModel if no data is found
          return ImageModel(imgName: imgName);
        }),
      );

      return images.whereType<ImageModel>().toList();
    } catch (e) {
      debugPrint("Failed to load cached images: $e");
      return [];
    }
  }

  Future<void> _cacheImagesOptimized(
      List<ImageModel> images, String cacheKey) async {
    try {
      // Create metadata
      final List<Map<String, dynamic>> metadata = [];

      // Cache each image/json separately
      for (var image in images) {
        if (image.imgBase64 != null) {
          // Compress image before caching
          // Uint8List compressed =
          //     await compute(_compressImage, image.imgBase64!);

          // await _cacheManager.putFile(
          //   "${cacheKey}_img_${image.imgName}",
          //   compressed,
          // );

          metadata.add({
            'imgName': image.imgName,
            'type': 'image',
          });
        } else if (image.strokesJson != null && image.strokesJson!.isNotEmpty) {
          // Cache JSON
          await _cacheManager.putFile(
            "${cacheKey}_json_${image.imgName}",
            Uint8List.fromList(utf8.encode(image.strokesJson!)),
          );

          metadata.add({
            'imgName': image.imgName,
            'type': 'json',
          });
        }
      }

      // Cache metadata
      await _cacheManager.putFile(
        "${cacheKey}_metadata",
        Uint8List.fromList(utf8.encode(jsonEncode(metadata))),
      );
    } catch (e) {
      debugPrint("Failed to cache images: $e");
    }
  }

  // ========== PARALLEL IMAGE PROCESSING ==========
  Future<List<ImageModel>> _fetchAndProcessImages(
      String folderName, int? isSignature) async {
    var result = await dataRepo.soapRequest(
      isSignature: isSignature,
      sqlStr: "",
      action: "IO_get_Images",
      newName: "",
      currentFolder: folderName,
      filePath: "",
      imageBytes: "",
    );

    return result.fold(
      (failure) {
        debugPrint("API Fetch Failed: ${failure.errorMsg}");
        return [];
      },
      (dMaster) async {
        final document = xml.XmlDocument.parse(dMaster.body);
        if (document.findAllElements('IO_get_ImagesResult').isNotEmpty) {
          final resultElement =
              document.findAllElements('IO_get_ImagesResult').first;
          return _parseBase64ImagesParallel(
              resultElement.innerText, isSignature);
        }
        return [];
      },
    );
  }

  // Parse and decode images in parallel
  Future<List<ImageModel>> _parseBase64ImagesParallel(
      String jsonString, int? isSignature) async {
    List<String> base64Strings = jsonString.split(',');

    // Process all images in parallel
    List<Future<ImageModel?>> futures = base64Strings.map((element) async {
      return ImageModel(imgName: element);
    }).toList();

    List<ImageModel?> results = await Future.wait(futures);
    List<ImageModel> imageModels = results.whereType<ImageModel>().toList();

    // Remove signature if needed
    if (imageModels.isNotEmpty &&
        imageModels.first.imgName.toLowerCase() == "signature.png" &&
        isSignature == null) {
      imageModels.removeAt(1);
    }

    return imageModels;
  }

  // ========== DATE PARSING ==========
  DateTime _parseDate(String imgName) {
    try {
      String nameWithoutExt = imgName.contains(".png")
          ? imgName.split('.png')[0]
          : imgName.contains(".json")
              ? imgName.split('.json')[0]
              : imgName;

      List<String> parts = nameWithoutExt.split(' ');
      if (parts.length < 2) return DateTime.now();

      List<String> dateParts = parts[0].split('-');
      List<String> timeParts = parts[1].split('-');

      if (dateParts.length < 3 || timeParts.length < 3) return DateTime.now();

      int day = int.parse(dateParts[0]);
      int month = int.parse(dateParts[1]);
      int year = int.parse(dateParts[2]);

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      int second = int.parse(timeParts[2]);

      return DateTime(year, month, day, hour, minute, second);
    } catch (e) {
      debugPrint("Failed to parse date from $imgName: $e");
      return DateTime.now();
    }
  }

  // ========== CLEANUP ==========
  Future<void> clearCache(String folderName) async {
    final String cacheKey = "patient_$folderName";
    await _cacheManager.removeFile("${cacheKey}_metadata");
    // Note: Individual files will be cleaned by cache manager automatically
  }

  @override
  Future<void> close() {
    newImages.clear();
    cachedImages.clear();
    return super.close();
  }
}





























//No 4
// import 'dart:convert';
// import 'package:bloc/bloc.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// import 'package:xml/xml.dart' as xml;
// import 'package:image/image.dart' as img;
// import '../../core/repos/data_repo.dart';
// import '../../patient_visits_screen/data/image_model.dart';
// part 'get_files_state.dart';

// class GetFilesCubit extends Cubit<GetFilesState> {
//   GetFilesCubit(this.dataRepo) : super(GetFilesInitial());
//   final DataRepo dataRepo;

//   List<ImageModel> newImages = [];
//   List<ImageModel> cachedImages = [];

//   // Custom cache manager with longer lifetime
//   static final DefaultCacheManager _cacheManager = DefaultCacheManager();

//   Future<void> getImages3(
//       String folderName, int? isSignature, bool isNavigatingFromList) async {
//     if (isClosed) return;
//     emit(GettingFiles());

//     final String cacheKey = "patient_$folderName";
//     List<ImageModel> images = [];

//     try {
//       if (isNavigatingFromList) {
//         // Load from cache first
//         cachedImages = await _getCachedImagesOptimized(cacheKey);
//         images = cachedImages;

//         if (images.isEmpty) {
//           images = await _fetchAndProcessImages(folderName, isSignature);
//           if (isSignature == null) {
//             await _cacheImagesOptimized(images, cacheKey);
//           }
//         }
//       } else {
//         // Fetch new images
//         newImages = await _fetchAndProcessImages(folderName, isSignature);

//         if (isSignature == null) {
//           images = _mergeImagesOptimized(cachedImages, newImages);
//           await _cacheImagesOptimized(images, cacheKey);
//         } else {
//           images = newImages;
//         }
//       }

//       // Sort by date
//       images.sort(
//           (a, b) => _parseDate(b.imgName).compareTo(_parseDate(a.imgName)));

//       emit(GetFilesSuccess(images: images));
//     } catch (e) {
//       debugPrint("Error in getImages3: $e");
//       emit(GetFilesFaild(error: e.toString()));
//     }
//   }

//   // ========== OPTIMIZED MERGE ==========
//   List<ImageModel> _mergeImagesOptimized(
//     List<ImageModel> cached,
//     List<ImageModel> fresh,
//   ) {
//     final Map<String, ImageModel> merged = {
//       for (var img in cached) img.imgName: img,
//     };

//     // Replace or add new images
//     for (var newImg in fresh) {
//       merged[newImg.imgName] = newImg;
//     }

//     return merged.values.toList();
//   }

//   // ========== OPTIMIZED CACHING (Separate Files) ==========
//   Future<List<ImageModel>> _getCachedImagesOptimized(String cacheKey) async {
//     try {
//       // Load metadata file
//       FileInfo? metadataFile =
//           await _cacheManager.getFileFromCache("${cacheKey}_metadata");
//       if (metadataFile == null) return [];

//       final String metadataJson = await metadataFile.file.readAsString();
//       final List<dynamic> metadataList = jsonDecode(metadataJson);

//       // Load images in parallel
//       final List<ImageModel> images = await Future.wait(
//         metadataList.map((meta) async {
//           final String imgName = meta['imgName'];
//           final String type = meta['type']; // 'image' or 'json'

//           if (type == 'image') {
//             // Load image from separate cache file
//             FileInfo? imgFile = await _cacheManager
//                 .getFileFromCache("${cacheKey}_img_$imgName");
//             if (imgFile != null) {
//               Uint8List imgBytes = await imgFile.file.readAsBytes();
//               return ImageModel(imgName: imgName, imgBase64: imgBytes);
//             }
//           } else if (type == 'json') {
//             // Load JSON strokes
//             FileInfo? jsonFile = await _cacheManager
//                 .getFileFromCache("${cacheKey}_json_$imgName");
//             if (jsonFile != null) {
//               String strokesJson = await jsonFile.file.readAsString();
//               return ImageModel(imgName: imgName, strokesJson: strokesJson);
//             }
//           }

//           // Return an empty ImageModel if no data is found
//           return ImageModel(imgName: imgName);
//         }),
//       );

//       return images.whereType<ImageModel>().toList();
//     } catch (e) {
//       debugPrint("Failed to load cached images: $e");
//       return [];
//     }
//   }

//   Future<void> _cacheImagesOptimized(
//       List<ImageModel> images, String cacheKey) async {
//     try {
//       // Create metadata
//       final List<Map<String, dynamic>> metadata = [];

//       // Cache each image/json separately
//       for (var image in images) {
//         if (image.imgBase64 != null) {
//           // Compress image before caching
//           Uint8List compressed =
//               await compute(_compressImage, image.imgBase64!);

//           await _cacheManager.putFile(
//             "${cacheKey}_img_${image.imgName}",
//             compressed,
//           );

//           metadata.add({
//             'imgName': image.imgName,
//             'type': 'image',
//           });
//         } else if (image.strokesJson != null &&
//             image.strokesJson!.isNotEmpty) {
//           // Cache JSON
//           await _cacheManager.putFile(
//             "${cacheKey}_json_${image.imgName}",
//             Uint8List.fromList(utf8.encode(image.strokesJson!)),
//           );

//           metadata.add({
//             'imgName': image.imgName,
//             'type': 'json',
//           });
//         }
//       }

//       // Cache metadata
//       await _cacheManager.putFile(
//         "${cacheKey}_metadata",
//         Uint8List.fromList(utf8.encode(jsonEncode(metadata))),
//       );
//     } catch (e) {
//       debugPrint("Failed to cache images: $e");
//     }
//   }

//   // ========== PARALLEL IMAGE PROCESSING ==========
//   Future<List<ImageModel>> _fetchAndProcessImages(
//       String folderName, int? isSignature) async {
//     var result = await dataRepo.soapRequest(
//       isSignature: isSignature,
//       sqlStr: "",
//       action: "IO_get_Images",
//       newName: "",
//       currentFolder: folderName,
//       filePath: "",
//       imageBytes: "",
//     );

//     return result.fold(
//       (failure) {
//         debugPrint("API Fetch Failed: ${failure.errorMsg}");
//         return [];
//       },
//       (dMaster) async {
//         final document = xml.XmlDocument.parse(dMaster.body);
//         if (document.findAllElements('IO_get_ImagesResult').isNotEmpty) {
//           final resultElement =
//               document.findAllElements('IO_get_ImagesResult').first;
//           return _parseBase64ImagesParallel(resultElement.innerText, isSignature);
//         }
//         return [];
//       },
//     );
//   }

//   // Parse and decode images in parallel
//   Future<List<ImageModel>> _parseBase64ImagesParallel(
//       String jsonString, int? isSignature) async {
//     List<String> base64Strings = jsonString.split(',');

//     // Process all images in parallel
//     List<Future<ImageModel?>> futures = base64Strings.map((element) async {
//       List<String> parts = element.split("IMAGENAME");
//       if (parts.length != 2) return null;

//       String imgName = parts[1].trim();
//       String contentString = parts[0];

//       if (imgName.toLowerCase().endsWith('.png')) {
//         // Decode Base64 in isolate
//         Uint8List? imgBase64 = await compute(_decodeBase64, contentString);
//         if (imgBase64 != null) {
//           return ImageModel(imgName: imgName, imgBase64: imgBase64);
//         }
//         // Skip invalid PNG images
//         throw Exception('Invalid PNG image data');
//       } else if (imgName.toLowerCase().endsWith('.json')) {
//         return ImageModel(imgName: imgName, strokesJson: contentString);
//       }

//       throw Exception('Unsupported file type');
//     }).toList();

//     List<ImageModel?> results = await Future.wait(futures);
//     List<ImageModel> imageModels =
//         results.whereType<ImageModel>().toList();

//     // Remove signature if needed
//     if (imageModels.isNotEmpty &&
//         imageModels.first.imgName.toLowerCase() == "signature.png" &&
//         isSignature == null) {
//       imageModels.removeAt(1);
//     }

//     return imageModels;
//   }

//   // ========== ISOLATE FUNCTIONS ==========
//   // These functions run in separate isolates for heavy computation

//   static Uint8List? _decodeBase64(String base64String) {
//     try {
//       String cleanedBase64 =
//           base64String.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
//       String base64Padded = cleanedBase64.padRight(
//         (cleanedBase64.length + 3) ~/ 4 * 4,
//         '=',
//       );
//       return base64Decode(base64Padded);
//     } catch (e) {
//       debugPrint("Failed to decode Base64: $e");
//       return null;
//     }
//   }

//   static Uint8List _compressImage(Uint8List imageBytes) {
//     try {
//       // Decode PNG
//       img.Image? image = img.decodeImage(imageBytes);
//       if (image == null) return imageBytes;

//       // Resize if too large (e.g., max 1920px width)
//       if (image.width > 1920) {
//         image = img.copyResize(image, width: 1920);
//       }

//       // Encode as JPEG with 80% quality
//       return Uint8List.fromList(img.encodeJpg(image, quality: 80));
//     } catch (e) {
//       debugPrint("Failed to compress image: $e");
//       return imageBytes; // Return original if compression fails
//     }
//   }

//   // ========== DATE PARSING ==========
//   DateTime _parseDate(String imgName) {
//     try {
//       String nameWithoutExt = imgName.contains(".png")
//           ? imgName.split('.png')[0]
//           : imgName.contains(".json")
//               ? imgName.split('.json')[0]
//               : imgName;

//       List<String> parts = nameWithoutExt.split(' ');
//       if (parts.length < 2) return DateTime.now();

//       List<String> dateParts = parts[0].split('-');
//       List<String> timeParts = parts[1].split('-');

//       if (dateParts.length < 3 || timeParts.length < 3) return DateTime.now();

//       int day = int.parse(dateParts[0]);
//       int month = int.parse(dateParts[1]);
//       int year = int.parse(dateParts[2]);

//       int hour = int.parse(timeParts[0]);
//       int minute = int.parse(timeParts[1]);
//       int second = int.parse(timeParts[2]);

//       return DateTime(year, month, day, hour, minute, second);
//     } catch (e) {
//       debugPrint("Failed to parse date from $imgName: $e");
//       return DateTime.now();
//     }
//   }

//   // ========== CLEANUP ==========
//   Future<void> clearCache(String folderName) async {
//     final String cacheKey = "patient_$folderName";
//     await _cacheManager.removeFile("${cacheKey}_metadata");
//     // Note: Individual files will be cleaned by cache manager automatically
//   }

//   @override
//   Future<void> close() {
//     newImages.clear();
//     cachedImages.clear();
//     return super.close();
//   }
// }
















//No 3

// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:bloc/bloc.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// import 'package:meta/meta.dart';
// import 'package:xml/xml.dart' as xml;
// import 'package:image/image.dart' as img;

// import '../../core/repos/data_repo.dart';
// import '../../patient_visits_screen/data/image_model.dart';

// part 'get_files_state.dart';

// class GetFilesCubit extends Cubit<GetFilesState> {
//   GetFilesCubit(this.dataRepo) : super(GetFilesInitial());
//   final DataRepo dataRepo;

//   List<ImageModel> newImages = [];
//   List<ImageModel> cachedImages = [];

//   Future<void> getImages3(
//       String folderName, int? isSignature, bool isNavigatingFromList) async {
//     if (isClosed) return;
//     emit(GettingFiles());

//     final DefaultCacheManager cacheManager = DefaultCacheManager();
//     final String cacheKey = "patient_$folderName";

//     List<ImageModel> images = [];

//     try {
//       if (isNavigatingFromList) {
//         cachedImages = await _getCachedImages(cacheManager, cacheKey);
//         images = cachedImages;

//         if (images.isEmpty) {
//           images = await _fetchImagesFromAPI(folderName, isSignature);
//           if (isSignature == null) {
//             await _cacheImages(images, cacheManager, cacheKey);
//           }
//         }
//       } else {
//         newImages = await _fetchImagesFromAPI(folderName, isSignature);

//         if (isSignature == null) {
//           images = _mergeImages(cachedImages, newImages);
//           await _cacheImages(images, cacheManager, cacheKey);
//         } else {
//           images = newImages;
//         }
//       }

//       // Sort by date
//       images.sort((a, b) => _parseDate(b.imgName).compareTo(_parseDate(a.imgName)));

//       emit(GetFilesSuccess(images: images));
//     } catch (e) {
//       emit(GetFilesFaild(error: e.toString()));
//       debugPrint("Error in getImages3: $e");
//     }
//   }

//   // Merge cached and fresh images without duplicates
//   List<ImageModel> _mergeImages(List<ImageModel> cached, List<ImageModel> fresh) {
//     final Map<String, ImageModel> merged = {
//       for (var img in cached) img.imgName: img,
//     };

//     for (var newImg in fresh) {
//       merged[newImg.imgName] = newImg;
//     }

//     return merged.values.toList();
//   }

//   Future<List<ImageModel>> _getCachedImages(
//       DefaultCacheManager cacheManager, String cacheKey) async {
//     try {
//       FileInfo? cachedFileInfo = await cacheManager.getFileFromCache(cacheKey);
//       if (cachedFileInfo != null) {
//         return _loadImagesFromCache(cachedFileInfo.file);
//       }
//     } catch (e) {
//       debugPrint("Failed to load cached images: $e");
//     }
//     return [];
//   }

//   Future<List<ImageModel>> _fetchImagesFromAPI(
//       String folderName, int? isSignature) async {
//     var result = await dataRepo.soapRequest(
//       isSignature: isSignature,
//       sqlStr: "",
//       action: "IO_get_Images",
//       newName: "",
//       currentFolder: folderName,
//       filePath: "",
//       imageBytes: "",
//     );

//     return result.fold(
//       (failure) {
//         debugPrint("API Fetch Failed: ${failure.errorMsg}");
//         return [];
//       },
//       (dMaster) async {
//         final document = xml.XmlDocument.parse(dMaster.body);
//         if (document.findAllElements('IO_get_ImagesResult').isNotEmpty) {
//           final resultElement =
//               document.findAllElements('IO_get_ImagesResult').first;
//           return await _parseBase64Images(resultElement.innerText, isSignature);
//         }
//         return [];
//       },
//     );
//   }

//   Future<List<ImageModel>> _loadImagesFromCache(File cachedFile) async {
//     final String jsonString = await cachedFile.readAsString();
//     final List<dynamic> jsonList = jsonDecode(jsonString);
//     return jsonList
//         .map((item) => ImageModel(
//               imgName: item['imgName'],
//               imgBase64: item['imgBase64'] != null
//                   ? base64Decode(item['imgBase64'])
//                   : null,
//               strokesJson: item['strokesJson'] ?? "",
//             ))
//         .toList();
//   }

//   Future<void> _cacheImages(
//       List<ImageModel> images, DefaultCacheManager cacheManager, String cacheKey) async {
//     final List<Map<String, dynamic>> jsonList = images
//         .map((image) => {
//               'imgName': image.imgName,
//               'imgBase64': image.imgBase64 != null
//                   ? base64Encode(image.imgBase64!)
//                   : null,
//               'strokesJson': image.strokesJson ?? "",
//             })
//         .toList();
//     await cacheManager.putFile(
//       cacheKey,
//       Uint8List.fromList(utf8.encode(jsonEncode(jsonList))),
//     );
//   }

//   Future<List<ImageModel>> _parseBase64Images(String raw, int? isSignature) async {
//     List<String> base64Strings = raw.split(',');
//     List<ImageModel> imageModels = [];

//     // parallel decoding
//     await Future.wait(base64Strings.map((element) async {
//       final parts = element.split("IMAGENAME");

//       if (parts.length == 2) {
//         String imgName = parts[1].trim();
//         String contentString = parts[0];

//         if (imgName.toLowerCase().endsWith('.png')) {
//           String cleanedBase64 =
//               contentString.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
//           String paddedBase64 = cleanedBase64.padRight(
//             (cleanedBase64.length + 3) ~/ 4 * 4,
//             '=',
//           );

//           // decode in isolate
//           Uint8List imgBytes =
//               await compute(_decodeAndCompressImage, paddedBase64);

//           imageModels.add(ImageModel(imgName: imgName, imgBase64: imgBytes));
//         } else if (imgName.toLowerCase().endsWith('.json')) {
//           imageModels.add(ImageModel(imgName: imgName, strokesJson: contentString));
//         }
//       }
//     }));

//     if (imageModels.isNotEmpty &&
//         imageModels.first.imgName.toLowerCase() == "signature.png" &&
//         isSignature == null) {
//       imageModels.removeAt(0);
//     }

//     return imageModels;
//   }

//   DateTime _parseDate(String imgName) {
//     String nameWithoutExt = imgName.contains(".png")
//         ? imgName.split('.png')[0]
//         : imgName.contains(".json")
//             ? imgName.split('.json')[0]
//             : imgName;

//     List<String> parts = nameWithoutExt.split(' '); // [date, time]
//     List<String> dateParts = parts[0].split('-'); // [dd-MM-yyyy]
//     List<String> timeParts = parts[1].split('-'); // [hh-mm-ss]

//     int day = int.parse(dateParts[0]);
//     int month = int.parse(dateParts[1]);
//     int year = int.parse(dateParts[2]);

//     int hour = int.parse(timeParts[0]);
//     int minute = int.parse(timeParts[1]);
//     int second = int.parse(timeParts[2]);

//     return DateTime(year, month, day, hour, minute, second);
//   }
// }

// // run in background isolate to improve performance
// Future<Uint8List> _decodeAndCompressImage(String base64Str) async {
//   final Uint8List decoded = base64Decode(base64Str);

//   try {
//     final image = img.decodeImage(decoded);
//     if (image != null) {
//       // compress to reduce memory
//       final compressed = img.encodeJpg(image, quality: 75);
//       return Uint8List.fromList(compressed);
//     }
//   } catch (e) {
//     debugPrint("Image compression failed: $e");
//   }

//   return decoded;
// }






























//No 2
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:bloc/bloc.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// import 'package:meta/meta.dart';
// import 'package:xml/xml.dart' as xml;
// import '../../core/repos/data_repo.dart';
// import '../../patient_visits_screen/data/image_model.dart';
// part 'get_files_state.dart';

// class GetFilesCubit extends Cubit<GetFilesState> {
//   GetFilesCubit(this.dataRepo) : super(GetFilesInitial());
//   final DataRepo dataRepo;

//   List<ImageModel> newImages = [];
//   List<ImageModel> cachedImages = [];

//   Future<void> getImages3(
//       String folderName, int? isSignature, bool isNavigatingFromList) async {
//     if (isClosed) return;
//     emit(GettingFiles());

//     final DefaultCacheManager cacheManager = DefaultCacheManager();
//     final String cacheKey = "patient_$folderName";

//     List<ImageModel> images = [];

//     if (isNavigatingFromList) {
//       cachedImages = await _getCachedImages(cacheManager, cacheKey);
//       images = cachedImages;
//       if (images.isEmpty) {
//         images = await _fetchImagesFromAPI(folderName, isSignature);
//         if (isSignature == null) {
//           await _cacheImages(images, cacheManager, cacheKey);
//         }
//       }
//     } else {
//       newImages = await _fetchImagesFromAPI(folderName, isSignature);

//       if (isSignature == null) {
//         images = _mergeImages(cachedImages, newImages);
//         await _cacheImages(images, cacheManager, cacheKey);
//       } else {
//         images = newImages;
//       }
//     }

//     // Sort by date
//     images
//         .sort((a, b) => _parseDate(b.imgName).compareTo(_parseDate(a.imgName)));

//     emit(GetFilesSuccess(images: images));
//   }

//   List<ImageModel> _mergeImages(
//   List<ImageModel> cached,
//   List<ImageModel> fresh,
// ) {
//   final Map<String, ImageModel> merged = {
//     for (var img in cached) img.imgName: img,
//   };

//   for (var newImg in fresh) {
//     merged[newImg.imgName] = newImg; // إذا موجودة، بيستبدلها تلقائيًا
//   }

//   return merged.values.toList();
// }


//   // Merge cached and fresh images without duplicates
//   // List<ImageModel> _mergeImages(
//   //     List<ImageModel> cached, List<ImageModel> fresh) {
//   //   Set<String> existing = {};

//   //   for (var img in cached) {
//   //     if (img.imgBase64 != null) {
//   //       existing.add(_hashImage(img.imgBase64!));
//   //     } else if (img.strokesJson != null && img.strokesJson!.isNotEmpty) {
//   //       existing.add(_hashContent(img.strokesJson!));
//   //     }
//   //   }

//   //   List<ImageModel> all = List.from(cached);

//   //   for (var newImg in fresh) {
//   //     if (newImg.imgBase64 != null &&
//   //         !existing.contains(_hashImage(newImg.imgBase64!))) {
//   //       all.add(newImg);
//   //       existing.add(_hashImage(newImg.imgBase64!));
//   //     } else if (newImg.strokesJson != null &&
//   //         newImg.strokesJson!.isNotEmpty &&
//   //         existing.contains(newImg.imgName)) {
//   //       all.add(newImg);
//   //       existing.add(_hashContent(newImg.strokesJson!));
//   //     }
//   //   }

//   //   return all;
//   // }

//   Future<List<ImageModel>> _getCachedImages(
//       DefaultCacheManager cacheManager, String cacheKey) async {
//     try {
//       FileInfo? cachedFileInfo = await cacheManager.getFileFromCache(cacheKey);
//       if (cachedFileInfo != null)
//         return _loadImagesFromCache(cachedFileInfo.file);
//     } catch (e) {
//       debugPrint("Failed to load cached images: $e");
//     }
//     return [];
//   }

//   Future<List<ImageModel>> _fetchImagesFromAPI(
//       String folderName, int? isSignature) async {
//     var result = await dataRepo.soapRequest(
//       isSignature: isSignature,
//       sqlStr: "",
//       action: "IO_get_Images",
//       newName: "",
//       currentFolder: folderName,
//       filePath: "",
//       imageBytes: "",
//     );

//     return result.fold(
//       (failure) {
//         debugPrint("API Fetch Failed: ${failure.errorMsg}");
//         return [];
//       },
//       (dMaster) async {
//         final document = xml.XmlDocument.parse(dMaster.body);
//         if (document.findAllElements('IO_get_ImagesResult').isNotEmpty) {
//           final resultElement =
//               document.findAllElements('IO_get_ImagesResult').first;
//           return _parseBase64Images(resultElement.innerText, isSignature);
//         }
//         return [];
//       },
//     );
//   }

//   String _hashImage(Uint8List imgBase64) => base64Encode(imgBase64);
//   String _hashContent(String data) => base64Encode(utf8.encode(data));

//   Future<List<ImageModel>> _loadImagesFromCache(File cachedFile) async {
//     final String jsonString = await cachedFile.readAsString();
//     final List<dynamic> jsonList = jsonDecode(jsonString);
//     return jsonList
//         .map((item) => ImageModel(
//               imgName: item['imgName'],
//               imgBase64: item['imgBase64'] != null
//                   ? Uint8List.fromList(List<int>.from(item['imgBase64']))
//                   : null,
//               strokesJson: item['strokesJson'] ?? "",
//             ))
//         .toList();
//   }

//   Future<void> _cacheImages(List<ImageModel> images,
//       DefaultCacheManager cacheManager, String cacheKey) async {
//     final List<Map<String, dynamic>> jsonList = images
//         .map((image) => {
//               'imgName': image.imgName,
//               'imgBase64': image.imgBase64?.toList(),
//               'strokesJson': image.strokesJson ?? "",
//             })
//         .toList();
//     await cacheManager.putFile(
//         cacheKey, Uint8List.fromList(utf8.encode(jsonEncode(jsonList))));
//   }

//   List<ImageModel> _parseBase64Images(String jsonString, int? isSignature) {
//     List<String> base64Strings = jsonString.split(',');
//     List<ImageModel> imageModels = [];

//     for (var element in base64Strings) {
//       List<String> parts = element.split("IMAGENAME");

//       if (parts.length == 2) {
//         String imgName = parts[1].trim();
//         String contentString = parts[0];

//         if (imgName.toLowerCase().endsWith('.png')) {
//           String cleanedBase64String =
//               contentString.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
//           String base64Padded = cleanedBase64String.padRight(
//             (cleanedBase64String.length + 3) ~/ 4 * 4,
//             '=',
//           );
//           Uint8List imgBase64 = base64Decode(base64Padded);
//           imageModels.add(ImageModel(imgName: imgName, imgBase64: imgBase64));
//         } else if (imgName.toLowerCase().endsWith('.json')) {
//           imageModels
//               .add(ImageModel(imgName: imgName, strokesJson: contentString));
//         }
//       }
//     }

//     if (imageModels.isNotEmpty &&
//         imageModels.first.imgName.toLowerCase() == "signature.png" &&
//         isSignature == null) {
//       imageModels.removeAt(0);
//     }

//     return imageModels;
//   }

//   DateTime _parseDate(String imgName) {
//     String nameWithoutExt = imgName.contains(".png")
//         ? imgName.split('.png')[0]
//         : imgName.contains(".json")
//             ? imgName.split('.json')[0]
//             : imgName;

//     List<String> parts = nameWithoutExt.split(' '); // [date, time]
//     List<String> dateParts = parts[0].split('-'); // [dd-MM-yyyy]
//     List<String> timeParts = parts[1].split('-'); // [hh-mm-ss]

//     int day = int.parse(dateParts[0]);
//     int month = int.parse(dateParts[1]);
//     int year = int.parse(dateParts[2]);

//     int hour = int.parse(timeParts[0]);
//     int minute = int.parse(timeParts[1]);
//     int second = int.parse(timeParts[2]);

//     return DateTime(year, month, day, hour, minute, second);
//   }
// }



















//NO 1
// class GetFilesCubit extends Cubit<GetFilesState> {
//   GetFilesCubit(this.dataRepo) : super(GetFilesInitial());
//   final DataRepo dataRepo;

//   List<ImageModel> newImages = [];
//   List<ImageModel> cachedImages = [];

//   Future<void> getImages3(
//     String folderName,
//     int? isSignature,
//     bool isNavigatingFromList,
//   ) async {
//     if (isClosed) return;
//     emit(GettingFiles());

//     final DefaultCacheManager cacheManager = DefaultCacheManager();
//     final String cacheKey = "patient_$folderName";

//     List<ImageModel> images = [];

//     if (isNavigatingFromList) {
//       // ✅ الحالة الأولى: جاي من القائمة → استعمل الكاش فقط
//       cachedImages = await _getCachedImages(cacheManager, cacheKey);
//       images = cachedImages;
//       if (images.isEmpty) {
//         // لو الكاش فاضي، جيب من API
//         images = await _fetchImagesFromAPI(folderName, isSignature);
//         if (isSignature == null) {
//           // خزّن بالكاش إذا مش توقيع
//           await _cacheImages(images, cacheManager, cacheKey);
//         }
//       }
//     } else {
//       // ✅ الحالة الثانية: مش جاي من القائمة → جيب من API وكاشها
//       newImages = await _fetchImagesFromAPI(folderName, isSignature);

//       // Merge مع الكاش إذا حابب (بس هون ممكن تستغني عنه إذا بدك أحدث نسخة بس)
//       // cachedImages = await _getCachedImages(cacheManager, cacheKey);

//       if (isSignature == null) {
//         images = _mergeImages(cachedImages, newImages);
//         // ✅ خزّن الصور الجديدة بالكاش
//         await _cacheImages(images, cacheManager, cacheKey);
//       } else {
//         images = newImages;
//       }
//     }

//     // ✅ رتب الصور بالأحدث
//     images.sort((a, b) {
//       DateTime parseDate(String imgName) {
//         String nameWithoutExt = "";
//         if (imgName.contains("png")) {
//           nameWithoutExt = imgName.split('.png')[0];
//         }
//         if (imgName.contains("json")) {
//           nameWithoutExt = imgName.split('.json')[0];
//         }
//         //String nameWithoutExt = imgName.split('.png')[0];
//         List<String> parts = nameWithoutExt.split(' '); // [date, time]
//         List<String> dateParts = parts[0].split('-'); // [day, month, year]
//         List<String> timeParts = parts[1].split('-'); // [hour, min, sec]

//         int day = int.parse(dateParts[0]);
//         int month = int.parse(dateParts[1]);
//         int year = int.parse(dateParts[2]);

//         int hour = int.parse(timeParts[0]);
//         int minute = int.parse(timeParts[1]);
//         int second = int.parse(timeParts[2]);

//         return DateTime(year, month, day, hour, minute, second);
//       }

//       return parseDate(b.imgName).compareTo(parseDate(a.imgName));
//     });

//     emit(GetFilesSuccess(images: images));
//   }

// // 🔄 دالة للدمج
//   List<ImageModel> _mergeImages(
//       List<ImageModel> cached, List<ImageModel> fresh) {
//     Set<String> existing =
//         cached.map((img) => _hashImage(img.imgBase64!)).toSet();
//     List<ImageModel> all = List.from(cached);

//     for (var newImg in fresh) {

//       if (newImg.imgBase64 != null && !existing.contains(_hashImage(newImg.imgBase64!))) {
//         all.add(newImg);
//         existing.add(_hashImage(newImg.imgBase64!));
//       }else if (newImg.strokesJson != null && newImg.strokesJson!.isNotEmpty&&
//           !existing.contains(newImg.strokesJson)) {
//         // لو الصورة عبارة عن رسم (مش صورة PNG)
//         all.add(newImg);

//       }
//     }
//     return all;
//   }

//   // Future<void> getImages3(
//   //     String folderName, int? isSignature, bool isNavigatingFromList) async {
//   //   if (isClosed) return;
//   //   debugPrint("Started ${DateTime.now()}");
//   //   emit(GettingFiles());
//   //   final DefaultCacheManager cacheManager = DefaultCacheManager();
//   //   final String cacheKey = "patient_$folderName";
//   //   // ✅ Fetch from cache and API in parallel
//   //   final results = await Future.wait([
//   //     if (isNavigatingFromList)
//   //       _getCachedImages(cacheManager, cacheKey), // Fetch from cache
//   //     if (!isNavigatingFromList)
//   //       _fetchImagesFromAPI(folderName, isSignature), // Fetch from API
//   //   ]);
//   //   if (isNavigatingFromList) {
//   //     // ✅ Step 1: Get cached images
//   //     cachedImages = results.first;
//   //     if (cachedImages.isNotEmpty) {
//   //       emit(GetFilesSuccess(images: cachedImages));
//   //     }
//   //   }
//   //   if (!isNavigatingFromList) {
//   //     // ✅ Step 2: Get new images from API
//   //     newImages = results.first;
//   //   }
//   //   // ✅ Step 3: Merge cache and API results
//   //   Set<String> existingImageHashes =
//   //       cachedImages.map((img) => _hashImage(img.imgBase64)).toSet();
//   //   List<ImageModel> allImages = List.from(cachedImages);
//   //   for (var newImage in newImages) {
//   //     String newImageHash = _hashImage(newImage.imgBase64);
//   //     if (!existingImageHashes.contains(newImageHash)) {
//   //       allImages.add(newImage);
//   //       existingImageHashes.add(newImageHash);
//   //     }
//   //   }
//   //   // ✅ Step 4: Update cache with the final merged images
//   //   await _cacheImages(allImages, cacheManager, cacheKey);
//   //   // ✅ Emit the final images list
//   //   allImages = List<ImageModel>.from(allImages)
//   //     ..sort((a, b) => b.imgName.compareTo(a.imgName));
//   //   emit(GetFilesSuccess(images: allImages));
//   // }

//   Future<List<ImageModel>> _getCachedImages(
//       DefaultCacheManager cacheManager, String cacheKey) async {
//     try {
//       FileInfo? cachedFileInfo = await cacheManager.getFileFromCache(cacheKey);
//       if (cachedFileInfo != null) {
//         return _loadImagesFromCache(cachedFileInfo.file);
//       }
//     } catch (e) {
//       debugPrint("Failed to load cached images: $e");
//     }
//     return [];
//   }

//   Future<List<ImageModel>> _fetchImagesFromAPI(
//       String folderName, int? isSignature) async {
//     var result = await dataRepo.soapRequest(
//       isSignature: isSignature,
//       sqlStr: "",
//       action: "IO_get_Images",
//       newName: "",
//       currentFolder: folderName,
//       filePath: "",
//       imageBytes: "",
//     );

//     return result.fold(
//       (failure) {
//         debugPrint("API Fetch Failed: ${failure.errorMsg}");
//         return [];
//       },
//       (dMaster) async {
//         final document = xml.XmlDocument.parse(dMaster.body);
//         if (document.findAllElements('IO_get_ImagesResult').isNotEmpty) {
//           final resultElement =
//               document.findAllElements('IO_get_ImagesResult').first;
//           return _parseBase64Images(resultElement.innerText, isSignature);
//         }
//         return [];
//       },
//     );
//   }

// // ✅ Function to hash image base64 for duplicate check
//   String _hashImage(Uint8List imgBase64) {
//     // Convert the image bytes to a hash (using a simple hash method like MD5 or SHA1)
//     return base64Encode(
//         imgBase64); // This works because base64-encoded strings can be directly compared
//   }

// // ✅ Function to load images from cache
//   Future<List<ImageModel>> _loadImagesFromCache(File cachedFile) async {
//     final String jsonString = await cachedFile.readAsString();
//     final List<dynamic> jsonList = jsonDecode(jsonString);
//     return jsonList
//         .map((item) => ImageModel(
//               imgName: item['imgName'],
//               imgBase64:item['imgBase64']!=null? Uint8List.fromList(List<int>.from(item['imgBase64'])):null,
//               strokesJson: item['strokesJson'] ?? "",
//             ))
//         .toList();
//   }

// // ✅ Function to cache images
//   Future<void> _cacheImages(List<ImageModel> images,
//       DefaultCacheManager cacheManager, String cacheKey) async {
//     final List<Map<String, dynamic>> jsonList = images
//         .map((image) => {
//               'imgName': image.imgName,
//               'imgBase64':image.imgBase64?.toList(),
//               'strokesJson': image.strokesJson??"",

//             })
//         .toList();
//     await cacheManager.putFile(
//         cacheKey, Uint8List.fromList(utf8.encode(jsonEncode(jsonList))));
//   }

// // ✅ Function to parse Base64 images from API response
//   List<ImageModel> _parseBase64Images(String jsonString, int? isSignature) {
//     List<String> base64Strings = jsonString.split(',');
//     List<ImageModel> imageModels = [];

//     for (var element in base64Strings) {
//       List<String> parts = element.split("IMAGENAME");

//       if (parts.length == 2) {
//         String imgName = parts[1].trim();
//         String base64String = parts[0];
//         if (imgName.contains("png")) {
//           // Clean and decode Base64 string
//           String cleanedBase64String =
//               base64String.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
//           String base64Padded = cleanedBase64String.padRight(
//             (cleanedBase64String.length + 3) ~/ 4 * 4,
//             '=',
//           );

//           Uint8List imgBase64 = base64Decode(base64Padded);
//           imageModels.add(ImageModel(imgName: imgName, imgBase64: imgBase64));
//         } else {
//           String strokesJson = base64String;
//           imageModels
//               .add(ImageModel(imgName: imgName, strokesJson: strokesJson));
//         }
//       }
//     }
//     if (imageModels.isNotEmpty &&
//         imageModels.first.imgName == "Signature.png" &&
//         isSignature == null) {
//       imageModels.removeAt(0); // Remove unwanted first element if necessary
//     }

//     return imageModels;
//   }
// }
