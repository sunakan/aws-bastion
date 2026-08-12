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

## 決定事項

- `isuren-kakomon/kakomon14/cloud-init/generate-user-data.py`を新規作成した。`provisioning/`配下のファイル一覧(`lib.sh`〜`95-deploy-helper.sh`、`mise.kakomon14.toml`/`.lock`、`pnpm-workspace.kakomon14.yaml`。`README.md`はプロビジョニング実行に不要なため対象外)を読み込み、`write_files`(配置先`/opt/kakomon14/provisioning/`)+`runcmd`(`all.sh`を1本呼ぶ)形式のcloud-config(`user-data.yaml`)を生成する。provisioning/側の内容が正になるよう、user-data.yamlは直接編集せず都度再生成する運用とした
- `ENABLE_TLS`は`true`で固定した。`90-nginx.sh`の`generate_tls_cert`は自己署名証明書を生成するのみでネットワーク到達性(Let's Encrypt等)を要さないため、外部からvariableで渡せるようにする対応は不要と判断した
- EC2 UserDataのサイズ制限(base64エンコード後16KB)への対応: 生成されたuser-data.yamlは生サイズ32,519バイトだが、gzip圧縮すると9,256バイト、さらにbase64エンコードすると12,345バイトとなり制限内に収まることを確認した
- 実機確認は、素のUbuntu AMI(`ami-0df1235688731e6cc`、Packer側と同条件のフィルタで検索)に対し、`verify-ami.yaml`をベースにした一時CloudFormationスタックでEC2を起動して行った。当初`verify-ami.yaml`にUserDataパラメータを追加する案を試したが、CloudFormationパラメータには4096文字の上限がありgzip+base64後(12,345文字)でも収まらなかったため撤回(`verify-ami.yaml`自体への変更はコミットしていない)。代わりにUserDataをテンプレート本体に直接埋め込んだ一時テンプレート(`/tmp`配下、リポジトリ外)を生成してデプロイする方式で検証した
- SSM経由で`/var/log/cloud-init-output.log`を確認し、`10-base.sh`〜`95-deploy-helper.sh`の各`done`ログ→`[kakomon14] all.sh: done`→`Cloud-init v. 26.1-0ubuntu3~26.04.1 finished ...`(Up 136.88 seconds)、`cloud-init status --long`の`errors: []`まで到達することを確認した。プロビジョニング進捗はこのログで十分追えると判断した
- インスタンスタイプ`t4g.small`でのOOM懸念(過去`pnpm install`でOOM killerが発動した実績あり、aws-bastion/CLAUDE.md参照)について、`dmesg`でOOM killerのログがないこと、および`free -h`でメモリに余裕(981Mi使用/1.8Gi中、325Mi free+688Mi buff/cache)があることを確認した。今回のプロビジョニング内容では問題は再現しなかった
- 検証後、CloudFormationスタック・一時テンプレート・base64エンコード済みファイルはすべて削除済み
