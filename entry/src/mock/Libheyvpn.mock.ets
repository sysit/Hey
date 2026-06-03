class NativeResultModel {
  ok: boolean;
  message: string;

  constructor(ok: boolean, message: string) {
    this.ok = ok;
    this.message = message;
  }
}

class RuntimeStatsModel {
  uploadBytes: number = 0;
  downloadBytes: number = 0;
  xrayRunning: boolean = false;
  tunRunning: boolean = false;
  lastMessage: string = 'Mock native bridge ready.';
}

class LibheyvpnMock {
  validateConfig(configJson: string): NativeResultModel {
    const ok = configJson.length > 0 && configJson.indexOf('"outbounds"') >= 0;
    return new NativeResultModel(ok, ok ? 'Mock config preflight passed.' : 'Mock config is missing outbounds.');
  }

  setTunFd(tunFd: number): NativeResultModel {
    const ok = tunFd >= 0;
    return new NativeResultModel(ok, ok ? 'Mock Xray TUN fd configured.' : 'Mock TUN fd is invalid.');
  }

  startXray(configJson: string): NativeResultModel {
    return new NativeResultModel(configJson.length > 0, 'Mock Xray bridge started.');
  }

  stopXray(): NativeResultModel {
    return new NativeResultModel(true, 'Mock Xray bridge stopped.');
  }

  getStats(): RuntimeStatsModel {
    return new RuntimeStatsModel();
  }
}

export default new LibheyvpnMock();
