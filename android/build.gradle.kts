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
    afterEvaluate {
        if (project.hasProperty("android")) {
            try {
                val namespaceField = project.extensions
                    .getByName("android")
                    .javaClass
                    .getMethod("getNamespace")
                    .invoke(project.extensions.getByName("android")) as? String
                if (namespaceField == null || namespaceField.isEmpty()) {
                    val nsResolver = project.extensions
                        .getByName("android")
                        .javaClass
                        .getMethod("setNamespace", String::class.java)
                    nsResolver.invoke(
                        project.extensions.getByName("android"),
                        "com.hermex.android.${project.name.replace("-", "_")}"
                    )
                }
            } catch (_: Exception) {
                // Module not an Android module — skip
            }
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Disable resource verification for isar_flutter_libs (lStar AGP 8.11+ compat)
gradle.projectsEvaluated {
    subprojects {
        if (name == "isar_flutter_libs") {
            tasks.matching { it.name.contains("verifyReleaseResources") }.configureEach {
                enabled = false
            }
        }
    }
}
