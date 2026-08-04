const { Plugin, Notice, PluginSettingTab, Setting } = require("obsidian");
const { execFile } = require("child_process");
const { promisify } = require("util");
const path = require("path");
const fs = require("fs");

const execFileAsync = promisify(execFile);

const SSH_REMOTE = "git@github.com:169068671/Summary-of-zcode-Workflows.git";
const LEGACY_HTTPS_REMOTE = "https://github.com/169068671/Summary-of-zcode-Workflows.git";

const DEFAULT_SETTINGS = {
  remoteUrl: SSH_REMOTE,
  branch: "main",
  runValidation: true,
};

class CodexGitHubSyncPlugin extends Plugin {
  async onload() {
    this.settings = Object.assign({}, DEFAULT_SETTINGS, await this.loadData());
    if (this.settings.remoteUrl.replace(/\/$/, "") === LEGACY_HTTPS_REMOTE) {
      this.settings.remoteUrl = SSH_REMOTE;
      await this.saveData(this.settings);
    }
    this.syncing = false;
    this.statusBar = this.addStatusBarItem();
    this.statusBar.setText("GitHub: 待同步");

    this.addRibbonIcon("cloud-upload", "同步 Codex 工作流到 GitHub", () => this.runSync(false));
    this.addCommand({
      id: "sync-codex-workflows-to-github",
      name: "一键同步整个仓库到 GitHub",
      callback: () => this.runSync(false),
    });
    this.addCommand({
      id: "check-codex-workflows-git-status",
      name: "检查 GitHub 同步状态",
      callback: () => this.runSync(true),
    });
    this.addCommand({
      id: "test-codex-workflows-github-ssh",
      name: "测试 GitHub SSH 连接（不上传）",
      callback: () => this.runSshTest(),
    });
    this.addSettingTab(new CodexGitHubSyncSettingTab(this.app, this));
  }

  vaultPath() {
    const adapter = this.app.vault.adapter;
    if (!adapter || typeof adapter.getBasePath !== "function") {
      throw new Error("此插件只支持 Obsidian 桌面端的本地知识库。");
    }
    return adapter.getBasePath();
  }

  scriptPath(vaultPath) {
    return path.join(vaultPath, ".obsidian", "plugins", this.manifest.id, "sync_vault.py");
  }

  parsePayload(stdout, fallback) {
    try {
      return JSON.parse((stdout || "").trim());
    } catch (_) {
      return { ok: false, message: fallback || "同步脚本未返回有效结果。" };
    }
  }

  async runSync(statusOnly) {
    if (this.syncing) {
      new Notice("同步任务正在运行，请勿重复点击。");
      return;
    }

    this.syncing = true;
    const notice = new Notice(statusOnly ? "正在检查 Git 状态…" : "正在核验并同步到 GitHub…", 0);
    this.statusBar.setText(statusOnly ? "GitHub: 检查中" : "GitHub: 同步中");

    try {
      const vaultPath = this.vaultPath();
      const scriptPath = this.scriptPath(vaultPath);
      if (!fs.existsSync(scriptPath)) {
        throw new Error(`缺少同步脚本：${scriptPath}`);
      }

      const args = [
        scriptPath,
        "--vault",
        vaultPath,
        "--remote-url",
        this.settings.remoteUrl,
        "--branch",
        this.settings.branch,
        "--json",
      ];
      if (statusOnly) args.push("--status");
      if (!statusOnly && this.settings.runValidation) args.push("--validate");

      const { stdout } = await execFileAsync("python3", args, {
        cwd: vaultPath,
        timeout: 180000,
        maxBuffer: 8 * 1024 * 1024,
        env: Object.assign({}, process.env, { GIT_TERMINAL_PROMPT: "0" }),
      });
      const payload = this.parsePayload(stdout);
      if (!payload.ok) throw new Error(payload.message);

      notice.setMessage(payload.message);
      this.statusBar.setText(statusOnly ? `GitHub: ${payload.changes || 0} 项待同步` : `GitHub: 已同步 ${payload.commit}`);
      window.setTimeout(() => notice.hide(), 5000);
    } catch (error) {
      const stdout = error && error.stdout ? String(error.stdout) : "";
      const payload = this.parsePayload(stdout, error && error.message ? error.message : String(error));
      const message = payload.message || (error && error.message) || String(error);
      console.error("GitHub SSH Sync failed", error);
      notice.setMessage(`GitHub 同步失败：${message}`);
      this.statusBar.setText("GitHub: 同步失败");
      window.setTimeout(() => notice.hide(), 12000);
    } finally {
      this.syncing = false;
    }
  }

