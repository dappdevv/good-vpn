package com.example.fl_openvpn_client

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Binder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.DatagramChannel
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong

data class VpnStatus(
    val state: String,
    val message: String? = null,
    val serverIp: String? = null,
    val localIp: String? = null,
    val bytesIn: Long? = null,
    val bytesOut: Long? = null,
    val duration: Long? = null,
    val connectedAt: Long? = null,
    val errorMessage: String? = null
)

class OpenVpnService : VpnService() {
    companion object {
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "vpn_channel"
        private const val TAG = "OpenVpnService"
    }

    private val binder = LocalBinder()
    private var vpnInterface: ParcelFileDescriptor? = null
    private var isConnected = AtomicBoolean(false)
    private var statusListener: ((VpnStatus) -> Unit)? = null
    private val bytesIn = AtomicLong(0)
    private val bytesOut = AtomicLong(0)
    private var connectedAt: Long = 0
    private var currentServerIp: String? = null

    // Native OpenVPN client
    private val openVpnNative = OpenVpnNative()
    private var isNativeLibraryAvailable = false

    // Main thread handler for UI updates
    private val mainHandler = Handler(Looper.getMainLooper())
    
    inner class LocalBinder : Binder() {
        fun getService(): OpenVpnService = this@OpenVpnService
    }
    
    override fun onBind(intent: Intent?): IBinder {
        return binder
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        initializeNativeLibrary()
    }

    private fun initializeNativeLibrary() {
        try {
            isNativeLibraryAvailable = openVpnNative.isNativeLibraryAvailable()

            if (isNativeLibraryAvailable) {
                openVpnNative.setStatusCallback(object : OpenVpnNative.StatusCallback {
                    override fun onStatusUpdate(status: String, message: String) {
                        Log.d(TAG, "Native status update: $status - $message")
                        handleNativeStatusUpdate(status, message)
                    }
                })
                Log.i(TAG, "Native OpenVPN library initialized successfully")
            } else {
                Log.w(TAG, "Native OpenVPN library not available, using fallback implementation")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize native OpenVPN library", e)
            isNativeLibraryAvailable = false
        }
    }

    private fun handleNativeStatusUpdate(status: String, message: String) {
        // Post to main thread to avoid threading issues with Flutter
        mainHandler.post {
            val vpnStatus = when (status) {
                "connecting" -> VpnStatus(
                    state = "connecting",
                    message = message
                )
                "authenticating" -> VpnStatus(
                    state = "authenticating",
                    message = message
                )
                "connected" -> {
                    isConnected.set(true)
                    connectedAt = System.currentTimeMillis()
                    VpnStatus(
                        state = "connected",
                        message = message,
                        serverIp = currentServerIp,
                        localIp = "10.8.0.2",
                        connectedAt = connectedAt
                    )
                }
                "disconnected" -> {
                    isConnected.set(false)
                    connectedAt = 0
                    bytesIn.set(0)
                    bytesOut.set(0)
                    VpnStatus(
                        state = "disconnected",
                        message = message
                    )
                }
                "error" -> VpnStatus(
                    state = "error",
                    errorMessage = message
                )
                else -> VpnStatus(
                    state = "disconnected",
                    message = message
                )
            }

            statusListener?.invoke(vpnStatus)

            // Update notification
            if (isConnected.get()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(NOTIFICATION_ID, createNotification("Connected", message), ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
                } else {
                    startForeground(NOTIFICATION_ID, createNotification("Connected", message))
                }
            }
        }
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "CONNECT" -> {
                val config = intent.getStringExtra("config")
                val username = intent.getStringExtra("username")
                val password = intent.getStringExtra("password")
                val serverName = intent.getStringExtra("serverName")
                
                if (config != null) {
                    connect(config, username, password, serverName)
                }
            }
            "DISCONNECT" -> {
                disconnect()
            }
        }
        
        return START_STICKY
    }
    
    fun setStatusListener(listener: (VpnStatus) -> Unit) {
        statusListener = listener
    }
    
    fun connect(config: String, username: String?, password: String?, serverName: String?) {
        if (isConnected.get()) {
            updateStatus("error", "Already connected")
            return
        }

        try {
            updateStatus("connecting", "Establishing VPN connection...")

            // Parse basic config info
            val serverInfo = parseServerInfo(config)
            currentServerIp = serverInfo.first
            val port = serverInfo.second

            // Try to use native OpenVPN library first
            if (isNativeLibraryAvailable) {
                Log.i(TAG, "Using native OpenVPN library")

                // Create VPN interface for native library
                val builder = Builder()
                    .setSession(serverName ?: "OpenVPN")
                    .addAddress("10.8.0.2", 24)
                    .addDnsServer("8.8.8.8")
                    .addDnsServer("8.8.4.4")
                    .addRoute("0.0.0.0", 0)
                    .setMtu(1500)

                vpnInterface = builder.establish()

                if (vpnInterface != null) {
                    // Use native OpenVPN client
                    val success = openVpnNative.connectToVpn(config, username, password)
                    if (!success) {
                        updateStatus("error", "Native OpenVPN connection failed")
                        vpnInterface?.close()
                        vpnInterface = null
                    }
                } else {
                    updateStatus("error", "Failed to establish VPN interface")
                }
            } else {
                Log.i(TAG, "Using fallback VPN implementation")
                // Fallback to simulation
                connectWithSimulation(config, username, password, serverName)
            }

        } catch (e: Exception) {
            Log.e(TAG, "Connection failed", e)
            updateStatus("error", "Connection failed: ${e.message}")
        }
    }

