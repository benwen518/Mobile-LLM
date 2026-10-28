# A800-2 mobile AI development container

## Verified deployment

- Host alias: `A8002_sbw`
- Container: `sbw_mobile_ai_dev_a2`
- Container SSH alias: `A8002-sbw_mobile_ai_dev_a2`
- Image: `sbw/mobile-ai-dev:a8002-20261028`
- Runtime network mode: host network, because the A800-2 Docker host currently lacks the `iptables` binary required for Docker port publishing
- SSH daemon: `127.0.0.1:32328` on A800-2, reachable only through the jump host
- Workspace mount: `/home/share/projects/sbw-mobile-ai/workspace:/workspace` (read/write)
- Model mount: `/home/share/models/sbw-mobile-ai:/models` (read-only)
- Infra mount: `/home/share/projects/sbw-mobile-ai/infra:/config` (read-only)

The image contains Android SDK 35, Android NDK r28b, Gradle 8.9, JDK 17, CMake, Ninja, Git LFS, ADB, and OpenSSH.

## ADB path

```text
PLR110
  -> Windows ADB server (auto-detect 5038, then 5037)
  -> OpenSSH remote forward
  -> A800-2/container loopback 127.0.0.1:5038
  -> adb -H 127.0.0.1 -P 5038
```

The Windows watchdog is `infra/a8002/A8002-Mobile-AI-ADB-tunnel.ps1`. It controls only the SSH child process it creates and never terminates unrelated ADB or SSH processes.

## Model policy

Weights are not committed to GitHub. The private model tree is staged at `/home/share/models/sbw-mobile-ai/.incoming-20261028`, verified against `models/MANIFEST.json`, and published atomically as `/home/share/models/sbw-mobile-ai/20261028` only after every file passes SHA256 verification.

