# Hey VPN Native Core

`libheyvpn.so` is the ArkTS N-API bridge. It is now prepared for real core
integration through two optional native libraries packaged beside it:

- `libxray.so`: built from XTLS/libXray with cgo exports. Required symbols:
  - `CGoRunXrayFromJSON(const char* base64Request) -> char*`
  - `CGoStopXray() -> char*`
- `libheytun2socks.so`: a small Harmony adapter around the chosen tun2socks
  implementation. Required symbols:
  - `HeyTun2SocksStart(int tunFd, const char* socksHost, int socksPort, int mtu) -> int`
  - `HeyTun2SocksStop() -> void`
  - optional `HeyTun2SocksUploadBytes() -> int64_t`
  - optional `HeyTun2SocksDownloadBytes() -> int64_t`

If those libraries are absent, `libheyvpn.so` keeps the app lifecycle working
and returns explicit fallback messages. Packet forwarding becomes real only
after both optional libraries are packaged and load successfully.
