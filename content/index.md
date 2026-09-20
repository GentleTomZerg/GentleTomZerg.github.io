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

## Summaries

- [[伯林我的学术之路]] — 伯林学术自述：牛津证实主义异端→一元论批判→多元论与两种自由；pass1 read

## Concepts

- [[一元论]] — 一问题一答案、答案和谐可集成完美生活
- [[价值多元论]] — 价值多而客观、互斥、可理解可评判；非相对主义
- [[消极自由与积极自由]] — 免于障碍 vs 谁控制我；高级自我偷换即压迫
- [[历史决定论批判]] — 决定论的代价：道德语言崩塌；必然 yet 牺牲悖论
- [[文化重心与内部理解]] — 维柯内部理解、赫尔德重心、大花园
- [[浪漫主义的价值创造论]] — 价值被造非被发现；拜伦个体 vs 集体超我

## Entities

- [[伯林]] — 本书作者，一元论怀疑者、多元论提出者
- [[维柯]] — 文化观念第一人，内部理解源头
- [[赫尔德]] — 文化重心、大花园；文化民族主义之父
- [[赫尔岑]] — 歌例；俄国章再遇

## Comparisons
## Syntheses
