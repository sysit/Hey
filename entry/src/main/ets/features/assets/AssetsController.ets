import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { http } from '@kit.NetworkKit';
import fs from '@ohos.file.fs';
import { shouldExposeLocalHttpProxy } from '../../core/LocalProxy';
import { AppLanguage } from '../../core/Profile';
import { LOCAL_HTTP_PROXY_HOST, LOCAL_HTTP_PROXY_PORT } from '../../core/XrayConfig';
import { translate } from '../../core/I18n';
import { formatTwo } from '../../utils/LocalizationPresenter';
import { AssetStore, CustomAssetUrl } from '../../storage/AssetStore';
import { SettingsStore } from '../../storage/SettingsStore';


export function buildAssetDownloadProxyPorts(proxyPort: number): Array<number> {
  if (!isValidAssetDownloadProxyPort(proxyPort)) {
    return [0];
  }
  return [Math.floor(proxyPort), 0];
}

function isValidAssetDownloadProxyPort(proxyPort: number): boolean {
  return typeof proxyPort === 'number' && Math.floor(proxyPort) === proxyPort && proxyPort > 0 && proxyPort <= 65535;
}

export class AssetsController {
  
  private pad(val: number): string {
    return val < 10 ? `0${val}` : `${val}`;
  }

  private t(language: AppLanguage, key: string): string {
    return translate(language, key);
  }

  // 获取本地 dat 文件大小和修改日期
  getFileStatus(context: common.Context, fileName: string, language: AppLanguage): string {
    const path = `${context.filesDir}/${fileName}`;
    try {
      if (fs.accessSync(path)) {
        const stat = fs.statSync(path);
        const sizeMb = (stat.size / (1024 * 1024)).toFixed(2);
        const date = new Date(stat.mtime * 1000);
        const timeStr = `${date.getFullYear()}/${this.pad(date.getMonth() + 1)}/${this.pad(date.getDate())} ${this.pad(date.getHours())}:${this.pad(date.getMinutes())}:${this.pad(date.getSeconds())}`;
        return formatTwo(language, 'assets.fileStatus', 'size', sizeMb, 'time', timeStr);
      }
    } catch (e) {}
    return this.t(language, 'assets.notDownloaded');
  }

  // 获取自定义资源的大小
  getCustomFileStatus(context: common.Context, name: string, language: AppLanguage): string {
    const path = `${context.filesDir}/${name}.dat`;
    try {
      if (fs.accessSync(path)) {
        const stat = fs.statSync(path);
        const sizeMb = (stat.size / (1024 * 1024)).toFixed(2);
        return `${sizeMb} MB`;
      }
    } catch (e) {}
    return this.t(language, 'assets.notDownloaded');
  }

  // 执行资源网络更新下载
  async downloadAsset(
    context: common.Context,
    fileName: string,
    url: string,
    language: AppLanguage,
    onStart: () => void,
    onSuccess: () => void,
    onError: (errMsg: string) => void,
    onComplete: () => void
  ): Promise<void> {
    onStart();

    const tempPath = `${context.filesDir}/${fileName}.tmp`;
    const targetPath = `${context.filesDir}/${fileName.endsWith('.dat') ? fileName : fileName + '.dat'}`;
    const proxyPort = await this.resolveDownloadProxyPort(context);

    try {
      promptAction.showToast({ message: this.t(language, 'assets.downloading').replace('{title}', fileName) });
      await this.downloadToFileWithFallback(url, tempPath, targetPath, proxyPort);
      promptAction.showToast({ message: this.t(language, 'assets.downloadSuccess').replace('{title}', fileName) });
      onSuccess();
    } catch (error) {
      try {
        if (fs.accessSync(tempPath)) {
          fs.unlinkSync(tempPath);
        }
      } catch (e) {}

      const errMsg = error instanceof Error ? error.message : JSON.stringify(error);
      promptAction.showToast({
        message: this.t(language, 'assets.downloadFailed')
          .replace('{title}', fileName)
          .replace('{error}', errMsg)
      });
      onError(errMsg);
    } finally {
      onComplete();
    }
  }

