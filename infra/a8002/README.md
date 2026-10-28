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

## Access

```powershell
ssh A8002-sbw_mobile_ai_dev_a2
```

The shared checkout is `/workspace/Mobile-LLM`, with origin `https://github.com/benwen518/Mobile-LLM.git`. Fetch and pull work without a credential. Push authentication is intentionally per contributor; no shared GitHub token or private key is stored in the container.

## ADB path

```text
PLR110
  -> Windows ADB server (auto-detect 5038, then 5037)
  -> OpenSSH remote forward
  -> A800-2/container loopback 127.0.0.1:5038
  -> adb -H 127.0.0.1 -P 5038
```

The Windows watchdog is `infra/a8002/A8002-Mobile-AI-ADB-tunnel.ps1`. It controls only the SSH child process it creates and never terminates unrelated ADB or SSH processes.

```bash
adb -H 127.0.0.1 -P 5038 devices -l
```

## Model policy

Weights are not committed to GitHub. The private snapshot was verified against [models/MANIFEST.json](../../models/MANIFEST.json) and atomically published at `/home/share/models/sbw-mobile-ai/20261028`.

- Files verified: 95/95
- Payload bytes: 25,376,469,088
- Manifest SHA256: `f96556db3d705038bcd4c68c36c92f86872ff930ab87d6c1b3962d3e4bd9f5e4`
- Receipt SHA256: `e9844fb5ff6f9574fec0473d9d24ef773dc66a4794f51bd9aabdd3a738e89477`
- Verification failures: 0

