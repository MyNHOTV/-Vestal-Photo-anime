package com.ai.anime.art.generator.photo.create.aiart

import android.content.Context
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.LayoutInflater
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class GenericNativeAdFactory(private val context: Context, private val layoutId: Int) : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val adView = LayoutInflater.from(context).inflate(layoutId, null) as NativeAdView

        // Headline
        adView.headlineView = adView.findViewById(R.id.native_ad_headline)
        (adView.headlineView as? TextView)?.text = nativeAd.headline

        // Body
        adView.bodyView = adView.findViewById(R.id.native_ad_body)
        if (nativeAd.body == null) {
            adView.bodyView?.visibility = TextView.GONE
        } else {
            adView.bodyView?.visibility = TextView.VISIBLE
            (adView.bodyView as? TextView)?.text = nativeAd.body
        }

        // Call to Action
        adView.callToActionView = adView.findViewById(R.id.native_ad_button)
        if (nativeAd.callToAction == null) {
            adView.callToActionView?.visibility = Button.GONE
        } else {
            adView.callToActionView?.visibility = Button.VISIBLE
            (adView.callToActionView as? Button)?.text = nativeAd.callToAction
        }

        // Icon
        adView.iconView = adView.findViewById(R.id.native_ad_icon)
        if (nativeAd.icon == null) {
            adView.iconView?.visibility = ImageView.GONE
        } else {
            adView.iconView?.visibility = ImageView.VISIBLE
            (adView.iconView as? ImageView)?.setImageDrawable(nativeAd.icon?.drawable)
        }

        // Media
        adView.mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        nativeAd.mediaContent?.let {
            adView.mediaView?.setMediaContent(it)
        }

        // Advertiser
        adView.advertiserView = adView.findViewById(R.id.ad_advertiser)
        if (nativeAd.advertiser == null) {
            adView.advertiserView?.visibility = TextView.GONE
        } else {
            adView.advertiserView?.visibility = TextView.VISIBLE
            (adView.advertiserView as? TextView)?.text = nativeAd.advertiser
        }

        // Stars
        adView.starRatingView = adView.findViewById(R.id.ad_stars)
        if (nativeAd.starRating == null) {
            adView.starRatingView?.visibility = RatingBar.GONE
        } else {
            adView.starRatingView?.visibility = RatingBar.VISIBLE
            (adView.starRatingView as? RatingBar)?.rating = nativeAd.starRating!!.toFloat()
        }

        // Apply custom colors from customOptions
        customOptions?.let { options ->
            // Apply button color
            options["buttonColor"]?.let { colorValue ->
                val button = adView.findViewById<Button>(R.id.native_ad_button)
                button?.let {
                    val colorInt = (colorValue as? Number)?.toInt() ?: return@let
                    val drawable = GradientDrawable().apply {
                        setColor(colorInt)
                        cornerRadius = TypedValue.applyDimension(
                            TypedValue.COMPLEX_UNIT_DIP,
                            12f,
                            context.resources.displayMetrics
                        )
                    }
                    it.background = drawable
                }
            }
        }

        adView.setNativeAd(nativeAd)

        return adView
    }
}