  // 一键更新全部：逐个刷新用户添加的远程资源（http/https；local:// 本地导入跳过），
  // 最终按成功 / 部分 / 全失败给出汇总提示。应用不内置任何下载源。
  async downloadAllAssets(
    context: common.Context,
    language: AppLanguage,
    remoteCustomAssets: Array<CustomAssetUrl>,
    onProgress: (fileName: string) => void,
    onComplete: () => void
  ): Promise<void> {
    try {
      promptAction.showToast({ message: this.t(language, 'assets.updatingAll') });
      const proxyPort = await this.resolveDownloadProxyPort(context);

      let total = 0;
      let success = 0;

      for (let index = 0; index < remoteCustomAssets.length; index++) {
        const asset = remoteCustomAssets[index];
        if (!this.isRemoteAssetUrl(asset.url)) {
          continue;
        }
        onProgress(asset.name);
        total++;
        if (await this.performDownload(context, `${asset.name}.dat`, asset.url.trim(), proxyPort)) {
          success++;
        }
      }

      if (total > 0 && success === total) {
        promptAction.showToast({ message: this.t(language, 'assets.updateAllSuccess') });
      } else if (success > 0) {
        promptAction.showToast({ message: this.t(language, 'assets.partialUpdateSuccess') });
      } else {
        promptAction.showToast({ message: this.t(language, 'assets.updateAllFailed') });
      }
      onComplete();
    } catch (error) {
      promptAction.showToast({ message: this.t(language, 'assets.updateAllError').replace('{error}', JSON.stringify(error)) });
      onComplete();
    }
  }

