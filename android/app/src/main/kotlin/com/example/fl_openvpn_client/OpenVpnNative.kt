package com.example.fl_openvpn_client

import android.util.Log

class OpenVpnNative {
    companion object {
        private const val TAG = "OpenVpnNative"
        private var isLibraryLoaded = false

        init {
            try {
                System.loadLibrary("openvpn_native")
                isLibraryLoaded = true
                Log.i(TAG, "OpenVPN native library loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                isLibraryLoaded = false
                Log.e(TAG, "Failed to load OpenVPN native library", e)
            }
        }
    }

    fun isNativeLibraryAvailable(): Boolean {
        return isLibraryLoaded
    }
    
    interface StatusCallback {
        fun onStatusUpdate(status: String, message: String)
    }
    
    // Native methods
    external fun initialize(callback: StatusCallback)
    external fun connect(config: String, username: String?, password: String?): Boolean
    external fun disconnect()
    external fun getStatus(): String
    external fun getStats(): Map<String, Any>?
    external fun cleanup()
    
    private var statusCallback: StatusCallback? = null
    
    fun setStatusCallback(callback: StatusCallback) {
        this.statusCallback = callback
        if (isLibraryLoaded) {
            try {
                initialize(callback)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize native callback", e)
            }
        } else {
            Log.w(TAG, "Native library not available, skipping callback initialization")
        }
    }
    
    fun connectToVpn(config: String, username: String? = null, password: String? = null): Boolean {
        if (!isLibraryLoaded) {
            Log.w(TAG, "Native library not available, cannot connect")
            return false
        }
        return try {
            connect(config, username, password)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to connect to VPN", e)
            false
        }
    }
    
    fun disconnectFromVpn() {
        if (!isLibraryLoaded) {
            Log.w(TAG, "Native library not available, cannot disconnect")
            return
        }
        try {
            disconnect()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to disconnect from VPN", e)
        }
    }
    
    fun getCurrentStatus(): String {
        if (!isLibraryLoaded) {
            return "unavailable"
        }
        return try {
            getStatus()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get VPN status", e)
            "error"
        }
    }
    
    fun getConnectionStats(): Map<String, Any>? {
        if (!isLibraryLoaded) {
            return null
        }
        return try {
            getStats()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get VPN stats", e)
            null
        }
    }
    
    fun release() {
        if (isLibraryLoaded) {
            try {
                cleanup()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to cleanup native resources", e)
            }
        }
        statusCallback = null
    }
}
