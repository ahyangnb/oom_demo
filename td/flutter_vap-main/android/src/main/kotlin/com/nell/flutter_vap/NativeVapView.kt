package com.nell.flutter_vap

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import android.view.View
import com.tencent.qgame.animplayer.AnimConfig
import com.tencent.qgame.animplayer.AnimView
import com.tencent.qgame.animplayer.inter.IAnimListener
import com.tencent.qgame.animplayer.inter.IFetchResource
import com.tencent.qgame.animplayer.mix.Resource
import com.tencent.qgame.animplayer.util.ScaleType
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import okhttp3.Call
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.ResponseBody
import okio.IOException
import java.io.File


internal class NativeVapView(binaryMessenger: BinaryMessenger, context: Context, id: Int, creationParams: Map<String?, Any?>?) : MethodChannel.MethodCallHandler, PlatformView {
    private val mContext: Context = context

    private var vapView: AnimView? = null
    private val viewUse: android.widget.FrameLayout = android.widget.FrameLayout(context)
    private val channel: MethodChannel
    private var methodResult: MethodChannel.Result? = null

    private var vapInfo: Map<String?, String?>? = null
    private var fill: String = "1"
    init {
        var key = creationParams!!["key"];
        var res = "flutter_vap_controller_" + key
        channel = MethodChannel(binaryMessenger, res)
        channel.setMethodCallHandler(this)
    }

    override fun getView(): View {
        return viewUse
    }

    override fun dispose() {
        cleanupVapView()
        channel.setMethodCallHandler(null)
    }

    private fun cleanupVapView() {
        vapView?.let {
            it.stopPlay()
            it.setAnimListener(null)
            viewUse.removeView(it)
            vapView = null
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        methodResult = result
        when (call.method) {
            "playPath" -> {
                cleanupVapView()
                
                val vapInfoStr = call.argument<String>("vapInfo")
                if (vapInfoStr.isNullOrEmpty()) {
                    vapInfo = null
                } else {
                    vapInfo = Json.decodeFromString(vapInfoStr)
                }
                val fillStr = call.argument<String>("fill")
                if (fillStr.isNullOrEmpty()) {
                    fill = "1"
                }else{
                    fill = fillStr
                }
                call.argument<String>("path")?.let {
                    vapView = AnimView(mContext)
                    vapView?.layoutParams = android.widget.FrameLayout.LayoutParams(
                        android.widget.FrameLayout.LayoutParams.MATCH_PARENT,
                        android.widget.FrameLayout.LayoutParams.MATCH_PARENT
                    )
                    viewUse.addView(vapView)

                    setVapListener()
                    if (fill == "1") {
                        vapView?.setScaleType(ScaleType.CENTER_CROP)
                    } else {
                        vapView?.setScaleType(ScaleType.FIT_CENTER)
                    }
                    vapView?.startPlay(File(it))
                }
            }
            "playAsset" -> {
                cleanupVapView()
                
                val vapInfoStr = call.argument<String>("vapInfo")
                if (vapInfoStr.isNullOrEmpty()) {
                    vapInfo = null
                } else {
                    vapInfo = Json.decodeFromString(vapInfoStr)
                }
                val fillStr = call.argument<String>("fill")
                if (fillStr.isNullOrEmpty()) {
                    fill = "1"
                }else{
                    fill = fillStr
                }
                call.argument<String>("asset")?.let {
                    vapView = AnimView(mContext)
                    vapView?.layoutParams = android.widget.FrameLayout.LayoutParams(
                        android.widget.FrameLayout.LayoutParams.MATCH_PARENT,
                        android.widget.FrameLayout.LayoutParams.MATCH_PARENT
                    )
                    viewUse.addView(vapView)

                    setVapListener()
                    if (fill == "1") {
                        vapView?.setScaleType(ScaleType.CENTER_CROP)
                    } else {
                        vapView?.setScaleType(ScaleType.FIT_CENTER)
                    }
                    vapView?.startPlay(mContext.assets, "flutter_assets/$it")
                }
            }
            "stop" -> {
                cleanupVapView()
            }
        }
    }

    fun setVapListener() {
        if (vapView == null){
            return
        }
        vapView?.setAnimListener(object : IAnimListener {
            override fun onFailed(errorType: Int, errorMsg: String?) {
                try {
                    GlobalScope.launch(Dispatchers.Main) {
                        methodResult?.success(HashMap<String, String>().apply {
                            put("status", "failure")
                            put("errorMsg", errorMsg ?: "unknown error")
                        })
                        methodResult = null
                    }
                } catch (e: IllegalStateException) {

                }
            }

            override fun onVideoComplete() {
                try {
                    GlobalScope.launch(Dispatchers.Main) {
                        methodResult?.success(HashMap<String, String>().apply {
                            put("status", "complete")
                        })
                        methodResult = null
                    }
                } catch (e: IllegalStateException) {

                }
            }

            override fun onVideoDestroy() {
                /// 视频被销毁
                Log.d("Vap-dana", "onVideoDestroy")
            }

            override fun onVideoRender(frameIndex: Int, config: AnimConfig?) {
            }

            override fun onVideoStart() {
                /// 开始播放
                Log.d("Vap-dana", "onVideoStart")
            }

        })
        vapView?.setFetchResource(object : IFetchResource {
            override fun fetchImage(resource: Resource, result: (Bitmap?) -> Unit) {
                val srcTag = resource.tag
                if (vapInfo?.keys?.contains(srcTag) == true) {
                    val imgUrl = vapInfo!![srcTag]
                    val request: Request = Request.Builder().url(imgUrl!!).build()
                    val client: OkHttpClient = OkHttpClient.Builder().build()
                    val call: Call = client.newCall(request)
                    try {
                        val response: Response = call.execute()
                        val body: ResponseBody? = response.body
                        if (body != null) {
                            result(BitmapFactory.decodeStream(body.byteStream()))
                        } else {
                            result(null)
                        }
                    } catch (e: IOException) {
                        result(null)
                    }
                } else {
                    result(null)
                }
            }

            override fun fetchText(resource: Resource, result: (String?) -> Unit) {
                val srcTag = resource.tag
                if (vapInfo?.keys?.contains(srcTag) == true) {
                    result(vapInfo!![srcTag])
                } else {
                    result(null)
                }
            }

            override fun releaseResource(resources: List<Resource>) {
                resources.forEach {
                    it.bitmap?.recycle()
                }
            }
        });
    }

}