package guide.android.examples

import android.app.Activity
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.media.SoundPool
import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.LinearLayout
import android.widget.MediaController
import android.widget.VideoView
import java.io.File

// ---- 16 章第 2 节：MediaPlayer 状态机 + 音频焦点 ----

class Example25MediaPlayer : Activity() {
    private var player: MediaPlayer? = null
    private lateinit var audioManager: AudioManager
    private var focusRequest: AudioFocusRequest? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 64, 32, 32)
        }
        root.addView(Button(this).apply {
            text = "播放（申请焦点 + 异步准备）"
            setOnClickListener { playWithFocus() }
        })
        root.addView(Button(this).apply {
            text = "暂停 / 恢复"
            setOnClickListener {
                player?.let { if (it.isPlaying) it.pause() else it.start() }
            }
        })
        root.addView(Button(this).apply {
            text = "停止"
            setOnClickListener { stopPlayback() }
        })
        setContentView(root)
    }

    private fun playWithFocus() {
        // 音频焦点：独占资源的礼貌协议
        focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build())
            .setOnAudioFocusChangeListener { change ->
                when (change) {
                    AudioManager.AUDIOFOCUS_LOSS -> stopPlayback()        // 永久丢失
                    AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> player?.pause()
                    AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK ->
                        player?.setVolume(0.2f, 0.2f)                     // 闪避
                    AudioManager.AUDIOFOCUS_GAIN -> player?.start()       // 归还
                }
            }
            .build()
        audioManager.requestAudioFocus(focusRequest!!)

        player?.release()                          // 换曲先放生
        player = MediaPlayer().apply {
            setDataSource("/sdcard/music.mp3")     // 示例路径：真机上换成实际文件
            setOnPreparedListener { mp -> mp.start() }        // 异步准备完成才能 start
            setOnCompletionListener { stopPlayback() }
            setOnErrorListener { _, what, extra ->
                Log.e("Media", "error what=$what extra=$extra"); true
            }
            prepareAsync()
        }
    }

    private fun stopPlayback() {
        player?.release()
        player = null
        focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
        focusRequest = null
    }

    override fun onDestroy() {
        stopPlayback()                              // 最后期限
        super.onDestroy()
    }
}

// ---- 16 章第 3 节：SoundPool 短音效池 ----

class Example25SoundPool : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val loaded = mutableSetOf<Int>()
        val pool = SoundPool.Builder()
            .setMaxStreams(4)
            .setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA).build())
            .build()
        pool.setOnLoadCompleteListener { _, sampleId, status ->
            if (status == 0) loaded += sampleId    // 加载是异步的
        }
        val clickId = pool.load("/sdcard/click.ogg", 1)   // priority 现状无效，恒传 1

        setContentView(Button(this).apply {
            text = "点一下响一下（loop=0, rate=1f）"
            setOnClickListener {
                if (clickId in loaded) {
                    pool.play(clickId, 1f, 1f, 1, 0, 1f)
                }
            }
        })
    }
}

// ---- 16 章第 4 节：VideoView + MediaController ----

class Example25VideoView : Activity() {
    private var video: VideoView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        video = VideoView(this).apply {
            setVideoPath("/sdcard/movie.mp4")
            setMediaController(MediaController(this@Example25VideoView))  // 控制条白送
            setOnCompletionListener { Log.d("Video", "done") }
        }
        setContentView(video)
        video?.start()
    }

    override fun onDestroy() {
        video?.stopPlayback()
        super.onDestroy()
    }
}

// ---- 16 章第 5 节：MediaRecorder 录音八步（顺序铁律）----

class Example25Recorder : Activity() {
    private var recorder: MediaRecorder? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val outFile = File(getExternalFilesDir(null), "note.m4a")

        val start = Button(this).apply { text = "开始录音（需 RECORD_AUDIO 运行时权限）" }
        val stop = Button(this).apply { text = "停止并保存" }
        start.setOnClickListener {
            recorder = MediaRecorder(this@Example25Recorder).apply {   // API 31 起须传 Context
                setAudioSource(MediaRecorder.AudioSource.MIC)        // ① 声源
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)   // ② 容器
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)      // ③ 编码器（必须在②后）
                setOutputFile(outFile.absolutePath)                  // ④ 落盘
                prepare()                                            // ⑤
                start()                                              // ⑥
            }
        }
        stop.setOnClickListener {
            recorder?.stop()                                         // ⑦
            recorder?.release()                                      // ⑧：漏了麦克风灯常亮
            recorder = null
            Log.d("Recorder", "saved ${outFile.absolutePath}")
        }
        setContentView(LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 64, 32, 32)
            addView(start)
            addView(stop)
        })
    }

    override fun onDestroy() {
        recorder?.release()
        recorder = null
        super.onDestroy()
    }
}

// ---- 16 章第 6 节：Camera2 骨架（打开设备 + 特性表）----

class Example25Camera2 : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val manager = getSystemService(Context.CAMERA_SERVICE) as android.hardware.camera2.CameraManager
        // 特性表：朝向、能力。开相机是异步回调（完整预览/拍照见书 11.3.1 流程）
        manager.cameraIdList.forEach { id ->
            val chars = manager.getCameraCharacteristics(id)
            val facing = chars.get(android.hardware.camera2.CameraCharacteristics.LENS_FACING)
            Log.d("Camera2", "camera $id facing=$facing" +
                "（LENS_FACING_BACK=${android.hardware.camera2.CameraCharacteristics.LENS_FACING_BACK}）")
        }
        // 真正 openCamera 需 CAMERA 运行时权限 + 合适的 HandlerThread 收回调
        setContentView(android.widget.TextView(this).apply { text = "看 logcat：Camera2" })
    }
}
