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

  Future<List<dynamic>> getImages(String folderName) async {
    emit(GettingFiles());
    var result = await dataRepo.soapRequest(
        sqlStr: "",
        action: "IO_get_Images",
        newName: "",
        currentFolder: folderName,
        filePath: "",
        imageBytes: "");
    result.fold((failure) {
      emit(GetFilesFaild(error: failure.errorMsg));
    }, (dMaster) async {
      final document = xml.XmlDocument.parse(dMaster.body);
      if (document.findAllElements('IO_get_ImagesResult').isNotEmpty) {
        final resultElement =
            document.findAllElements('IO_get_ImagesResult').first;
        final jsonString = resultElement.innerText;

        try {
          // Split the Base64 string on commas
          List<String> base64Strings = jsonString.split(',');
          List<ImageModel> imageModels = [];

          for (var element in base64Strings) {
            List<String> parts = element.split("IMAGENAME");

            if (parts.length == 2) {
              String imgName = parts[1].split(' ')[0].trim(); // The image name
              String base64String = parts[0].trim(); // The Base64 string
              // Clean the Base64 string
              String cleanedBase64String =
                  base64String.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
              // Ensure the Base64 string is properly padded
              String base64Padded = cleanedBase64String.padRight(
                (cleanedBase64String.length + 3) ~/ 4 * 4,
                '=',
              );
              // Decode the Base64 string into Uint8List
              Uint8List imgBase64 = base64Decode(base64Padded);
              // Create the ImageModel instance
              imageModels
                  .add(ImageModel(imgName: imgName, imgBase64: imgBase64));
            }
          }

          imageModels.removeAt(0);
          emit(
            GetFilesSuccess(images: imageModels),
          );
        } catch (e) {
          emit(
            GetFilesFaild(
              error: e.toString(),
            ),
          );
        }
      } else {
        emit(GetFilesSuccess(images: const []));
      }
    });
    return [];
  }

  Future<List<ImageModel>> getImages1(String folderName) async {
    emit(GettingFiles());

    final DefaultCacheManager cacheManager = DefaultCacheManager();
    final String cacheKey = "patient_$folderName";

    // ✅ Step 1: Check if images exist in cache
    FileInfo? cachedFileInfo = await cacheManager.getFileFromCache(cacheKey);
    if (cachedFileInfo != null) {
      try {
        final List<ImageModel> cachedImages =
            await _loadImagesFromCache(cachedFileInfo.file);
        emit(GetFilesSuccess(images: cachedImages));
        return cachedImages; // Return cached images immediately
      } catch (e) {
        emit(GetFilesFaild(error: "Failed to load cached images: $e"));
      }
    }

    // ✅ Step 2: Fetch images from the API
    var result = await dataRepo.soapRequest(
      sqlStr: "",
      action: "IO_get_Images",
      newName: "",
      currentFolder: folderName,
      filePath: "",
      imageBytes: "",
    );

    return result.fold((failure) {
      emit(GetFilesFaild(error: failure.errorMsg));
      return [];
    }, (dMaster) async {
      final document = xml.XmlDocument.parse(dMaster.body);
      if (document.findAllElements('IO_get_ImagesResult').isNotEmpty) {
        final resultElement =
            document.findAllElements('IO_get_ImagesResult').first;
        final jsonString = resultElement.innerText;

        try {
          List<ImageModel> imageModels = _parseBase64Images(jsonString);

          // ✅ Step 3: Store fetched images in cache
          await _cacheImages(imageModels, cacheManager, cacheKey);

          emit(GetFilesSuccess(images: imageModels));
          return imageModels;
        } catch (e) {
          emit(GetFilesFaild(error: "Error processing images: $e"));
          return [];
        }
      } else {
        emit(GetFilesSuccess(images: const []));
        return [];
      }
    });
  }

  Future<List<ImageModel>> getImages2(String folderName) async {
    emit(GettingFiles());

    final DefaultCacheManager cacheManager = DefaultCacheManager();
    final String cacheKey = "patient_$folderName";

    // ✅ Step 1: Check if images exist in cache
    FileInfo? cachedFileInfo = await cacheManager.getFileFromCache(cacheKey);
    List<ImageModel> cachedImages = [];

    if (cachedFileInfo != null) {
      try {
        // Load images from cache
        cachedImages = await _loadImagesFromCache(cachedFileInfo.file);
      } catch (e) {
        emit(GetFilesFaild(error: "Failed to load cached images: $e"));
      }
    }

    // ✅ Step 2: Fetch images from the API
    var result = await dataRepo.soapRequest(
      sqlStr: "",
      action: "IO_get_Images",
      newName: "",
      currentFolder: folderName,
      filePath: "",
      imageBytes: "",
    );

    return result.fold((failure) {
      emit(GetFilesFaild(error: failure.errorMsg));
      return [];
    }, (dMaster) async {
      final document = xml.XmlDocument.parse(dMaster.body);
      if (document.findAllElements('IO_get_ImagesResult').isNotEmpty) {
        final resultElement =
            document.findAllElements('IO_get_ImagesResult').first;
        final jsonString = resultElement.innerText;

        try {
          // Parse the new images
          List<ImageModel> newImages = _parseBase64Images(jsonString);

          // ✅ Step 3: Merge the new images with cached images (only add new ones)
          List<ImageModel> allImages = List.from(cachedImages);

          for (var newImage in newImages) {
            if (!allImages
                .any((image) => image.imgBase64 == newImage.imgBase64)) {
              allImages.add(
                  newImage); // Add the new image if it's not already in the list
            }
          }

          // ✅ Step 4: Update the cache with the new set of images
          await _cacheImages(allImages, cacheManager, cacheKey);

          emit(GetFilesSuccess(images: allImages));
          return allImages;
        } catch (e) {
          emit(GetFilesFaild(error: "Error processing images: $e"));
          return [];
        }
      } else {
        emit(GetFilesSuccess(images: const []));
        return [];
      }
    });
  }

  // Future<void> getImages3(String folderName) async {
  //   if (isClosed) return;
  //   debugPrint("Started ${DateTime.now()}");
  //   emit(GettingFiles());

  //   final DefaultCacheManager cacheManager = DefaultCacheManager();
  //   final String cacheKey = "patient_$folderName";

  //   // ✅ Step 1: Check if images exist in cache
  //   FileInfo? cachedFileInfo = await cacheManager.getFileFromCache(cacheKey);
  //   List<ImageModel> cachedImages = [];

  //   if (cachedFileInfo != null) {
  //     try {
  //       // Load images from cache
  //       cachedImages = await _loadImagesFromCache(cachedFileInfo.file);
  //       emit(GetFilesSuccess(images: cachedImages));
  //     } catch (e) {
  //       emit(GetFilesFaild(error: "Failed to load cached images: $e"));
  //     }
  //   }

  //   // ✅ Step 2: Fetch images from the API
  //   var result = await dataRepo.soapRequest(
  //     sqlStr: "",
  //     action: "IO_get_Images",
  //     newName: "",
  //     currentFolder: folderName,
  //     filePath: "",
  //     imageBytes: "",
  //   );

  //   return result.fold((failure) {
  //     emit(GetFilesFaild(error: failure.errorMsg));
  //   }, (dMaster) async {
  //     final document = xml.XmlDocument.parse(dMaster.body);
  //     if (document.findAllElements('IO_get_ImagesResult').isNotEmpty) {
  //       final resultElement =
  //           document.findAllElements('IO_get_ImagesResult').first;
  //       final jsonString = resultElement.innerText;

  //       try {
  //         // Parse the new images
  //         List<ImageModel> newImages = _parseBase64Images(jsonString);

  //         // ✅ Step 3: Merge the new images with cached images (only add new ones)
  //         List<ImageModel> allImages = List.from(cachedImages);

  //         // Create a Set of image base64 bytes to check duplicates
  //         Set<String> existingImageHashes =
  //             cachedImages.map((img) => _hashImage(img.imgBase64)).toSet();

  //         for (var newImage in newImages) {
  //           String newImageHash = _hashImage(newImage.imgBase64);

  //           // Add the new image only if it's not already in the cache
  //           if (!existingImageHashes.contains(newImageHash)) {
  //             allImages.add(
  //                 newImage); // Add the new image if it's not already in the list
  //             existingImageHashes
  //                 .add(newImageHash); // Add to the set of existing hashes
  //             debugPrint("Added new image: ${DateTime.now()}");
  //           }
  //         }

  //         // ✅ Step 4: Update the cache with the new set of images
  //         await _cacheImages(allImages, cacheManager, cacheKey);

  //         emit(GetFilesSuccess(images: allImages));
  //       } catch (e) {
  //         emit(GetFilesFaild(error: "Error processing images: $e"));
  //       }
  //     } else {
  //       emit(GetFilesSuccess(images: const []));
  //     }
  //   });
  // }

  Future<void> getImages3(String folderName) async {
    if (isClosed) return;
    debugPrint("Started ${DateTime.now()}");
    emit(GettingFiles());

    final DefaultCacheManager cacheManager = DefaultCacheManager();
    final String cacheKey = "patient_$folderName";

    // ✅ Fetch from cache and API in parallel
    final results = await Future.wait([
      _getCachedImages(cacheManager, cacheKey), // Fetch from cache
      _fetchImagesFromAPI(folderName), // Fetch from API
    ]);

    // ✅ Step 1: Get cached images
    List<ImageModel> cachedImages = results[0];
    if (cachedImages.isNotEmpty) {
      emit(GetFilesSuccess(images: cachedImages));
    }

    // ✅ Step 2: Get new images from API
    List<ImageModel> newImages = results[1];

    // ✅ Step 3: Merge cache and API results
    Set<String> existingImageHashes =
        cachedImages.map((img) => _hashImage(img.imgBase64)).toSet();
    List<ImageModel> allImages = List.from(cachedImages);

    for (var newImage in newImages) {
      String newImageHash = _hashImage(newImage.imgBase64);
      if (!existingImageHashes.contains(newImageHash)) {
        allImages.add(newImage);
        existingImageHashes.add(newImageHash);
      }
    }

    // ✅ Step 4: Update cache with the final merged images
    await _cacheImages(allImages, cacheManager, cacheKey);

    // ✅ Emit the final images list
    emit(GetFilesSuccess(images: allImages));
  }

  Future<List<ImageModel>> _getCachedImages(
      DefaultCacheManager cacheManager, String cacheKey) async {
    try {
      FileInfo? cachedFileInfo = await cacheManager.getFileFromCache(cacheKey);
      if (cachedFileInfo != null) {
        return _loadImagesFromCache(cachedFileInfo.file);
      }
    } catch (e) {
      debugPrint("Failed to load cached images: $e");
    }
    return [];
  }

  Future<List<ImageModel>> _fetchImagesFromAPI(String folderName) async {
    var result = await dataRepo.soapRequest(
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
          return _parseBase64Images(resultElement.innerText);
        }
        return [];
      },
    );
  }

