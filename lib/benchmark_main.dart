import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skincare_app/screens/home/acne_detector.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: _BenchmarkPage()));
}

class _BenchmarkPage extends StatefulWidget {
  const _BenchmarkPage();

  @override
  State<_BenchmarkPage> createState() => _BenchmarkPageState();
}

class _BenchmarkPageState extends State<_BenchmarkPage> {
  String status = 'Đang chuẩn bị benchmark...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<Uint8List> _asset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<void> _run() async {
    AcneDetectorPipeline? pipeline;
    try {
      pipeline = await AcneDetectorPipeline.create();
      final cases = <String, Uint8List>{
        'acne': await _asset('assets/image/anh_da_mun.jpg'),
        'landscape': await _asset('assets/image/anh_2.jpg'),
      };
      final output = <String, dynamic>{};
      for (final entry in cases.entries) {
        setState(() => status = 'Đang đo ${entry.key}...');
        await pipeline.detectAndFilterWithBenchmark(entry.value); // warm-up
        final runs = <Map<String, dynamic>>[];
        for (var i = 0; i < 10; i++) {
          final result = await pipeline.detectAndFilterWithBenchmark(
            entry.value,
          );
          final run = <String, dynamic>{
            'decode_us': result.decodeMicroseconds,
            'yolo_us': result.yoloMicroseconds,
            'classifier_us': result.classifierMicroseconds,
            'total_us': result.totalMicroseconds,
            'candidates': result.candidateCount,
            'classified': result.classifiedCount,
            'boxes': result.boxes.length,
            'rss_bytes': ProcessInfo.currentRss,
          };
          runs.add(run);
          debugPrint('BENCHMARK_RUN=${entry.key},${i + 1},${jsonEncode(run)}');
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        output[entry.key] = runs;
      }
      try {
        await pipeline.detectAndFilterWithBenchmark(
          Uint8List.fromList(utf8.encode('not-an-image')),
        );
        output['invalid_image'] = 'returned_without_exception';
      } catch (error) {
        output['invalid_image'] = 'handled_exception: ${error.runtimeType}';
      }
      debugPrint('BENCHMARK_INVALID=${output['invalid_image']}');
      debugPrint('BENCHMARK_JSON=${jsonEncode(output)}');
      debugPrint('BENCHMARK_DONE');
      setState(() => status = 'Benchmark hoàn tất.');
    } catch (error, stackTrace) {
      debugPrint('BENCHMARK_ERROR=$error');
      debugPrint('$stackTrace');
      setState(() => status = 'Benchmark lỗi: $error');
    } finally {
      await pipeline?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(padding: const EdgeInsets.all(24), child: Text(status)),
    ),
  );
}
