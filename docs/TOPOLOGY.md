# A800-2 mobile development topology

Verified on 2026-10-28.

```text
PLR110 (3B661K0119Q00000, arm64-v8a)
  -> Windows ADB server (active port auto-detected: 5037 or 5038)
  -> persistent OpenSSH reverse tunnel
  -> A800-2 / sbw_mobile_ai_dev_a2 loopback 127.0.0.1:5038

Developer
  -> SSH alias A8002_sbw
  -> A800-2 loopback 127.0.0.1:32328
  -> sbw_mobile_ai_dev_a2
  -> /workspace/Mobile-LLM

/home/share/models/sbw-mobile-ai/20261028
  -> read-only bind mount /models/20261028
```

## Runtime receipt

| Item | Verified value |
| --- | --- |
| Container | `sbw_mobile_ai_dev_a2` |
| Container ID | `b5bb374dd82d1693aa8822707014b7856073d29f71ec18b3453b29832998cf7f` |
| Image | `sbw/mobile-ai-dev:a8002-20261028` |
| Image ID | `sha256:9d06353408129e8939aa06583fcd274c8bfc159231bbf2365d7a0df217517f7d` |
| Image size | 7,242,704,413 bytes |
| Restart policy | `unless-stopped` |
| Network | `host`; SSH binds only to `127.0.0.1:32328` |
| Workspace | `/home/share/projects/sbw-mobile-ai/workspace:/workspace` (read/write) |
| Models | `/home/share/models/sbw-mobile-ai:/models` (read-only) |
| GitHub | `https://github.com/benwen518/Mobile-LLM.git` |

## Model receipt

| Gate | Result |
| --- | --- |
| Payload files | 95/95 |
| Payload bytes | 25,376,469,088 |
| Per-file SHA256 | PASS, 0 failures |
| Manifest SHA256 | `f96556db3d705038bcd4c68c36c92f86872ff930ab87d6c1b3962d3e4bd9f5e4` |
| Receipt SHA256 | `e9844fb5ff6f9574fec0473d9d24ef773dc66a4794f51bd9aabdd3a738e89477` |
| Published tree | `/home/share/models/sbw-mobile-ai/20261028` |
| Container visibility | `/models/20261028` |
| Container write test | correctly rejected by read-only mount |

The public manifest replaces the local absolute source root with `<local-project-root>`. All relative source paths, destination paths, byte counts, and SHA256 values are unchanged.

## Security boundary

- A800-2 SSH and container SSH are not exposed as new public listeners.
- The ADB reverse forward listens on loopback only.
- The container has a dedicated ED25519 key and password authentication is disabled.
- No shared GitHub PAT or private key is stored in the container; collaborators authenticate pushes individually.
- GitHub excludes model weights, APK/AAR output, credentials, and transfer state.
