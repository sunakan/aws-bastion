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

## 決定事項

- 移設先のディレクトリ名は`isuren-kakomon/kakomon14/provisioning/`で確定した(タスク起票時点の「仮」表記を確定)。`isuren-kakomon/kakomon14/`配下には既にPacker側の`packer/empty.pkr.hcl`があり、provisioning用スクリプトとPackerテンプレートを並列に分ける構成とした
- コピーはSCRIPT_DIR相対参照のみで構成されているファイル群だったため、単純な全ファイルコピーで完結した。コピー元(`aws-bastion/scripts/kakomon14/`)とのdiffは差分ゼロ(完全一致)
- `aws-bastion/scripts/kakomon14/`は削除せず残す方針とした。試行錯誤の記録として残し、各completedタスクのファイルパス言及ともそのまま整合する
- 実機確認は、既存のbastionスタック(`aws-bastion-20260812104222`、instance-id `i-098408d4a4b7ddd19`)上でSSM経由により実施した。`aws-bastion/scripts/kakomon14/`を`/tmp/provisioning-verify/`へ複製し、そこで`sudo bash all.sh`を実行して`all.sh: done`まで完走(Status: Success)することを確認した。冪等性のある各サブスクリプトも正常に「already up to date」等で完了しており、独立したディレクトリ配置でも動作することを確認できた。検証後、`/tmp/provisioning-verify/`は削除済み
- `isuren-kakomon/`側への変更(新規`kakomon14/provisioning/`)は`add: kakomon14のプロビジョニングスクリプトをisuren-kakomonへ移設`(コミットc98c979)としてコミット済み
