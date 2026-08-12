# AGENTS.md

## このリポジトリでやろうとしていること

開発用EC2踏み台(bastion)上で、ISUCONの過去問を再現
まず`development/compose-go.yml` を使い、Webアプリ含めて全部Dockerコンテナで動かす方針
その次にVM自体で動くのに何が必要かを洗い出し、cloud-initとmiseで動かす

## AIが参照すべきローカルの場所

例: isucon14の場合
- `/Users/user01/works/github.com/isucon/isucon14`: ISUCON14リポジトリのローカルコピー。
  AIが構造を把握するための参照専用。実際のビルド・起動・デバッグ作業はubuntu側(EC2上の同じリポジトリ)で行うため、
  このローカルコピーに対してコマンドを実行したり、ファイルを編集したりしない。

## コマンド実行の方針

- isuconN関連の作業はローカルで先走って実行しない(mise install/lock、docker composeなどをローカルで試さない)。
  実行が必要な場合はubuntu側で行う(`mise connect`等でEC2に入って作業する、またはユーザー自身が実行する)。
- bastion stackが複数存在する場合に一覧から選ぶ操作(`down-bastion`/`connect`タスクのfzf選択)は、AIからは対話操作できないため、awsコマンドで直接操作してよい。
  例: `aws cloudformation describe-stacks --query "Stacks[?starts_with(StackName, 'aws-bastion')].StackName" --output text`
  で一覧取得し、末尾のタイムスタンプが最大(一番新しい)ものを選ぶ。

## このbastionの位置づけ

このリポジトリ(cloudformation.yaml)はお試し用の使い捨て環境であり、AMI化の対象ではない。
過去問をGo版AMIとして焼く作業は、別の場所で新たに行う想定(このbastionを段階的に発展させるものではない)。

## 過去問(isucon14等)をGo版AMIとして焼く方針

- Ansible/Taskfileはそのまま使わず、cloud-init(UserData)とmiseに置き換える
- 言語ランタイムのインストール(xbuild相当)はmiseで代替する
- 対象言語はGoのみに絞る(他言語のセットアップは不要)
- 本番の`isucon`ユーザー(パスワードなしsudo)は`isuren`に読み替える。bastion自体のユーザー(user101予定)とは別物

## 見逃しがちな注意点(isucon14版)

- `bench/Dockerfile`はISUCON運営限定のプライベートECRイメージ(supervisor)に依存しており一般環境ではビルドできない。benchはホストで直接`go run`する
- `development/compose-go.yml`はfrontendの事前ビルド(`pnpm run build`)が前提。nginxが`frontend/build/client`をマウントするだけでビルドはしない
- ベンチ実行時の`context deadline exceeded`多発は、インスタンスのリソース不足(CPU)が原因のことがある。アプリのバグかリソース不足かの切り分けが必要
