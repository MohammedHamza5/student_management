import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'upload_state.dart';
import '../model/mock_data.dart';

class UploadCubit extends Cubit<UploadState> {
  UploadCubit() : super(UploadInitial());

  List<MockResearch> researchesMale = [];
  List<MockResearch> researchesFemale = [];
  final Box _box = Hive.box('app_data');
  bool _isLoaded = false;

  void loadResearches() {
    if (_isLoaded) return;

    final maleData = _box.get('researchesMale', defaultValue: []);
    final femaleData = _box.get('researchesFemale', defaultValue: []);

    researchesMale = (maleData as List<dynamic>).map((item) {
      final mapItem = Map<String, dynamic>.from(item as Map);
      return MockResearch.fromJson(mapItem);
    }).toList();

    researchesFemale = (femaleData as List<dynamic>).map((item) {
      final mapItem = Map<String, dynamic>.from(item as Map);
      return MockResearch.fromJson(mapItem);
    }).toList();

    _isLoaded = true;
    if (researchesMale.isNotEmpty || researchesFemale.isNotEmpty) {
      emit(UploadSuccess(researchesMale.isNotEmpty ? researchesMale.length : researchesFemale.length, researchesMale.isNotEmpty ? "الذكور" : "الإناث"));
    }
  }

  Future<void> uploadFile(String gender, dynamic file) async {
    emit(UploadLoading());

    try {
      Uint8List bytes;
      if (kIsWeb) {
        bytes = (file as FilePickerResult).files.single.bytes!;
        print("File bytes read on web: ${bytes.length} bytes");
      } else {
        bytes = await (file as File).readAsBytes();
        print("File bytes read on device: ${bytes.length} bytes");
      }

      final archive = ZipDecoder().decodeBytes(bytes);

      String documentContent = '';
      for (final archiveFile in archive) {
        if (archiveFile.name == 'word/document.xml') {
          documentContent = utf8.decode(archiveFile.content as List<int>);
          print("Found document.xml, content length: ${documentContent.length}");
          break;
        }
      }

      if (documentContent.isEmpty) {
        print("No document.xml found or content is empty");
        emit(UploadError("فشل في قراءة الملف: لا يوجد محتوى"));
        return;
      }

      print("Document Content: $documentContent");

      final document = xml.XmlDocument.parse(documentContent);
      const wordNamespace = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';
      final paragraphs = document.findAllElements('p', namespace: wordNamespace);
      final List<MockResearch> extractedResearches = [];

      print("Found ${paragraphs.length} paragraphs");

      for (var paragraph in paragraphs) {
        final textElements = paragraph.findAllElements('t', namespace: wordNamespace);
        final text = textElements.map((e) => e.text).join(' ').trim();
        if (text.isNotEmpty) {
          extractedResearches.add(MockResearch(text));
          print("Extracted research: $text");
        }
      }

      if (extractedResearches.isEmpty) {
        print("No researches extracted from paragraphs");
        emit(UploadError("لم يتم العثور على أبحاث في الملف"));
        return;
      }

      if (gender == "الذكور") {
        researchesMale = extractedResearches;
        _box.put('researchesMale', researchesMale.map((r) => r.toJson()).toList());
        emit(UploadSuccess(researchesMale.length, gender));
      } else if (gender == "الإناث") {
        researchesFemale = extractedResearches;
        _box.put('researchesFemale', researchesFemale.map((r) => r.toJson()).toList());
        emit(UploadSuccess(researchesFemale.length, gender));
      }

      _isLoaded = true;
    } catch (e) {
      print("Detailed error during file processing: $e");
      emit(UploadError("خطأ أثناء معالجة الملف: $e"));
    }
  }

  void resetResearches(String gender) {
    if (gender == "الذكور") {
      researchesMale = [];
      _box.put('researchesMale', []);
    } else if (gender == "الإناث") {
      researchesFemale = [];
      _box.put('researchesFemale', []);
    }
    emit(UploadInitial());
    _isLoaded = false;
  }

  void clearAllResearches() {
    _box.delete('researchesMale');
    _box.delete('researchesFemale');
    researchesMale.clear();
    researchesFemale.clear();
    emit(UploadInitial());
  }

  // void clearResearchesByGender(String gender) {
  //   final box = Hive.box<MockResearch>('researches');
  //   final researchList = box.values.toList();
  //
  //   for (var research in researchList) {
  //     if (research.gender == gender) {
  //       box.delete(research.key);
  //     }
  //   }
  //   emit(UploadState.loaded(researches: box.values.toList()));
  // }
}