// ✅ Function to hash image base64 for duplicate check
  String _hashImage(Uint8List imgBase64) {
    // Convert the image bytes to a hash (using a simple hash method like MD5 or SHA1)
    return base64Encode(
        imgBase64); // This works because base64-encoded strings can be directly compared
  }

// ✅ Function to load images from cache
  Future<List<ImageModel>> _loadImagesFromCache(File cachedFile) async {
    final String jsonString = await cachedFile.readAsString();
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((item) => ImageModel(
              imgName: item['imgName'],
              imgBase64: Uint8List.fromList(List<int>.from(item['imgBase64'])),
            ))
        .toList();
  }

// ✅ Function to cache images
  Future<void> _cacheImages(List<ImageModel> images,
      DefaultCacheManager cacheManager, String cacheKey) async {
    final List<Map<String, dynamic>> jsonList = images
        .map((image) => {
              'imgName': image.imgName,
              'imgBase64': image.imgBase64.toList(),
            })
        .toList();
    await cacheManager.putFile(
        cacheKey, Uint8List.fromList(utf8.encode(jsonEncode(jsonList))));
  }

// ✅ Function to parse Base64 images from API response
  List<ImageModel> _parseBase64Images(String jsonString) {
    List<String> base64Strings = jsonString.split(',');
    List<ImageModel> imageModels = [];

    for (var element in base64Strings) {
      List<String> parts = element.split("IMAGENAME");

      if (parts.length == 2) {
        String imgName = parts[1].split(' ')[0].trim();
        String base64String = parts[0].trim();

        // Clean and decode Base64 string
        String cleanedBase64String =
            base64String.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
        String base64Padded = cleanedBase64String.padRight(
          (cleanedBase64String.length + 3) ~/ 4 * 4,
          '=',
        );

        Uint8List imgBase64 = base64Decode(base64Padded);
        imageModels.add(ImageModel(imgName: imgName, imgBase64: imgBase64));
      }
    }

    imageModels.removeAt(0); // Remove unwanted first element if necessary
    return imageModels;
  }

