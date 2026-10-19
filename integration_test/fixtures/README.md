# Face input fixture

`face.jpg` is the Grace Hopper example image distributed by TensorFlow:
https://storage.googleapis.com/download.tensorflow.org/example_images/grace_hopper.jpg

Used only to exercise single-face capture validation and the scan/save workflow.
It is not a labelled acne dataset and no acne-accuracy claim is made from it.
The Android integration test replaces the OS chooser with this fixture; face
validation, TFLite inference, Firebase emulator login and local storage are real.
