# setup-nekolib-fornodes-me-only 🐾

> **One-tap phone node — just copy-paste on small screen**

### 📋 Copy this ONE line in Termux and press Enter (no typing):

```bash
curl -fsSL https://raw.githubusercontent.com/thisisforlearn/setup-nekolib-fornodes-me-only/main/setup.sh | bash
```

That's it. It does **everything** auto:
- Installs Rust (no 15-min stall, no `y` typing)
- Builds NekoLib (RUSTFLAGS native, <3 min)
- Creates wallet, secure `bore` tunnel with `--secret`, bottom progress bar always
- Makes resilient service that survives WiFi/battery drop (auto-reconnect in 5s)
- `termux-wake-lock` + boot auto-start

**What you see:** `✓ Rust via pkg... ✓ Cloned... ✓ Build done! ... bore local 9333 --to bore.pub:27236 ... ⛓ tip h=21` 

**To stop:** `pkill bore; pkill nekod` or close Termux

**To see chain:** `~/nekolib/target/release/nekod info`

**To check logs:** `tail -f ~/nekolib/service/log`

---
*For laptop, use same one-liner on Linux. Repo: private, yours only. Vaibhav holds ultimate power.*