  private isRemoteAssetUrl(url: string): boolean {
    const lower = url.trim().toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  private async performDownload(context: common.Context, fileName: string, url: string, proxyPort: number): Promise<boolean> {
    const tempPath = `${context.filesDir}/${fileName}.tmp`;
    const targetPath = `${context.filesDir}/${fileName}`;
    try {
      await this.downloadToFileWithFallback(url, tempPath, targetPath, proxyPort);
      return true;
    } catch (error) {
      try {
        if (fs.accessSync(tempPath)) {
          fs.unlinkSync(tempPath);
        }
      } catch (e) {}
    }
    return false;
  }

  private async resolveDownloadProxyPort(context: common.Context): Promise<number> {
    try {
      const settings = await SettingsStore.load(context);
      return shouldExposeLocalHttpProxy(settings) ? LOCAL_HTTP_PROXY_PORT : 0;
    } catch (error) {
      return 0;
    }
  }

  private async downloadToFileWithFallback(url: string, tempPath: string, targetPath: string, proxyPort: number): Promise<void> {
    const ports = buildAssetDownloadProxyPorts(proxyPort);
    let lastError = '';
    for (let index = 0; index < ports.length; index++) {
      try {
        const data = await this.requestAssetData(url, ports[index]);
        this.writeAssetData(tempPath, targetPath, data);
        return;
      } catch (error) {
        lastError = error instanceof Error ? error.message : JSON.stringify(error);
        this.removeTempFile(tempPath);
      }
    }
    throw new Error(lastError.length > 0 ? lastError : 'download failed');
  }

  private async requestAssetData(url: string, proxyPort: number): Promise<ArrayBuffer> {
    const request = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        readTimeout: 60000,
        connectTimeout: 15000,
        usingCache: false
      };
      if (isValidAssetDownloadProxyPort(proxyPort)) {
        options.usingProxy = {
          host: LOCAL_HTTP_PROXY_HOST,
          port: proxyPort,
          exclusionList: []
        };
      }
      const response = await request.request(url, options);
      const responseCode = Number(response.responseCode);
      if (responseCode < 200 || responseCode >= 300) {
        throw new Error(`HTTP ${response.responseCode}`);
      }
      return response.result as ArrayBuffer;
    } finally {
      request.destroy();
    }
  }

  private writeAssetData(tempPath: string, targetPath: string, data: ArrayBuffer): void {
    const file = fs.openSync(tempPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
    fs.writeSync(file.fd, data);
    fs.closeSync(file);
    try {
      if (fs.accessSync(targetPath)) {
        fs.unlinkSync(targetPath);
      }
    } catch (e) {}
    fs.renameSync(tempPath, targetPath);
  }

  private removeTempFile(tempPath: string): void {
    try {
      if (fs.accessSync(tempPath)) {
        fs.unlinkSync(tempPath);
      }
    } catch (e) {}
  }

  // 流式拷贝文件到沙箱
  async copyLocalFileToAssets(
    context: common.Context,
    srcUri: string,
    destFileName: string,
    language: AppLanguage,
    onSuccess: () => void,
    onError: (errMsg: string) => void
  ): Promise<boolean> {
    const destPath = `${context.filesDir}/${destFileName}`;
    const tempPath = `${context.filesDir}/${destFileName}.tmp`;

    let srcFile: fs.File | null = null;
    let destFile: fs.File | null = null;
    try {
      srcFile = fs.openSync(srcUri, fs.OpenMode.READ_ONLY);
      destFile = fs.openSync(tempPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);

      const buf = new ArrayBuffer(8192);
      let readLen = 0;
      while ((readLen = fs.readSync(srcFile.fd, buf)) > 0) {
        fs.writeSync(destFile.fd, buf, { length: readLen });
      }

      fs.closeSync(srcFile);
      fs.closeSync(destFile);
      srcFile = null;
      destFile = null;

      try {
        if (fs.accessSync(destPath)) {
          fs.unlinkSync(destPath);
        }
      } catch (e) {}
      fs.renameSync(tempPath, destPath);

      promptAction.showToast({ message: this.t(language, 'assets.action.importLocal.success').replace('{title}', destFileName) });
      onSuccess();
      return true;
    } catch (error) {
      if (srcFile) fs.closeSync(srcFile);
      if (destFile) fs.closeSync(destFile);
      try {
        if (fs.accessSync(tempPath)) {
          fs.unlinkSync(tempPath);
        }
      } catch (e) {}

      const errMsg = error instanceof Error ? error.message : JSON.stringify(error);
      promptAction.showToast({ message: this.t(language, 'assets.action.importLocal.failed').replace('{error}', errMsg) });
      onError(errMsg);
      return false;
    }
  }

  // 删除 Geo 资源
  deleteAsset(context: common.Context, fileName: string, language: AppLanguage, onComplete: () => void): void {
    const targetPath = `${context.filesDir}/${fileName}`;
    try {
      if (fs.accessSync(targetPath)) {
        fs.unlinkSync(targetPath);
        promptAction.showToast({ message: this.t(language, 'assets.deleteSuccess').replace('{title}', fileName) });
      }
    } catch (error) {
      promptAction.showToast({ message: this.t(language, 'assets.deleteFailed').replace('{error}', JSON.stringify(error)) });
    } finally {
      onComplete();
    }
  }

  // 删除自定义 URL 链接及本地 dat 文件
  async deleteCustomAsset(context: common.Context, item: CustomAssetUrl, customAssets: Array<CustomAssetUrl>, language: AppLanguage): Promise<Array<CustomAssetUrl>> {
    const path = `${context.filesDir}/${item.name}.dat`;
    try {
      if (fs.accessSync(path)) {
        fs.unlinkSync(path);
      }
    } catch (e) {}

    const updated = customAssets.filter(asset => asset.id !== item.id);
    await AssetStore.save(context, updated);
    promptAction.showToast({ message: this.t(language, 'assets.customDeleteSuccess') });
    return updated;
  }

}

export const ASSETS_CONTROLLER: AssetsController = new AssetsController();
