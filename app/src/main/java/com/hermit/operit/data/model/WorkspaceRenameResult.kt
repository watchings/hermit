package com.hermit.data.model

data class WorkspaceRenameResult(
    val workspacePath: String,
    val workspaceEnv: String?,
    val workspaceName: String
)
