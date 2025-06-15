#include <jni.h>
#include <string>
#include <memory>
#include <android/log.h>
#include "openvpn_client.h"

#define LOG_TAG "OpenVPN_JNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static std::unique_ptr<OpenVPNClient> g_client;
static JavaVM* g_jvm = nullptr;
static jobject g_callback_obj = nullptr;

// JNI callback to Java
void statusCallback(const std::string& status, const std::string& message) {
    if (!g_jvm || !g_callback_obj) return;
    
    JNIEnv* env;
    if (g_jvm->GetEnv((void**)&env, JNI_VERSION_1_6) != JNI_OK) {
        if (g_jvm->AttachCurrentThread(&env, nullptr) != JNI_OK) {
            LOGE("Failed to attach thread");
            return;
        }
    }
    
    jclass cls = env->GetObjectClass(g_callback_obj);
    jmethodID method = env->GetMethodID(cls, "onStatusUpdate", "(Ljava/lang/String;Ljava/lang/String;)V");
    
    if (method) {
        jstring jstatus = env->NewStringUTF(status.c_str());
        jstring jmessage = env->NewStringUTF(message.c_str());
        env->CallVoidMethod(g_callback_obj, method, jstatus, jmessage);
        env->DeleteLocalRef(jstatus);
        env->DeleteLocalRef(jmessage);
    }
    
    env->DeleteLocalRef(cls);
}

extern "C" {

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void* reserved) {
    g_jvm = vm;
    return JNI_VERSION_1_6;
}

JNIEXPORT void JNICALL JNI_OnUnload(JavaVM* vm, void* reserved) {
    g_jvm = nullptr;
    if (g_callback_obj) {
        JNIEnv* env;
        if (vm->GetEnv((void**)&env, JNI_VERSION_1_6) == JNI_OK) {
            env->DeleteGlobalRef(g_callback_obj);
        }
        g_callback_obj = nullptr;
    }
}

JNIEXPORT void JNICALL
Java_com_example_fl_1openvpn_1client_OpenVpnNative_initialize(JNIEnv* env, jobject thiz, jobject callback) {
    LOGI("Initializing OpenVPN native client");
    
    // Store callback object
    if (g_callback_obj) {
        env->DeleteGlobalRef(g_callback_obj);
    }
    g_callback_obj = env->NewGlobalRef(callback);
    
    // Create OpenVPN client
    g_client = std::make_unique<OpenVPNClient>(statusCallback);
    
    LOGI("OpenVPN native client initialized");
}

JNIEXPORT jboolean JNICALL
Java_com_example_fl_1openvpn_1client_OpenVpnNative_connect(JNIEnv* env, jobject thiz, 
                                                           jstring config, jstring username, jstring password) {
    if (!g_client) {
        LOGE("OpenVPN client not initialized");
        return JNI_FALSE;
    }
    
    const char* config_str = env->GetStringUTFChars(config, nullptr);
    const char* username_str = username ? env->GetStringUTFChars(username, nullptr) : nullptr;
    const char* password_str = password ? env->GetStringUTFChars(password, nullptr) : nullptr;
    
    LOGI("Connecting to OpenVPN server");
    
    bool result = g_client->connect(
        std::string(config_str),
        username_str ? std::string(username_str) : "",
        password_str ? std::string(password_str) : ""
    );
    
    env->ReleaseStringUTFChars(config, config_str);
    if (username_str) env->ReleaseStringUTFChars(username, username_str);
    if (password_str) env->ReleaseStringUTFChars(password, password_str);
    
    return result ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT void JNICALL
Java_com_example_fl_1openvpn_1client_OpenVpnNative_disconnect(JNIEnv* env, jobject thiz) {
    if (g_client) {
        LOGI("Disconnecting from OpenVPN server");
        g_client->disconnect();
    }
}

JNIEXPORT jstring JNICALL
Java_com_example_fl_1openvpn_1client_OpenVpnNative_getStatus(JNIEnv* env, jobject thiz) {
    if (!g_client) {
        return env->NewStringUTF("disconnected");
    }
    
    std::string status = g_client->getStatus();
    return env->NewStringUTF(status.c_str());
}

JNIEXPORT jobject JNICALL
Java_com_example_fl_1openvpn_1client_OpenVpnNative_getStats(JNIEnv* env, jobject thiz) {
    if (!g_client) {
        return nullptr;
    }
    
    auto stats = g_client->getStats();
    
    // Create HashMap
    jclass hashMapClass = env->FindClass("java/util/HashMap");
    jmethodID hashMapInit = env->GetMethodID(hashMapClass, "<init>", "()V");
    jmethodID hashMapPut = env->GetMethodID(hashMapClass, "put", 
                                           "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");
    
    jobject hashMap = env->NewObject(hashMapClass, hashMapInit);
    
    // Add stats to HashMap
    jclass longClass = env->FindClass("java/lang/Long");
    jmethodID longInit = env->GetMethodID(longClass, "<init>", "(J)V");
    
    jobject bytesIn = env->NewObject(longClass, longInit, (jlong)stats.bytesIn);
    jobject bytesOut = env->NewObject(longClass, longInit, (jlong)stats.bytesOut);
    jobject duration = env->NewObject(longClass, longInit, (jlong)stats.duration);
    
    env->CallObjectMethod(hashMap, hashMapPut, env->NewStringUTF("bytesIn"), bytesIn);
    env->CallObjectMethod(hashMap, hashMapPut, env->NewStringUTF("bytesOut"), bytesOut);
    env->CallObjectMethod(hashMap, hashMapPut, env->NewStringUTF("duration"), duration);
    env->CallObjectMethod(hashMap, hashMapPut, env->NewStringUTF("serverIp"),
                         env->NewStringUTF(stats.serverIp.c_str()));
    env->CallObjectMethod(hashMap, hashMapPut, env->NewStringUTF("localIp"),
                         env->NewStringUTF(stats.localIp.c_str()));

    return hashMap;
}

JNIEXPORT void JNICALL
Java_com_example_fl_1openvpn_1client_OpenVpnNative_cleanup(JNIEnv* env, jobject thiz) {
    LOGI("Cleaning up OpenVPN native client");
    g_client.reset();
    
    if (g_callback_obj) {
        env->DeleteGlobalRef(g_callback_obj);
        g_callback_obj = nullptr;
    }
}

} // extern "C"
