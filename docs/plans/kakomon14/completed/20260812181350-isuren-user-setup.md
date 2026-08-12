priority: 10

# isurenユーザーのセットアップ(20-user.sh)

## 目的

Ansibleの`roles/isucon-user`相当を、`isucon`→`isuren`に読み替えて再現する。本番の`isucon`ユーザー(パスワードなしsudo)はisurenに読み替える方針(bastion自体のユーザー(user101予定)とは別物)。

## やること

- `isuren`グループ/ユーザーを作成する(uid/gid 1100)
- ホームディレクトリ`/home/isuren`を`0755`にする(nginxがroot配下を辿るために必須)
- sudoersに`isuren ALL=(ALL) NOPASSWD:ALL`を`/etc/sudoers.d/99-isuren-user`として配置する(配置前に`visudo -cf`で検証する)
- `env.sh`を`/home/isuren/env.sh`に配置する(中身はAnsible版から変更しない。`ISUCON_DB_*`等の識別子は据え置き)

## 完了条件

`runuser -u isuren -- sudo -n true` が通ること

## 決定事項

- パスワード設定(元Ansibleの`password: isucon`、平文でほぼ無効な実装)と`.ssh`ディレクトリ作成/`authorized_keys`削除は意図的に未対応。bastionはSSHキー/sudo経由の運用でisurenへのパスワードログインを想定しないため
- `scripts/kakomon14/20-user.sh`をbastion上で2回実行し、1回目全項目changed→2回目全項目already up to dateを確認済み
- `sudo runuser -u isuren -- sudo -n true`が`OK`を返すことを確認済み(完了条件を満たす。`runuser`はroot権限が必要なため`sudo`を付けて実行する)

## 関連

- docs/isuren-kakomon-strategy.md
