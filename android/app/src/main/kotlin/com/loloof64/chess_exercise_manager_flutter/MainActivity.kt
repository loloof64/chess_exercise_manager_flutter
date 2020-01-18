package com.loloof64.chess_exercise_manager_flutter

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel
import com.kalab.chess.enginesupport.ChessEngineResolver
import com.kalab.chess.enginesupport.ChessEngine
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "loloof64.chess_utils/engine_discovery"
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        { call, result ->
                            if (call.method.equals("copyAllEnginesToAppDir")) {
                                copyAllEnginesToAppDir()
                                result.success(1)
                            }
                            else if (call.method.equals("getEnginesList")) {
                                val enginesNames = getEnginesNames()
                                result.success(enginesNames);
                            }
                            else {
                                result.notImplemented();
                            }
                        }
                )
    }

    private fun copyAllEnginesToAppDir() {
        val engineResolver = ChessEngineResolver(this)
        val engines = engineResolver.resolveEngines()
        val destinationFolder = File(getFilesDir(), "Engines")
        destinationFolder.mkdir()
        engines.forEach{
            it.copyToFiles(getContentResolver(), destinationFolder)
        }
    }

    private fun getEnginesNames() : String {
        val enginesDir = File(getFilesDir(), "Engines")
        val enginesNames = enginesDir.listFiles().map{
            val name = it.name
            val pattern = "lib(.*)\\.so".toRegex()
            pattern.find(name)?.groupValues?.get(1) ?: name
        }
        return enginesNames.joinToString(",")
    }
}
