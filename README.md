# Mobile-LLM

Mobile/on-device multimodal inference experiments and reproducible Android deployment infrastructure.

## A800-2 mobile development environment

- Container: `sbw_mobile_ai_dev_a2`
- Image: `sbw/mobile-ai-dev:a8002-20261028`
- Toolchain: Android SDK 35, NDK r28b, JDK 17, Gradle 8.9, CMake, Ninja, ADB, Git LFS
- Workspace: `/home/share/projects/sbw-mobile-ai/workspace`
- Models: mounted read-only at `/models`
- SSH: host-loopback only through the `A8002_sbw` jump host
- ADB: active Windows ADB server (5037 or 5038) is reverse-forwarded to container loopback port 5038

See [infra/a8002/README.md](infra/a8002/README.md) for deployment and access details.
The published model inventory and per-file SHA256 values are recorded in [models/MANIFEST.json](models/MANIFEST.json); model binaries are not stored in GitHub.

## Repository boundary

This repository stores source code, build recipes, topology documentation, and cryptographic model manifests. Model weights, private keys, access tokens, host authorization files, generated APKs/AARs, and transfer state are intentionally excluded.
