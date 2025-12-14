package com.example.eira.model

data class BlockedAppData(
    val packageName: String,
    val appName: String,
    val limitMillis: Long,
    val startTime: Long,
    val isActive: Boolean
) {
    companion object {
        fun fromJson(json: Map<String, Any>): BlockedAppData {
            return BlockedAppData(
                packageName = json["packageName"] as String,
                appName = json["appName"] as String,
                limitMillis = (json["limitMillis"] as Number).toLong(),
                startTime = (json["startTime"] as Number).toLong(),
                isActive = json["isActive"] as? Boolean ?: true
            )
        }
    }
    
    fun toJson(): Map<String, Any> {
        return mapOf(
            "packageName" to packageName,
            "appName" to appName,
            "limitMillis" to limitMillis,
            "startTime" to startTime,
            "isActive" to isActive
        )
    }
}
