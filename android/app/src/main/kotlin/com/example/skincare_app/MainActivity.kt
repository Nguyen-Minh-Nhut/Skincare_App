package com.example.skincare_app

import android.graphics.BitmapFactory
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "meowskin/scan_input")
            .setMethodCallHandler { call, result ->
                if (call.method != "faces") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                val bitmap = bytes?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
                if (bitmap == null) {
                    result.error("invalid-image", "Cannot decode image", null)
                    return@setMethodCallHandler
                }
                val detector = FaceDetection.getClient(
                    FaceDetectorOptions.Builder()
                        .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE)
                        .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL)
                        .setMinFaceSize(0.10f)
                        .build()
                )
                detector.process(InputImage.fromBitmap(bitmap, 0))
                    .addOnSuccessListener { faces ->
                        result.success(faces.map { face ->
                            mapOf("roll" to face.headEulerAngleZ.toDouble(),
                                  "yaw" to face.headEulerAngleY.toDouble(),
                                  "pitch" to face.headEulerAngleX.toDouble(),
                                  "widthFraction" to face.boundingBox.width().toDouble() / bitmap.width)
                        })
                    }
                    .addOnFailureListener { result.error("face-check-failed", "Cannot validate face", null) }
                    .addOnCompleteListener { detector.close(); bitmap.recycle() }
            }
    }
}
