package com.venered.social.utils

import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime

object DateTimeFormatter {
    fun formatRelativeTime(instant: Instant?): String {
        if (instant == null) return "hace poco"

        val now = Instant.DISTANT_FUTURE
        val difference = kotlin.math.abs((now.toEpochMilliseconds() - instant.toEpochMilliseconds()) / 1000)

        return when {
            difference < 60 -> "hace un momento"
            difference < 3600 -> "hace ${difference / 60} minutos"
            difference < 86400 -> "hace ${difference / 3600} horas"
            difference < 604800 -> "hace ${difference / 86400} días"
            else -> instant.toLocalDateTime(TimeZone.currentSystemDefault()).date.toString()
        }
    }

    fun formatDate(instant: Instant?): String {
        if (instant == null) return ""
        return instant.toLocalDateTime(TimeZone.currentSystemDefault()).toString()
    }
}

object ImageUtils {
    fun webSafeUrl(url: String?): String {
        if (url == null || url.isEmpty()) return ""
        
        return when {
            url.startsWith("https://i.ibb.co") || 
            url.startsWith("https://cdn.telegram.org") -> {
                "https://images.weserv.nl/?url=${url.substringAfter("://")}"
            }
            else -> url
        }
    }
}

object ValidationUtils {
    fun isValidEmail(email: String): Boolean {
        val emailPattern = "[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}".toRegex()
        return emailPattern.matches(email)
    }

    fun isValidPassword(password: String): Boolean {
        return password.length >= 8
    }

    fun isValidUsername(username: String): Boolean {
        val usernamePattern = "^[a-zA-Z0-9_]{3,20}$".toRegex()
        return usernamePattern.matches(username)
    }
}

val ESTADOS_VENEZUELA = listOf(
    "Amazonas", "Anzoátegui", "Apure", "Aragua", "Barinas", "Bolívar",
    "Carabobo", "Cojedes", "Delta Amacuro", "Distrito Capital", "Falcón",
    "Guárico", "Lara", "Mérida", "Miranda", "Monagas", "Nueva Esparta",
    "Portuguesa", "Sucre", "Táchira", "Trujillo", "Vargas", "Yaracuy", "Zulia"
)