// // ✅ Function to load images from cache
//   Future<List<ImageModel>> _loadImagesFromCache(File cachedFile) async {
//     final String jsonString = await cachedFile.readAsString();
//     final List<dynamic> jsonList = jsonDecode(jsonString);
//     return jsonList
//         .map((item) => ImageModel(
//               imgName: item['imgName'],
//               imgBase64: Uint8List.fromList(List<int>.from(item['imgBase64'])),
//             ))
//         .toList();
//   }

// // ✅ Function to cache images
//   Future<void> _cacheImages(List<ImageModel> images,
//       DefaultCacheManager cacheManager, String cacheKey) async {
//     final List<Map<String, dynamic>> jsonList = images
//         .map((image) => {
//               'imgName': image.imgName,
//               'imgBase64': image.imgBase64.toList(),
//             })
//         .toList();
//     await cacheManager.putFile(
//         cacheKey, Uint8List.fromList(utf8.encode(jsonEncode(jsonList))));
//   }

// // ✅ Function to parse Base64 images from API response
//   List<ImageModel> _parseBase64Images(String jsonString) {
//     List<String> base64Strings = jsonString.split(',');
//     List<ImageModel> imageModels = [];

//     for (var element in base64Strings) {
//       List<String> parts = element.split("IMAGENAME");

