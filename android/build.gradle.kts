allprojects {
    repositories {
        google()
        mavenCentral()
    }

}


val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)





subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.LibraryExtension
            if (android.namespace.isNullOrEmpty()) {
                val manifest = project.file("src/main/AndroidManifest.xml")
                if (manifest.exists()) {
                    val pkg = Regex("""package\s*=\s*"([^"]+)"""").find(manifest.readText())?.groupValues?.get(1)
                    if (!pkg.isNullOrEmpty()) {
                        android.namespace = pkg
                    }
                }
            }
            android.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "17"
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
