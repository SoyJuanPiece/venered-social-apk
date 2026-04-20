package com.venered.social.data.network

import io.ktor.client.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json

object SupabaseClient {
    private const val SUPABASE_URL = "https://ywbqkzvsqgyxgmguxwam.supabase.co"
    private const val SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3YnFrenZzcWd5eGdtZ3V4d2FtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1OTE1NTcsImV4cCI6MjA4ODE2NzU1N30.5JaEK5jA4c_p1bM_LEI36FQvfMcDI9NuR-Xj8wAY1ZA"

    val httpClient = HttpClient {
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                isLenient = true
            })
        }

        install(io.ktor.client.plugins.logging.Logging) {
            level = io.ktor.client.plugins.logging.LogLevel.ALL
        }

        defaultRequest {
            header("apikey", SUPABASE_KEY)
            header("Authorization", "Bearer $SUPABASE_KEY")
        }
    }

    fun getUrl() = SUPABASE_URL
    fun getKey() = SUPABASE_KEY
}

// Extensiones útiles para URLs
fun getSupabaseUrl(path: String): String {
    return "${SupabaseClient.getUrl()}$path"
}
