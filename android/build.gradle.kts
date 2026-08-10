allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// record 4.4.4 declares package="com.llfbandit.record" in its own
// AndroidManifest.xml. AGP 8 refuses that outright — :record:processDebugManifest
// fails and no APK is produced, so Android cannot build at all. The attribute
// lives inside the published plugin, so there is nothing to change app-side
// except this.
//
// Two halves: strip the attribute from the manifest, and set the namespace it
// used to provide. The namespace must be com.llfbandit.record specifically —
// the generic fallback below would assign com.example.fallback.record and the
// plugin's own R class references would stop resolving.
//
// iOS ships on record 4.4.4, so upgrading is not an option; 5.x also has its
// own broken record_linux. Remove this once the dependency can move.
subprojects {
    if (name == "record") {
        val manifest = file("src/main/AndroidManifest.xml")
        if (manifest.exists()) {
            val text = manifest.readText()
            val packageAttr = Regex("""\s+package\s*=\s*"[^"]*"""")
            if (packageAttr.containsMatchIn(text)) {
                manifest.writeText(packageAttr.replace(text, ""))
                logger.lifecycle("Stripped package= from record's AndroidManifest (AGP 8 compatibility)")
            }
        }
        afterEvaluate {
            val android = extensions.findByName("android")
            if (android != null) {
                try {
                    android.javaClass
                        .getMethod("setNamespace", String::class.java)
                        .invoke(android, "com.llfbandit.record")
                } catch (e: Exception) {
                    logger.warn("Could not set record namespace: ${e.message}")
                }
            }
        }
    }
}

// Fix for older plugins that don't specify a namespace (required by AGP 8.0+)
subprojects {
    val setupNamespace = { proj: Project ->
        val android = proj.extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                if (getNamespace.invoke(android) == null) {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    val fallbackNamespace = "com.example.fallback.${proj.name.replace("-", "_")}"
                    setNamespace.invoke(android, fallbackNamespace)
                }
            } catch (e: Exception) {
                // Ignore
            }
        }
    }

    if (project.state.executed) {
        setupNamespace(project)
    } else {
        project.afterEvaluate { setupNamespace(this) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
