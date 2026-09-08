package com.hermit.integrations.http.bridge

import com.hermit.services.ChatServiceCore

internal class WebChatActionBridge(
    private val core: ChatServiceCore
) {
    fun manuallyUpdateMemory() {
        core.getMessageCoordinationDelegate().manuallyUpdateMemory()
    }

    fun manuallySummarizeConversation() {
        core.getMessageCoordinationDelegate().manuallySummarizeConversation()
    }
}
