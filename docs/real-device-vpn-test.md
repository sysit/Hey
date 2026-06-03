# Real Device VPN Closed Loop Test

This checklist verifies the current MVP path:

`VpnExtensionAbility -> TUN fd -> CGoSetTunFd -> Xray native TUN inbound -> Xray outbound`

## Build and Install

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/device_vpn_smoke_test.sh build
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/device_vpn_smoke_test.sh install
```

The smoke-test script installs the signed HAP. If install still fails with a
signature error, refresh the DevEco debug signing config and rebuild.

## Log Watch

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/device_vpn_smoke_test.sh logs
```

Expected tags:

- `HeyVpnAbility`: VPN authorization, TUN fd, lifecycle cleanup.
- `HeyNative`: `dlopen`, `dlsym`, TUN fd setup, Xray start/stop.
- In-app Logs panel: mirrored diagnostic events from the VPN extension plus periodic native stats.

## Manual Closed Loop

1. Open Hey on the device.
2. Paste a subscription URL or a single VLESS/REALITY link.
3. Select one node and tap Start.
4. Accept the system VPN authorization dialog.
5. Confirm the in-app log sequence:
   - `VPN ability created.`
   - `VPN created. tunFd=<number>`
   - `Xray TUN fd configured.`
   - `Xray started.`
   - repeated `Native bridge stats.`
6. Open another app, such as the system browser, and visit a site that requires the proxy.
7. Return to Hey and confirm upload/download counters increase.
8. Tap Stop and confirm:
   - `Xray stop requested.`
   - `VPN destroyed.`
   - the system VPN icon disappears.

## Failure Signals

- `dlopen libxray.so failed`: the packaged Go shared library is not accepted by the device runtime or was not packaged.
- `dlsym libxray.so failed`: exported symbols changed; verify `CGoSetTunFd`, `CGoRunXrayFromJSON`, and `CGoStopXray`.
- `Xray TUN fd configured` never appears: the Harmony VPN fd was not returned or libXray lacks `CGoSetTunFd`.
- VPN starts but traffic never increases: check whether the browser traffic is really routed through the VPN and whether the app's own bundle exclusion is avoiding Xray socket loops.
