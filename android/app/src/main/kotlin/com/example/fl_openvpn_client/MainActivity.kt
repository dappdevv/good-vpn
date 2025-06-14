package com.example.fl_openvpn_client

import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "fl_openvpn_client"
    private val EVENT_CHANNEL = "fl_openvpn_client/status"
    private val VPN_REQUEST_CODE = 1001

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var vpnServiceManager: VpnServiceManager? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)

        vpnServiceManager = VpnServiceManager(this, eventChannel)

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    vpnServiceManager?.initialize()
                    result.success(true)
                }
                "hasPermission" -> {
                    val hasPermission = VpnService.prepare(this) == null
                    result.success(hasPermission)
                }
                "requestPermission" -> {
                    requestVpnPermission(result)
                }
                "connect" -> {
                    val config = call.argument<String>("config")
                    val username = call.argument<String>("username")
                    val password = call.argument<String>("password")
                    val serverName = call.argument<String>("serverName")

                    if (config != null) {
                        vpnServiceManager?.connect(config, username, password, serverName)
                        result.success(true)
                    } else {
                        result.error("INVALID_CONFIG", "Configuration is required", null)
                    }
                }
                "disconnect" -> {
                    vpnServiceManager?.disconnect()
                    result.success(true)
                }
                "getConnectionStats" -> {
                    val stats = vpnServiceManager?.getConnectionStats()
                    result.success(stats)
                }
                "dispose" -> {
                    vpnServiceManager?.dispose()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestVpnPermission(result: MethodChannel.Result) {
        val intent = VpnService.prepare(this)
        if (intent != null) {
            pendingResult = result
            startActivityForResult(intent, VPN_REQUEST_CODE)
        } else {
            result.success(true)
        }
    }

    private var pendingResult: MethodChannel.Result? = null

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == VPN_REQUEST_CODE) {
            val granted = resultCode == RESULT_OK
            pendingResult?.success(granted)
            pendingResult = null
        }
    }
}
