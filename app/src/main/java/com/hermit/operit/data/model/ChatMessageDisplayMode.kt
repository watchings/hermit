package com.hermit.data.model

import kotlinx.serialization.Serializable

@Serializable
enum class ChatMessageDisplayMode {
    NORMAL,
    HIDDEN_PLACEHOLDER
}
