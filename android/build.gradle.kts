allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// [중요] Flutter CLI가 전달하는 빌드 경로(flutter-build-dir)를 우선적으로 사용하도록 설정
// 이 설정이 없으면 Flutter 도구가 구동될 때 APK 파일을 엉뚱한 곳에서 찾게 됩니다.
val flutterBuildDir = project.findProperty("flutter-build-dir") as String?
val newBuildDir: Directory = if (flutterBuildDir != null) {
    layout.projectDirectory.dir(flutterBuildDir)
} else {
    // Flutter 프로젝트 루트(../)의 build 디렉토리를 사용
    rootProject.layout.projectDirectory.dir("../build")
}

rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
