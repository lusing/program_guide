package guide.android.examples

object Example21JniBridge {
    init {
        System.loadLibrary("guide_native")
    }

    external fun stringFromJNI(): String
}

