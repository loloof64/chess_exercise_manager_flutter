package com.loloof64.chess_exercise_manager_flutter

import androidx.annotation.NonNull
import kotlin.concurrent.thread
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel
import com.kalab.chess.enginesupport.ChessEngineResolver
import com.kalab.chess.enginesupport.ChessEngine
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "loloof64.chess_utils/engine_discovery"
    private val enginesDirectory = "engines"
    private var processInput: java.io.BufferedWriter? = null
    private var processOuput: java.io.BufferedReader? = null
    private var process: Process? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
        methodChannel?.setMethodCallHandler(
                        { call, result ->
                            if (call.method.equals("copyAllEnginesToAppDir")) {
                                copyAllEnginesToAppDir()
                                result.success(1)
                            }
                            else if (call.method.equals("getEnginesList")) {
                                val enginesNames = getEnginesNames()
                                result.success(enginesNames)
                            }
                            else if (call.method.equals("chooseEngine")) {
                                val simpleName = call.arguments
                                chooseEngine(simpleName.toString())
                                result.success(1)
                            }
                            else if (call.method.equals("sendCommandToEngine")) {
                                sendCommandToEngine(call.arguments.toString())
                                result.success(1)
                            }
                            else {
                                result.notImplemented()
                            }
                        }
                )
    }

    private fun copyAllEnginesToAppDir() {
        val engineResolver = ChessEngineResolver(this)
        val engines = engineResolver.resolveEngines()
        val destinationFolder = File(getFilesDir(), enginesDirectory)
        destinationFolder.mkdir()
        engines.forEach{
            it.copyToFiles(getContentResolver(), destinationFolder)
        }
    }

    private fun getEnginesNames() : String {
        val enginesDir = File(getFilesDir(), enginesDirectory)
        val enginesNames = enginesDir.listFiles().map{
            val name = it.name
            val pattern = "lib(.*)\\.so".toRegex()
            pattern.find(name)?.groupValues?.get(1) ?: name
        }
        return enginesNames.joinToString(",")
    }

    private fun chooseEngine(simpleName: String) {
        closeEngineProcess()

        val completeName = "lib$simpleName.so"
        val directory = File(getFilesDir(), enginesDirectory)
        val pb = java.lang.ProcessBuilder()

        pb.command("./$completeName")
        pb.directory(directory)

        process = pb.start()

        processOuput = java.io.BufferedReader(java.io.InputStreamReader(process?.getInputStream()))
        processInput = java.io.BufferedWriter(java.io.OutputStreamWriter(process?.getOutputStream()))

        startEngineOutputReader()
    }

    private fun startEngineOutputReader() {
        val outputReaderThread = thread(isDaemon = true) {
            try {
                while (true) {
                    val line = processOuput?.readLine()
                    if (line != null && line.length > 0) {
                        runOnUiThread(object: Runnable{
                            override fun run() {
                                methodChannel?.invokeMethod("processEngineOutput", line)
                            }
                        })
                    }
                }
            } catch (ex: java.io.IOException) {

            }
        }
    }

    private fun sendCommandToEngine(command: String) {
        processInput?.write(command, 0, command.length)
        processInput?.newLine()
        processInput?.flush()
    }

    private fun closeEngineProcess() {
        processInput?.close()
        processInput = null

        processOuput?.close()
        processOuput = null

        process?.destroy()
    }

    override fun onDestroy() {
        closeEngineProcess()
        super.onDestroy()
    }
}
