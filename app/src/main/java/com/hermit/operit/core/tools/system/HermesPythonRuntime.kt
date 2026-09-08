package com.hermit.core.tools.system

import android.content.Context
import com.hermit.util.AppLogger
import java.io.File

/**
 * Resolves the bundled Hermes Python process inside the AArch64 PRoot userspace.
 *
 * The runtime is deliberately separate from the Android terminal session so the
 * Agent receives a stable Linux root and a reproducible Python interpreter.
 */
class HermesPythonRuntime(context: Context) {
    private val applicationContext = context.applicationContext

    companion object {
        private const val TAG = "HermesPythonRuntime"
        private const val ROOTFS_RELATIVE_PATH =
            "usr/var/lib/proot-distro/installed-rootfs/ubuntu"
        private const val PROOT_RELATIVE_PATH = "usr/bin/proot"
        private const val PYTHON_PATH = "/usr/bin/python3"
        private const val AGENT_PATH = "/opt/hermes-agent"
    }

    data class Layout(
        val rootfs: File,
        val proot: File,
        val agent: File
    )

    fun layout(): Layout {
        val filesDir = applicationContext.filesDir
        return Layout(
            rootfs = File(filesDir, ROOTFS_RELATIVE_PATH),
            proot = File(filesDir, PROOT_RELATIVE_PATH),
            agent = File(filesDir, "$ROOTFS_RELATIVE_PATH/opt/hermes-agent")
        )
    }

    fun requireLayout(): Layout {
        val resolved = layout()
        require(resolved.rootfs.isDirectory) {
            "Hermes Ubuntu AArch64 rootfs is not installed: ${resolved.rootfs}"
        }
        require(resolved.proot.isFile && resolved.proot.canExecute()) {
            "Hermes PRoot executable is not installed: ${resolved.proot}"
        }
        require(resolved.agent.isDirectory) {
            "Hermes Agent bundle is not installed: ${resolved.agent}"
        }
        return resolved
    }

    fun command(arguments: List<String>): List<String> {
        val resolved = requireLayout()
        val command = buildList {
            add(resolved.proot.absolutePath)
            add("--link2symlink")
            add("-0")
            add("-r")
            add(resolved.rootfs.absolutePath)
            add(PYTHON_PATH)
            add("$AGENT_PATH/run_agent.py")
            addAll(arguments)
        }
        AppLogger.d(TAG, "Prepared local Hermes Agent command for ${resolved.rootfs}")
        return command
    }
}
