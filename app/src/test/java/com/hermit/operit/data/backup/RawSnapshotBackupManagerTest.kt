package com.hermit.data.backup

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RawSnapshotBackupManagerTest {

    @Test
    fun snapshotPackageName_acceptsOperitPackagePrefix() {
        assertTrue(isSupportedSnapshotPackageName("com.hermit"))
        assertTrue(isSupportedSnapshotPackageName("com.hermit.debug"))
        assertTrue(isSupportedSnapshotPackageName("com.hermit.clone"))
    }

    @Test
    fun snapshotPackageName_rejectsDifferentPackagePrefix() {
        assertFalse(isSupportedSnapshotPackageName("com.ai.assistance.other"))
        assertFalse(isSupportedSnapshotPackageName("com.example.operit"))
    }
}
