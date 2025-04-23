# Keep OkHttp and its dependencies
-dontwarn org.bouncycastle.jsse.BCSSLParameters
-dontwarn org.bouncycastle.jsse.BCSSLSocket
-dontwarn org.bouncycastle.jsse.provider.BouncyCastleJsseProvider
-dontwarn org.conscrypt.Conscrypt$Version
-dontwarn org.conscrypt.Conscrypt
-dontwarn org.conscrypt.ConscryptHostnameVerifier
-dontwarn org.openjsse.javax.net.ssl.SSLParameters
-dontwarn org.openjsse.javax.net.ssl.SSLSocket
-dontwarn org.openjsse.net.ssl.OpenJSSE

# Keep OkHttp internal classes
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Keep SSL related classes
-keepclassmembers class * extends javax.net.ssl.SSLSocketFactory {
    private final javax.net.ssl.SSLContext sslContext;
}

# Keep Conscrypt classes if available
-if class org.conscrypt.Conscrypt
-keep class org.conscrypt.** { *; } 