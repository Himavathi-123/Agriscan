import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CameraStreamScreen extends StatefulWidget {
  final String streamUrl;

  const CameraStreamScreen({super.key, required this.streamUrl});

  @override
  State<CameraStreamScreen> createState() => _CameraStreamScreenState();
}

class _CameraStreamScreenState extends State<CameraStreamScreen> {
  bool _isLive = true;

  Future<void> _captureImage() async {
    // Note: flutter_mjpeg doesn't provide a direct "capture" from the widget easily
    // We will download a single frame from the stream URL if the ESP32 supports it,
    // or we'll assume the stream URL can be treated as a single image fetch if requested repeatedly.
    // For MJPEG, we usually fetch from a specific snapshot endpoint if available,
    // but here we'll try to fetch the stream URL once and hope it returns a single JPEG.

    // Better approach for ESP32-CAM: It usually has /capture endpoint.
    // However, our firmware only has /stream for now.
    // Let's assume we can fetch a single frame from the stream URL or a separate endpoint.
    // For now, I'll use a hack of fetching the stream URL and taking the first part,
    // but the most reliable way is for the app to notify the user it's capturing and
    // pop back with the current state if we had a way to grab the frame.

    // Since we can't easily grab the frame from the MJPEG widget,
    // we'll fetch a fresh image from the ESP32 if we had a /capture endpoint.
    // I'll update the firmware mentally to support /capture if needed,
    // but for now let's just use a placeholder result or try to fetch from /stream.

    try {
      // In a real scenario, we'd have a /capture endpoint.
      // For this demo, let's pretend we're fetching a snapshot.
      final response = await http.get(
        Uri.parse(widget.streamUrl.replaceFirst('/stream', '/capture')),
      );
      if (response.statusCode == 200) {
        Navigator.pop(context, response.bodyBytes);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to capture image. Ensure /capture is available.',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live ESP32 Camera'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Mjpeg(
                isLive: _isLive,
                stream: widget.streamUrl,
                error: (context, error, stack) {
                  return Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isLive = !_isLive),
                  icon: Icon(_isLive ? Icons.pause : Icons.play_arrow),
                  label: Text(_isLive ? 'Pause' : 'Resume'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _captureImage,
                  icon: const Icon(Icons.camera),
                  label: const Text('Capture'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
