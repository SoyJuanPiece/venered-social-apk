package com.venered.social.data.repository

import com.venered.social.data.network.SupabaseClient
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.client.request.forms.*
import io.ktor.http.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive

class MediaRepository {
    private val client = SupabaseClient.httpClient
    private val imgbbApiKey = "c4fd2ded598485660696ba819347f0bb"
    private val telegramServerUrl = "http://toby.hidencloud.com:24652/upload"

    /**
     * Sube una imagen a ImgBB
     */
    suspend fun uploadImage(bytes: ByteArray, fileName: String): Result<String> = runCatching {
        // Necesitamos un cliente limpio para no enviar las cabeceras de Supabase
        val response = client.post("https://api.imgbb.com/1/upload") {
            // Limpiamos cabeceras por defecto
            headers.remove("apikey")
            headers.remove("Authorization")
            
            parameter("key", imgbbApiKey)
            setBody(MultiPartFormDataContent(
                formData {
                    append("image", bytes, Headers.build {
                        append(HttpHeaders.ContentDisposition, "filename=\"$fileName\"")
                    })
                }
            ))
        }

        if (response.status == HttpStatusCode.OK) {
            val body = response.body<ImgBBResponse>()
            body.data.url
        } else {
            throw Exception("Error ImgBB: ${response.status}")
        }
    }

    /**
     * Sube un video o media pesada al backend de Telegram
     */
    suspend fun uploadToTelegram(bytes: ByteArray, fileName: String, isStory: Boolean = false): Result<String> = runCatching {
        val response = client.post(telegramServerUrl) {
            headers.remove("apikey")
            headers.remove("Authorization")
            
            setBody(MultiPartFormDataContent(
                formData {
                    append("media", bytes, Headers.build {
                        append(HttpHeaders.ContentDisposition, "filename=\"$fileName\"")
                        val ext = fileName.split(".").last().lowercase()
                        val contentType = when(ext) {
                            "mp4" -> "video/mp4"
                            "jpg", "jpeg" -> "image/jpeg"
                            "png" -> "image/png"
                            else -> "application/octet-stream"
                        }
                        append(HttpHeaders.ContentType, contentType)
                    })
                    append("isStory", isStory.toString())
                }
            ))
        }

        if (response.status == HttpStatusCode.OK) {
            val body = response.body<JsonObject>()
            body["media_url"]?.jsonPrimitive?.content 
                ?: body["url"]?.jsonPrimitive?.content 
                ?: body["file_id"]?.jsonPrimitive?.content 
                ?: throw Exception("Respuesta de Telegram sin URL")
        } else {
            throw Exception("Error Telegram: ${response.status}")
        }
    }
}

@Serializable
data class ImgBBResponse(
    val data: ImgBBData,
    val success: Boolean,
    val status: Int
)

@Serializable
data class ImgBBData(
    val url: String,
    val display_url: String
)
