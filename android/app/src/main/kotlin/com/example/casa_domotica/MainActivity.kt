package com.example.casa_domotica

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.os.Build
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import java.util.UUID
import android.bluetooth.BluetoothSocket

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.bluetooth/channel"
    private val REQUEST_ENABLE_BT = 1
    private var bluetoothSocket: BluetoothSocket? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPairedDevices" -> {
                    val devices = getPairedDevices(bluetoothAdapter)
                    result.success(devices)
                }
                "connectToDevice" -> {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        connectToDevice(address, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Dirección nula", null)
                    }
                }
                "sendData" -> {
                    val data = call.argument<String>("data")
                    if (data != null) {
                        sendData(data)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Datos nulos", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getPairedDevices(bluetoothAdapter: BluetoothAdapter?): List<Map<String, String>> {
        val devicesList = ArrayList<Map<String, String>>()

        if (bluetoothAdapter == null) {
            return devicesList
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.BLUETOOTH_CONNECT), REQUEST_ENABLE_BT)
                return devicesList
            }
        }

        val pairedDevices: Set<BluetoothDevice>? = bluetoothAdapter.bondedDevices
        pairedDevices?.forEach { device ->
            val deviceInfo = mapOf("name" to device.name, "address" to device.address)
            devicesList.add(deviceInfo)
        }

        return devicesList
    }

    private fun connectToDevice(address: String, result: MethodChannel.Result) {
        val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
        val device = bluetoothAdapter?.getRemoteDevice(address)

        if (device != null) {
            Thread {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.BLUETOOTH_CONNECT), REQUEST_ENABLE_BT)
                            return@Thread
                        }
                    }

                    val uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB") // UUID estándar para SPP
                    bluetoothSocket = device.createRfcommSocketToServiceRecord(uuid)
                    bluetoothSocket?.connect()
                    runOnUiThread {
                        result.success(null)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                    runOnUiThread {
                        result.error("CONNECTION_ERROR", e.message, null)
                    }
                }
            }.start()
        } else {
            result.error("DEVICE_NOT_FOUND", "Dispositivo no encontrado", null)
        }
    }

    private fun sendData(data: String) {
        try {
            bluetoothSocket?.outputStream?.write(data.toByteArray())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}

