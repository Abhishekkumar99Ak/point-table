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

subprojects {
    afterEvaluate {
        val androidExtension = extensions.findByName("android") ?: return@afterEvaluate
        val compileSdkSetter = androidExtension.javaClass.methods.firstOrNull { method ->
            method.name in setOf("compileSdkVersion", "setCompileSdkVersion", "setCompileSdk") &&
                method.parameterCount == 1
        }
        if (compileSdkSetter != null) {
            val sdkValue = if (compileSdkSetter.parameterTypes[0] == String::class.java) "36" else 36
            compileSdkSetter.invoke(androidExtension, sdkValue)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
