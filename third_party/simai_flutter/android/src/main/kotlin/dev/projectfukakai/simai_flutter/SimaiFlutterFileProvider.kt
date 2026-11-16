package dev.projectfukakai.simai_flutter

import androidx.core.content.FileProvider

/**
 * Plugin-specific provider class so this manifest entry does not merge with
 * FileProvider declarations from the host application or other plugins.
 */
class SimaiFlutterFileProvider : FileProvider()
