priority: 3

# scripts/kakomon14/をisuren-kakomon/kakomon14/へ移設する

## 目的

bastion上で固めたプロビジョニングスクリプトを、Packer/cloud-init側のリポジトリ(`isuren-kakomon/`、aws-bastionとは別のgitリポジトリ)に持ち込み、次フェーズの作業土台にする。

## やること

- `aws-bastion/scripts/kakomon14/`配下の全ファイル(`lib.sh`、`10-base.sh`〜`95-deploy-helper.sh`、`mise.kakomon14.toml`/`.lock`、`pnpm-workspace.kakomon14.yaml`、`README.md`)を`isuren-kakomon/kakomon14/provisioning/`(仮)にコピーする
- コピー後、`SCRIPT_DIR`相対参照のパスがそのまま機能することを確認する
- `aws-bastion/scripts/kakomon14/`自体は試行錯誤の記録として残すか削除するかを判断する(削除する場合は各completedタスクのファイルパス言及との整合性に注意)

## 完了条件

`isuren-kakomon/kakomon14/provisioning/`配下から`10-base.sh`〜`95-deploy-helper.sh`が揃っており、bastion上に手動でコピーして`sudo bash all.sh`を実行しても動作すること

## 関連

- docs/isuren-kakomon-strategy.md
- docs/plans/kakomon14/completed/20260812182550-cloud-init-handoff-prep.md
