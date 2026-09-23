---
title: Home
publish: true
---

<div class="avatar-hero">
  <video
    class="avatar-video"
    src="assets/avatar.mp4"
    poster="assets/avatar-poster.jpg"
    muted
    loop
    autoplay
    playsinline
    preload="auto"
    aria-hidden="true"
  ></video>
</div>

<style>
.avatar-hero {
  position: relative;
  display: flex;
  justify-content: center;
  margin: 1.5rem 0 0.75rem;
}
.avatar-hero::before {
  content: "";
  position: absolute;
  width: 320px;
  height: 320px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(143, 159, 169, 0.22), transparent 70%);
  filter: blur(28px);
  pointer-events: none;
}
.avatar-video {
  position: relative;
  width: 180px;
  aspect-ratio: 360 / 438;
  object-fit: cover;
  border-radius: 26px;
  display: block;
  border: 1px solid var(--lightgray);
  box-shadow: 0 14px 38px rgba(0, 0, 0, 0.16);
  background: #e8e3d5;
}
</style>

Hi, I'm Tom. I sketch, I read, and I write down what I find.

## Paths

- **[[wiki/index|Wiki]]** — notes on logic, operating systems, software design, and the books I'm reading.

<!-- To add a path: one more bullet, `**[[folder/page|Label]]** — one line.`
     Keep the list short; this page is a doorway, not a table of contents. -->
