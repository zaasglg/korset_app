import 'dart:io';
import 'dart:async';
import 'package:video_compress/video_compress.dart';

/// Helper class for video compression with progress tracking
class VideoCompressionHelper {
  /// Compress video with progress tracking
  static Future<File?> compressVideo(
    File videoFile, {
    VideoQuality quality = VideoQuality.MediumQuality,
    bool deleteOrigin = false,
    bool includeAudio = true,
    Function(double)? onProgress,
  }) async {
    try {
      // Create a local subscription for this compression operation
      Subscription? localSubscription;
      
      try {
        // Subscribe to compression progress stream
        localSubscription = VideoCompress.compressProgress$.subscribe((progress) {
          print('Video compression progress: ${progress}%');
          if (onProgress != null) {
            onProgress(progress);
          }
        });
      } catch (e) {
        print('Warning: Could not subscribe to progress stream: $e');
        // Continue without progress tracking
      }

      final compressedInfo = await VideoCompress.compressVideo(
        videoFile.path,
        quality: quality,
        deleteOrigin: deleteOrigin,
        includeAudio: includeAudio,
      );

      // Cancel local subscription after compression is complete
      try {
        localSubscription?.unsubscribe();
      } catch (e) {
        print('Warning: Could not unsubscribe from progress stream: $e');
      }

      if (compressedInfo != null && compressedInfo.file != null) {
        final compressedFile = compressedInfo.file!;
        final originalSize = videoFile.lengthSync();
        final compressedSize = compressedFile.lengthSync();
        final compressionRatio = ((originalSize - compressedSize) / originalSize * 100);

        print('✅ Video compressed successfully:');
        print('   Original size: ${(originalSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        print('   Compressed size: ${(compressedSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        print('   Compression ratio: ${compressionRatio.toStringAsFixed(1)}%');

        return compressedFile;
      } else {
        print('❌ Video compression failed, using original file');
        return videoFile;
      }
    } catch (e) {
      print('❌ Video compression error: $e');
      print('   Using original file');
      return videoFile;
    }
  }

  /// Get media info for a video file
  static Future<MediaInfo?> getMediaInfo(String videoPath) async {
    try {
      return await VideoCompress.getMediaInfo(videoPath);
    } catch (e) {
      print('❌ Error getting media info: $e');
      return null;
    }
  }

  /// Cancel any ongoing compression
  static Future<void> cancelCompression() async {
    try {
      await VideoCompress.cancelCompression();
    } catch (e) {
      print('❌ Error canceling compression: $e');
    }
  }

  /// Delete all cached files
  static Future<void> deleteAllCache() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (e) {
      print('❌ Error deleting cache: $e');
    }
  }
}
