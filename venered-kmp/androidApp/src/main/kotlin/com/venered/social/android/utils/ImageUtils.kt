package com.venered.social.android.utils

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import java.io.ByteArrayOutputStream

object ImageUtils {
    /**
     * Comprime una imagen desde una Uri a un ByteArray
     * @param quality Calidad de la compresión (0-100)
     * @param maxWidth Ancho máximo para redimensionar
     */
    fun compressImage(context: Context, uri: Uri, quality: Int = 80, maxWidth: Int = 1080): ByteArray? {
        return try {
            val inputStream = context.contentResolver.openInputStream(uri)
            val originalBitmap = BitmapFactory.decodeStream(inputStream)
            inputStream?.close()

            if (originalBitmap == null) return null

            // Redimensionar si es muy grande
            val ratio = originalBitmap.height.toFloat() / originalBitmap.width.toFloat()
            val targetWidth = if (originalBitmap.width > maxWidth) maxWidth else originalBitmap.width
            val targetHeight = (targetWidth * ratio).toInt()
            
            val scaledBitmap = Bitmap.createScaledBitmap(originalBitmap, targetWidth, targetHeight, true)
            
            val outputStream = ByteArrayOutputStream()
            scaledBitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
            val result = outputStream.toByteArray()
            
            outputStream.close()
            if (scaledBitmap != originalBitmap) {
                scaledBitmap.recycle()
            }
            originalBitmap.recycle()
            
            result
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
