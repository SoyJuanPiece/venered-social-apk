package com.venered.social.data.repository

import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.client.request.forms.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive

class MediaRepository {
    private val client = HttpClient {
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                isLenient = true
            })
        }
    }
    
    private val imgbbApiKey = "c4fd2ded598485660696ba819347f0bb"
    private val telegramServerUrl = "http://toby.hidencloud.com:24652/upload"

    /**
     * Sube una imagen a ImgBB
     */
    suspend fun uploadImage(bytes: ByteArray, fileName: String): Result<String> = runCatching {
        val response = client.post("https://api.imgbb.com/1/upload") {
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
