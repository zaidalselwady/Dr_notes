import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import '../../core/repos/data_repo.dart';
import '../../patient_visits_screen/data/image_model.dart';

part 'get_files_state.dart';

class GetFilesCubit extends Cubit<GetFilesState> {
  GetFilesCubit(this.dataRepo) : super(GetFilesInitial());
  final DataRepo dataRepo;

  List<ImageModel> newImages = [];
  List<ImageModel> cachedImages = [];

  Future<void> getImages3(
      String folderName, int? isSignature, bool isNavigatingFromList) async {
    if (isClosed) return;
    emit(GettingFiles());

    final DefaultCacheManager cacheManager = DefaultCacheManager();
    final String cacheKey = "patient_$folderName";

    List<ImageModel> images = [];

    if (isNavigatingFromList) {
      cachedImages = await _getCachedImages(cacheManager, cacheKey);
      images = cachedImages;
      if (images.isEmpty) {
        images = await _fetchImagesFromAPI(folderName, isSignature);
        if (isSignature == null) {
          await _cacheImages(images, cacheManager, cacheKey);
        }
      }
    } else {
      newImages = await _fetchImagesFromAPI(folderName, isSignature);

      if (isSignature == null) {
        images = _mergeImages(cachedImages, newImages);
        await _cacheImages(images, cacheManager, cacheKey);
      } else {
        images = newImages;
      }
    }

    // Sort by date
    images
        .sort((a, b) => _parseDate(b.imgName).compareTo(_parseDate(a.imgName)));

    emit(GetFilesSuccess(images: images));
  }

  List<ImageModel> _mergeImages(
  List<ImageModel> cached,
  List<ImageModel> fresh,
) {
  final Map<String, ImageModel> merged = {
    for (var img in cached) img.imgName: img,
  };

  for (var newImg in fresh) {
    merged[newImg.imgName] = newImg; // إذا موجودة، بيستبدلها تلقائيًا
  }

  return merged.values.toList();
}


  // Merge cached and fresh images without duplicates
  // List<ImageModel> _mergeImages(
  //     List<ImageModel> cached, List<ImageModel> fresh) {
  //   Set<String> existing = {};

  //   for (var img in cached) {
  //     if (img.imgBase64 != null) {
  //       existing.add(_hashImage(img.imgBase64!));
  //     } else if (img.strokesJson != null && img.strokesJson!.isNotEmpty) {
  //       existing.add(_hashContent(img.strokesJson!));
  //     }
  //   }

  //   List<ImageModel> all = List.from(cached);

  //   for (var newImg in fresh) {
  //     if (newImg.imgBase64 != null &&
  //         !existing.contains(_hashImage(newImg.imgBase64!))) {
  //       all.add(newImg);
  //       existing.add(_hashImage(newImg.imgBase64!));
  //     } else if (newImg.strokesJson != null &&
  //         newImg.strokesJson!.isNotEmpty &&
  //         existing.contains(newImg.imgName)) {
  //       all.add(newImg);
  //       existing.add(_hashContent(newImg.strokesJson!));
  //     }
  //   }

  //   return all;
  // }

  Future<List<ImageModel>> _getCachedImages(
      DefaultCacheManager cacheManager, String cacheKey) async {
    try {
      FileInfo? cachedFileInfo = await cacheManager.getFileFromCache(cacheKey);
      if (cachedFileInfo != null)
        return _loadImagesFromCache(cachedFileInfo.file);
    } catch (e) {
      debugPrint("Failed to load cached images: $e");
    }
    return [];
  }

  Future<List<ImageModel>> _fetchImagesFromAPI(
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
          return _parseBase64Images(resultElement.innerText, isSignature);
        }
        return [];
      },
    );
  }

  String _hashImage(Uint8List imgBase64) => base64Encode(imgBase64);
  String _hashContent(String data) => base64Encode(utf8.encode(data));

  Future<List<ImageModel>> _loadImagesFromCache(File cachedFile) async {
    final String jsonString = await cachedFile.readAsString();
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((item) => ImageModel(
              imgName: item['imgName'],
              imgBase64: item['imgBase64'] != null
                  ? Uint8List.fromList(List<int>.from(item['imgBase64']))
                  : null,
              strokesJson: item['strokesJson'] ?? "",
            ))
        .toList();
  }

  Future<void> _cacheImages(List<ImageModel> images,
      DefaultCacheManager cacheManager, String cacheKey) async {
    final List<Map<String, dynamic>> jsonList = images
        .map((image) => {
              'imgName': image.imgName,
              'imgBase64': image.imgBase64?.toList(),
              'strokesJson': image.strokesJson ?? "",
            })
        .toList();
    await cacheManager.putFile(
        cacheKey, Uint8List.fromList(utf8.encode(jsonEncode(jsonList))));
  }

  List<ImageModel> _parseBase64Images(String jsonString, int? isSignature) {
    List<String> base64Strings = jsonString.split(',');
    List<ImageModel> imageModels = [];

    for (var element in base64Strings) {
      List<String> parts = element.split("IMAGENAME");

      if (parts.length == 2) {
        String imgName = parts[1].trim();
        String contentString = parts[0];

        if (imgName.toLowerCase().endsWith('.png')) {
          String cleanedBase64String =
              contentString.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
          String base64Padded = cleanedBase64String.padRight(
            (cleanedBase64String.length + 3) ~/ 4 * 4,
            '=',
          );
          Uint8List imgBase64 = base64Decode(base64Padded);
          imageModels.add(ImageModel(imgName: imgName, imgBase64: imgBase64));
        } else if (imgName.toLowerCase().endsWith('.json')) {
          imageModels
              .add(ImageModel(imgName: imgName, strokesJson: contentString));
        }
      }
    }

    if (imageModels.isNotEmpty &&
        imageModels.first.imgName.toLowerCase() == "signature.png" &&
        isSignature == null) {
      imageModels.removeAt(0);
    }

    return imageModels;
  }

  DateTime _parseDate(String imgName) {
    String nameWithoutExt = imgName.contains(".png")
        ? imgName.split('.png')[0]
        : imgName.contains(".json")
            ? imgName.split('.json')[0]
            : imgName;

    List<String> parts = nameWithoutExt.split(' '); // [date, time]
    List<String> dateParts = parts[0].split('-'); // [dd-MM-yyyy]
    List<String> timeParts = parts[1].split('-'); // [hh-mm-ss]

    int day = int.parse(dateParts[0]);
    int month = int.parse(dateParts[1]);
    int year = int.parse(dateParts[2]);

    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    int second = int.parse(timeParts[2]);

    return DateTime(year, month, day, hour, minute, second);
  }
}

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
