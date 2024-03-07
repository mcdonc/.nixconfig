- input transcoding: h264 with PCM audio for studio version, av1 with PCM audio
  for free version.  Matroska container works fine for both.

- preferences / user / UI settings / UI display scale
  
- audio normalization for youtube on render / audio page 

- mkv / h.264 / mp3: all my systems can gpu-accelerate h.264 rendering, mp3 for
  smallest file size; youtube seems to cope fine, although ymmv, i don't use
  stereo audio, for example.

- CUDA GPU allows for accelerated rendering, and accelerated audio
  transcription; OpenCL doesn't.

- Audio transcription on a 4GB Quadro P1000 GPU often runs out of GPU memory.
  For me, changing my desktop resolution to 1080p instead of 4K gives it enough
  headroom to finish.  You can then change back to 4K.  I've also *think* I've
  seen it get enough headroom to finish by changing the GPU processing mode to
  OpenCL (although it goes much, much slower), but it might have been a fluke.

- Press super and hold title bar to make non-fullscreen.

  

  
