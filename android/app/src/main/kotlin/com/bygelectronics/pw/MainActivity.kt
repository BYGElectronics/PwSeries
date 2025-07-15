package com.bygelectronics.pw

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothProfile
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val AUDIO_CHANNEL = "bygelectronics.pw/audio_track"
    private var audioTrack: AudioTrack? = null

    private val BT_CHANNEL = "pwseries.bluetooth"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ——— Canal PTT (idéntico) ———
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startAudioTrack" -> { startAudioTrack(); result.success(null) }
                    "writeAudio"      -> { writeAudio(call.arguments as ByteArray); result.success(null) }
                    "stopAudioTrack"  -> { stopAudioTrack(); result.success(null) }
                    else              -> result.notImplemented()
                }
            }

        // ——— Canal A2DP + Classic ———
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BT_CHANNEL)
            .setMethodCallHandler { call: MethodCall, result ->
                val adapter = BluetoothAdapter.getDefaultAdapter()
                    ?: run { result.success(false); return@setMethodCallHandler }

                when (call.method) {
                    // 1) Consultar estado A2DP
                    "isBluetoothAudioConnected" -> {
                        if (!adapter.isEnabled) { result.success(false); return@setMethodCallHandler }
                        adapter.getProfileProxy(this, object: BluetoothProfile.ServiceListener {
                            override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                                val ok = proxy.connectedDevices.any { it.name == "BTPW" }
                                result.success(ok)
                                adapter.closeProfileProxy(profile, proxy)
                            }
                            override fun onServiceDisconnected(profile: Int) {}
                        }, BluetoothProfile.A2DP)
                    }

                    // 2) Conectar A2DP
                    "connectBluetoothAudio" -> {
                        if (!adapter.isEnabled) { result.success(false); return@setMethodCallHandler }
                        val dev = adapter.bondedDevices.firstOrNull { it.name == "BTPW" }
                            ?: run { result.success(false); return@setMethodCallHandler }
                        adapter.getProfileProxy(this, object: BluetoothProfile.ServiceListener {
                            override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                                try {
                                    val method = proxy.javaClass.getMethod("connect", BluetoothDevice::class.java)
                                    val ok = method.invoke(proxy, dev) as Boolean
                                    result.success(ok)
                                } catch (e: Exception) {
                                    result.success(false)
                                } finally {
                                    adapter.closeProfileProxy(profile, proxy)
                                }
                            }
                            override fun onServiceDisconnected(profile: Int) {}
                        }, BluetoothProfile.A2DP)
                    }

                    // 3) Desconectar A2DP
                    "disconnectBluetoothAudio" -> {
                        if (!adapter.isEnabled) { result.success(false); return@setMethodCallHandler }
                        val dev = adapter.bondedDevices.firstOrNull { it.name == "BTPW" }
                            ?: run { result.success(false); return@setMethodCallHandler }
                        adapter.getProfileProxy(this, object: BluetoothProfile.ServiceListener {
                            override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                                try {
                                    val method = proxy.javaClass.getMethod("disconnect", BluetoothDevice::class.java)
                                    val ok = method.invoke(proxy, dev) as Boolean
                                    result.success(ok)
                                } catch (e: Exception) {
                                    result.success(false)
                                } finally {
                                    adapter.closeProfileProxy(profile, proxy)
                                }
                            }
                            override fun onServiceDisconnected(profile: Int) {}
                        }, BluetoothProfile.A2DP)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ——— Métodos PTT (sin cambios) ———
    private fun startAudioTrack() {
        val sr = 8000
        val buf = AudioTrack.getMinBufferSize(
            sr,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        audioTrack = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(sr)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                .setBufferSizeInBytes(buf)
                .setTransferMode(AudioTrack.MODE_STREAM)
                .build()
        } else {
            AudioTrack(
                AudioManager.STREAM_MUSIC,
                sr,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                buf,
                AudioTrack.MODE_STREAM
            )
        }
        audioTrack?.play()
    }
    private fun writeAudio(data: ByteArray) {
        audioTrack?.write(data, 0, data.size)
    }
    private fun stopAudioTrack() {
        audioTrack?.stop()
        audioTrack?.release()
        audioTrack = null
    }
}
