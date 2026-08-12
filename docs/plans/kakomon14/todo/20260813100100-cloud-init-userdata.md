priority: 2

# cloud-init(UserData)化

## 目的

bashスクリプトでの試行錯誤(bastion上での手動実行)から、Packerビルド時に自動実行されるcloud-init(UserData)へ移行する。

## やること

- cloud-config(YAML)の`write_files`で、移設した`isuren-kakomon/kakomon14/provisioning/`配下の全スクリプト(`lib.sh`〜`95-deploy-helper.sh`)を配置する
- `runcmd`で`all.sh`を1本呼ぶ形にする。個々のスクリプトをruncmdに列挙せず1本化するのは、これまで検証してきた`all.sh`の実行順序・冪等性をそのまま活かすため
- `ENABLE_TLS`のデフォルト値を確定する(本番相当の動作確認をするため`true`が妥当と見込むが、Packerのvariableとして外から渡せるようにするかも検討する)
- cloud-initのログ(`/var/log/cloud-init-output.log`)でどこまでプロビジョニングの進捗が追えるか確認する

## 完了条件

Packerのshell provisionerではなく、`user_data`経由のcloud-initでプロビジョニングが完走すること(この時点ではPackerの本番ビルドまでは行わず、EC2起動確認レベルでよい)

## 関連

- docs/isuren-kakomon-strategy.md
- docs/plans/kakomon14/todo/20260813100000-migrate-scripts-to-isuren-kakomon.md