//       if (parts.length == 2) {
//         String imgName = parts[1].split(' ')[0].trim();
//         String base64String = parts[0].trim();

//         // Clean and decode Base64 string
//         String cleanedBase64String =
//             base64String.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
//         String base64Padded = cleanedBase64String.padRight(
//           (cleanedBase64String.length + 3) ~/ 4 * 4,
//           '=',
//         );

//         Uint8List imgBase64 = base64Decode(base64Padded);
//         imageModels.add(ImageModel(imgName: imgName, imgBase64: imgBase64));
//       }
//     }

//     imageModels.removeAt(0);
//     return imageModels;
//   }
}


  // List<String> base64Strings = List<String>.from(json.decode(jsonString));
      // List<Uint8List> imageBytes = base64Strings
      //     .map((base64String) => base64Decode(base64String))
      //     .toList();
      // setState(() {
      //   _images = imageBytes;
      //   _isLoading = false;
      // });
      // final List<dynamic> decodedJson = jsonDecode(jsonString);
      // final List<Map<String, dynamic>> dataList =
      //     List<Map<String, dynamic>>.from(decodedJson);
      // if (dataList.isNotEmpty) {
      //   driver = dataList;
      //   print("drivers $dataList");
      //   // emit(LoadingDriversSuccessful(drivers));
      // }



// for (var element in base64Strings) {
          //   element.split("IMAGENAME");
          // }
          // // Decode each Base64 string
          // List<Uint8List> imageBytesList = base64Strings.map((str) {
          //   String cleanedBase64String =
          //       str.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
          //   String base64Padded = cleanedBase64String.padRight(
          //     (cleanedBase64String.length + 3) ~/ 4 * 4,
          //     '=',
          //   );
          //   return base64Decode(base64Padded);
          // }).toList();