    private fun connectWithSimulation(config: String, username: String?, password: String?, serverName: String?) {
        // Original simulation code
        val serverInfo = parseServerInfo(config)
        currentServerIp = serverInfo.first

        val builder = Builder()
            .setSession(serverName ?: "OpenVPN")
            .addAddress("10.8.0.2", 24)
            .addDnsServer("8.8.8.8")
            .addDnsServer("8.8.4.4")
            .addRoute("0.0.0.0", 0)
            .setMtu(1500)

        vpnInterface = builder.establish()

        if (vpnInterface != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, createNotification("Connected", serverName), ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            } else {
                startForeground(NOTIFICATION_ID, createNotification("Connected", serverName))
            }
            isConnected.set(true)
            connectedAt = System.currentTimeMillis()

            updateStatus("connected", "Connected to VPN", currentServerIp, "10.8.0.2")
            startPacketForwarding()
        } else {
            updateStatus("error", "Failed to establish VPN interface")
        }
    }
    
    fun disconnect() {
        if (!isConnected.get()) {
            return
        }

        updateStatus("disconnecting", "Disconnecting...")

        try {
            // Disconnect native OpenVPN if available
            if (isNativeLibraryAvailable) {
                openVpnNative.disconnectFromVpn()
            }

            vpnInterface?.close()
            vpnInterface = null
            isConnected.set(false)
            connectedAt = 0
            currentServerIp = null
            bytesIn.set(0)
            bytesOut.set(0)

            stopForeground(true)
            updateStatus("disconnected", "Disconnected")

        } catch (e: Exception) {
            Log.e(TAG, "Disconnect failed", e)
            updateStatus("error", "Disconnect failed: ${e.message}")
        }
    }
    
    fun getConnectionStats(): Map<String, Any>? {
        if (!isConnected.get()) return null

        // Try to get stats from native library first
        if (isNativeLibraryAvailable) {
            val nativeStats = openVpnNative.getConnectionStats()
            if (nativeStats != null) {
                return nativeStats
            }
        }

        // Fallback to local stats
        val duration = if (connectedAt > 0) {
            (System.currentTimeMillis() - connectedAt) / 1000
        } else 0

        return mapOf(
            "bytesIn" to bytesIn.get(),
            "bytesOut" to bytesOut.get(),
            "duration" to duration,
            "serverIp" to (currentServerIp ?: ""),
            "localIp" to "10.8.0.2"
        )
    }
    
    private fun parseServerInfo(config: String): Pair<String, Int> {
        // Simple parser for demo - extract server and port from config
        val lines = config.split("\n")
        for (line in lines) {
            if (line.trim().startsWith("remote ")) {
                val parts = line.trim().split(" ")
                if (parts.size >= 3) {
                    val server = parts[1]
                    val port = parts[2].toIntOrNull() ?: 1194
                    return Pair(server, port)
                }
            }
        }
        return Pair("unknown", 1194)
    }
    
    private fun startPacketForwarding() {
        // Simplified packet forwarding for demo
        Thread {
            try {
                val vpnInput = FileInputStream(vpnInterface!!.fileDescriptor)
                val vpnOutput = FileOutputStream(vpnInterface!!.fileDescriptor)
                val buffer = ByteArray(32767)
                
                while (isConnected.get()) {
                    val length = vpnInput.read(buffer)
                    if (length > 0) {
                        // In a real implementation, this would forward packets to the VPN server
                        // For demo, we just simulate some traffic
                        bytesOut.addAndGet(length.toLong())
                        
                        // Echo back (simplified)
                        vpnOutput.write(buffer, 0, length)
                        bytesIn.addAndGet(length.toLong())
                    }
                    Thread.sleep(10)
                }
            } catch (e: Exception) {
                if (isConnected.get()) {
                    updateStatus("error", "Packet forwarding error: ${e.message}")
                }
            }
        }.start()
    }
    
    private fun updateStatus(
        state: String, 
        message: String? = null, 
        serverIp: String? = null, 
        localIp: String? = null
    ) {
        val status = VpnStatus(
            state = state,
            message = message,
            serverIp = serverIp ?: currentServerIp,
            localIp = localIp,
            bytesIn = if (isConnected.get()) bytesIn.get() else null,
            bytesOut = if (isConnected.get()) bytesOut.get() else null,
            duration = if (connectedAt > 0) (System.currentTimeMillis() - connectedAt) / 1000 else null,
            connectedAt = if (connectedAt > 0) connectedAt else null
        )
        
        statusListener?.invoke(status)
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "VPN Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "OpenVPN connection status"
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(title: String, content: String?): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content ?: "OpenVPN Client")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
    
    override fun onDestroy() {
        disconnect()

        // Cleanup native library
        if (isNativeLibraryAvailable) {
            try {
                openVpnNative.release()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to cleanup native library", e)
            }
        }

        super.onDestroy()
    }
}
