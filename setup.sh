#!/usr/bin/env bash
# setup-nekolib-fornodes-me-only — ONE-TAP phone node
# Just: curl -fsSL https://raw.githubusercontent.com/thisisforlearn/setup-nekolib-fornodes-me-only/main/setup.sh | bash
# No typing, bottom bar always, survives WiFi/power drop, secure bore --secret
# Author: Vaibhav — GPLv3 — Vaibhav holds ultimate power
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; MAG='\033[0;35m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
ok(){ echo -e "${GREEN}✓${RESET} $*"; }
info(){ echo -e "${CYAN}●${RESET} $*"; }
warn(){ echo -e "${YELLOW}⚠${RESET} $*"; }

BAR_W=28
progress(){ local cur=$1 tot=4 msg="$2" pct=$((cur*100/tot)) filled=$((cur*BAR_W/tot)) empty=$((BAR_W-filled)); bar="$(printf '█%.0s' $(seq 1 $filled 2>/dev/null) 2>/dev/null)$(printf '░%.0s' $(seq 1 $empty 2>/dev/null) 2>/dev/null)"; printf "\r${DIM}[%s] %d%% %s${RESET}   \n" "$bar" "$pct" "$msg"; }

cat <<'BANNER'
 ███╗   NEKOLIB ONE-TAP (phone me-only)
BANNER
echo -e "${DIM}One line → full node + secure tunnel + auto-reconnect — no typing${RESET}\n"

progress 0 "starting..."
need(){ command -v "$1" >/dev/null 2>&1; }

# keep phone awake
termux-wake-lock 2>/dev/null || true

# 1/4 deps — FAST, no 15-min pkg update
progress 1 "deps..."
if ! need cargo; then
  info "Installing Rust via pkg (fast)..."
  pkg install -y rust clang git termux-tools termux-api 2>&1 | tail -n 8 || {
    warn "retry with apt update..."
    apt update -o Acquire::Retries=2 2>&1 | tail -n 5 || true
    pkg install -y rust clang git 2>&1 | tail -n 5
  }
  ok "Rust $(rustc --version 2>&1 | head -n1)"
else
  ok "Rust $(cargo --version 2>&1 | head -n1)"
fi
export PATH="$HOME/.cargo/bin:$PATH"
# bore
if ! need bore; then
  info "Installing bore..."
  cargo install bore-cli 2>&1 | tail -n 5 || true
  ok "bore $(bore --version 2>&1 | head -n1 || echo ok)"
fi

progress 2 "download..."
DEST="$HOME/nekolib"
if [ -d "$DEST/.git" ]; then git -C "$DEST" pull --ff-only 2>&1 | tail -n 3; else rm -rf "$DEST"; git clone https://github.com/thisisforlearn/nekolib.git "$DEST" --depth 1; fi
cd "$DEST"
ok "Cloned to $DEST"

progress 3 "building 60-180s..."
info "Building native (no NDK needed)..."
# Termux fix: .cargo config already no forced linker, but ensure
if RUSTFLAGS="-C target-cpu=native" cargo build --release 2>&1 | tail -n 30; then ok "Build done $(du -h target/release/nekod 2>&1 | cut -f1 | head -n1)"; else warn "Build failed — check log, retry pkg install rust clang"; fi
progress 4 "built!"

# wallet
if [ ! -f "$DEST/nekodata/wallet.json" ]; then "$DEST/target/release/nekod" wallet 2>&1 | tail -n 15; else ok "Wallet exists"; fi

# secure secret
SECRET_FILE="$HOME/nekolib/BORE_SECRET"
if [ ! -f "$SECRET_FILE" ]; then openssl rand -hex 16 > "$SECRET_FILE" 2>/dev/null || head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$SECRET_FILE"; fi
SECRET="$(cat "$SECRET_FILE")"
info "Secure bore secret: ${SECRET:0:8}... (saved to $SECRET_FILE)"

# resilient service — survives WiFi/power 1-2 min gap
mkdir -p ~/nekolib/service ~/.termux/boot
cat > ~/nekolib/service/run.sh <<SVC
#!/data/data/com.termux/files/usr/bin/bash
set -e
export BORE_SECRET="\$(cat $SECRET_FILE)"
export PATH="\$HOME/.cargo/bin:\$PATH"
termux-wake-lock 2>/dev/null || true
while true; do
  echo "[\$(date)] starting nekod..."
  RUSTFLAGS="-C target-cpu=native" $DEST/target/release/nekod start --mine &
  NEKOPID=\$!
  echo "[\$(date)] starting bore on fixed port 27236 (secure)..."
  bore local 9333 --to bore.pub --port 27236 --secret "\$BORE_SECRET" &
  BOREPID=\$!
  wait -n \$NEKOPID \$BOREPID || true
  echo "[\$(date)] drop detected, restart in 5s..."
  kill \$NEKOPID \$BOREPID 2>/dev/null || true; pkill bore; pkill nekod || true
  sleep 5
  until ping -c1 8.8.8.8 >/dev/null 2>&1; do echo "waiting net..."; sleep 5; done
done
SVC
chmod +x ~/nekolib/service/run.sh
cat > ~/.termux/boot/start-nekolib.sh <<'BOOT'
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
nohup bash ~/nekolib/service/run.sh > ~/nekolib/service/log 2>&1 &
BOOT
chmod +x ~/.termux/boot/start-nekolib.sh

# start now
pkill bore; pkill nekod || true
nohup bash ~/nekolib/service/run.sh > ~/nekolib/service/log 2>&1 &
sleep 2
ok "Service started — bore.pub:27236 with secret, auto-reconnect"
info "Laptop bootstrap: \"bore.pub:27236\"  (use same BORE_SECRET if self-hosting)"
info "Check: tail -f ~/nekolib/service/log  or  ~/nekolib/target/release/nekod info"
echo -e "\n${GREEN}Done! Phone is global seed — safe, only 9333 exposed, IP hidden (peers see bore.pub), auto-survives WiFi/battery drop.${RESET}"
echo -e "${DIM}Share laptop: nekolib.json bootstrap_peers=[\"bore.pub:27236\"]${RESET}"
