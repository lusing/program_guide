package guide.android.examples

import android.app.Activity
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle

class Example17LocationManager : Activity() {
    private var locationManager: LocationManager? = null
    private val listener = LocationListener { _: Location -> }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        locationManager?.requestLocationUpdates(LocationManager.GPS_PROVIDER, 1000L, 1.0f, listener)
    }

    override fun onDestroy() {
        super.onDestroy()
        locationManager?.removeUpdates(listener)
    }
}

