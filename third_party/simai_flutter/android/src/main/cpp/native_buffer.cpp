#include <jni.h>

extern "C" JNIEXPORT jlong JNICALL
Java_dev_projectfukakai_simai_1flutter_SimaiFlutterPlugin_nativeBufferAddress(
    JNIEnv* env,
    jobject,
    jobject buffer) {
  return reinterpret_cast<jlong>(env->GetDirectBufferAddress(buffer));
}
