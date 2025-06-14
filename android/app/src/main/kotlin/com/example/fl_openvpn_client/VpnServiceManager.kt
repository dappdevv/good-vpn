package com.example.fl_openvpn_client

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.atomic.AtomicBoolean

class VpnServiceManager(
    private val context: Context,
    private val eventChannel: EventChannel
) {
    private var openVpnService: OpenVpnService? = null
    private var isServiceBound = AtomicBoolean(false)
    private var eventSink: EventChannel.EventSink? = null
    
    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as OpenVpnService.LocalBinder
            openVpnService = binder.getService()
            isServiceBound.set(true)
            
            // Set up status listener
            openVpnService?.setStatusListener { status ->
                eventSink?.success(mapOf(
                    "state" to status.state,
                    "message" to status.message,
                    "serverIp" to status.serverIp,
                    "localIp" to status.localIp,
                    "bytesIn" to status.bytesIn,
                    "bytesOut" to status.bytesOut,
                    "duration" to status.duration,
                    "connectedAt" to status.connectedAt,
                    "errorMessage" to status.errorMessage
                ))
            }
        }
        
        override fun onServiceDisconnected(name: ComponentName?) {
            openVpnService = null
            isServiceBound.set(false)
        }
    }
    
    fun initialize() {
        // Set up event channel
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
        
        // Bind to VPN service
        val intent = Intent(context, OpenVpnService::class.java)
        context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
    }
    
    fun connect(config: String, username: String?, password: String?, serverName: String?) {
        if (isServiceBound.get()) {
            openVpnService?.connect(config, username, password, serverName)
        } else {
            // Start service if not bound
            val intent = Intent(context, OpenVpnService::class.java).apply {
                putExtra("config", config)
                putExtra("username", username)
                putExtra("password", password)
                putExtra("serverName", serverName)
                action = "CONNECT"
            }
            context.startForegroundService(intent)
        }
    }
    
    fun disconnect() {
        openVpnService?.disconnect()
    }
    
    fun getConnectionStats(): Map<String, Any>? {
        return openVpnService?.getConnectionStats()
    }
    
    fun dispose() {
        if (isServiceBound.get()) {
            context.unbindService(serviceConnection)
            isServiceBound.set(false)
        }
        eventSink = null
    }
}
