# iOSのデバッグ

## シミュレータの権限

TCCの状態をスクリプトで操作し、権限まわりの経路を再現する:

```bash
xcrun simctl privacy <UDID> grant photos-add <bundle-id>
xcrun simctl privacy <UDID> revoke photos-add <bundle-id>
xcrun simctl privacy <UDID> reset photos-add <bundle-id>
```

`photos`、`camera`、`microphone`、`location` などのサービスも同じ形式で指定する。
権限ダイアログをもう一度出したいときは `reset` を使う。

## 実機のコンソール

`MisaのiPhone` はiPhone 17。診断出力が必要なときは、インストール済みのアプリを
コンソールを繋いだ状態で起動する:

```bash
xcrun devicectl device process launch --console --device "MisaのiPhone" <bundle-id>
```

`log collect --device` は `sudo` が必要なので、こちらを優先する。

実機では、一度拒否した権限のダイアログはiOSが二度と出さない。まず設定アプリを確認し、
拒否された権限に対してアプリが「設定を開く」導線を用意しているかも確認する。