  async runSshTest() {
    if (this.syncing) {
      new Notice("同步任务正在运行，请勿重复点击。");
      return;
    }

    this.syncing = true;
    const notice = new Notice("正在测试 GitHub SSH 连接…", 0);
    this.statusBar.setText("GitHub SSH: 测试中");

    try {
      const vaultPath = this.vaultPath();
      const scriptPath = this.scriptPath(vaultPath);
      if (!fs.existsSync(scriptPath)) {
        throw new Error(`缺少同步脚本：${scriptPath}`);
      }
      const { stdout } = await execFileAsync(
        "python3",
        [
          scriptPath,
          "--vault",
          vaultPath,
          "--remote-url",
          this.settings.remoteUrl,
          "--branch",
          this.settings.branch,
          "--test-connection",
          "--json",
        ],
        {
          cwd: vaultPath,
          timeout: 60000,
          maxBuffer: 2 * 1024 * 1024,
          env: Object.assign({}, process.env, { GIT_TERMINAL_PROMPT: "0" }),
        }
      );
      const payload = this.parsePayload(stdout);
      if (!payload.ok) throw new Error(payload.message);
      notice.setMessage(payload.message);
      this.statusBar.setText("GitHub SSH: 可用");
      window.setTimeout(() => notice.hide(), 6000);
    } catch (error) {
      const stdout = error && error.stdout ? String(error.stdout) : "";
      const payload = this.parsePayload(stdout, error && error.message ? error.message : String(error));
      const message = payload.message || (error && error.message) || String(error);
      console.error("GitHub SSH test failed", error);
      notice.setMessage(`GitHub SSH 测试失败：${message}`);
      this.statusBar.setText("GitHub SSH: 失败");
      window.setTimeout(() => notice.hide(), 12000);
    } finally {
      this.syncing = false;
    }
  }
}

class CodexGitHubSyncSettingTab extends PluginSettingTab {
  constructor(app, plugin) {
    super(app, plugin);
    this.plugin = plugin;
  }

  display() {
    const { containerEl } = this;
    containerEl.empty();
    containerEl.createEl("h2", { text: "GitHub SSH Sync" });
    containerEl.createEl("p", {
      text: "插件不保存 Token，固定使用电脑现有的 GitHub SSH 密钥；不会强推或改写历史。",
    });

    new Setting(containerEl)
      .setName("GitHub 仓库地址")
      .setDesc("使用 git@github.com:… 的 SSH 地址。旧版同仓库 HTTPS 地址会自动迁移为 SSH；不同仓库仍会停止。")
      .addText((text) =>
        text
          .setPlaceholder(DEFAULT_SETTINGS.remoteUrl)
          .setValue(this.plugin.settings.remoteUrl)
          .onChange(async (value) => {
            this.plugin.settings.remoteUrl = value.trim();
            await this.plugin.saveData(this.plugin.settings);
          })
      );

    new Setting(containerEl)
      .setName("分支")
      .setDesc("默认 main。当前分支与设置不一致时会停止。")
      .addText((text) =>
        text.setValue(this.plugin.settings.branch).onChange(async (value) => {
          this.plugin.settings.branch = value.trim() || "main";
          await this.plugin.saveData(this.plugin.settings);
        })
      );

    new Setting(containerEl)
      .setName("上传前核验知识库")
      .setDesc("建议始终开启。核验不通过时不会提交或推送。")
      .addToggle((toggle) =>
        toggle.setValue(this.plugin.settings.runValidation).onChange(async (value) => {
          this.plugin.settings.runValidation = value;
          await this.plugin.saveData(this.plugin.settings);
        })
      );

    new Setting(containerEl)
      .setName("检查当前状态")
      .setDesc("只读检查，不初始化、不提交、不推送。")
      .addButton((button) => button.setButtonText("检查").onClick(() => this.plugin.runSync(true)));

    new Setting(containerEl)
      .setName("测试 SSH 连接")
      .setDesc("只测试读取 GitHub 仓库，不提交、不推送。")
      .addButton((button) => button.setButtonText("测试").onClick(() => this.plugin.runSshTest()));

    containerEl.createEl("h3", { text: "首次使用前的 GitHub 认证" });
    containerEl.createEl("p", {
      text: "请先把本机 SSH 公钥添加到 GitHub，再在终端执行 ssh -T git@github.com 验证。插件不会读取或保存私钥。",
    });
  }
}

module.exports = CodexGitHubSyncPlugin;
