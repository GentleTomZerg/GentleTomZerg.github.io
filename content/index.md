---
title: Home
publish: true
---

<div class="avatar-hero">
  <video
    id="avatarVideo"
    class="avatar-video"
    src="assets/avatar-11s.mp4"
    muted
    loop
    autoplay
    playsinline
    preload="auto"
  ></video>
</div>

<style>
.avatar-hero {
  display: flex;
  justify-content: center;
  margin: 1.2rem 0 0.5rem;
}
.avatar-video {
  width: 180px;
  aspect-ratio: 768 / 936;
  object-fit: cover;
  border-radius: 28px;
  display: block;
  border: 2px solid var(--lightgray);
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.18);
  background: #e8e3d5;
}
</style>

<script>
(function () {
  function playAvatar() {
    var video = document.getElementById("avatarVideo")
    if (!video) return
    video.muted = true
    try { video.currentTime = 0 } catch (e) {}
    video.play().catch(function () {})
  }
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", playAvatar)
  } else {
    playAvatar()
  }
  document.addEventListener("nav", function () { setTimeout(playAvatar, 50) })
})();
</script>

Welcome! This is my public notebook — notes on logic, operating systems,
software design, and books I'm reading.

Use the search or the explorer on the left to browse around.
