# AGENTS.md

## このリポジトリでやろうとしていること

開発用EC2踏み台(bastion)上で、ISUCON14の環境を再現する。
`development/compose-go.yml` を使い、Webアプリ含めて全部Dockerコンテナで動かす方針。

## AIが参照すべきローカルの場所

- `/Users/user01/works/github.com/isucon/isucon14`: ISUCON14リポジトリのローカルコピー。
  AIが構造を把握するための参照専用。実際のビルド・起動・デバッグ作業はubuntu側(EC2上の同じリポジトリ)で行うため、
  このローカルコピーに対してコマンドを実行したり、ファイルを編集したりしない。

## コマンド実行の方針

- isucon14関連の作業はローカルで先走って実行しない(mise install/lock、docker composeなどをローカルで試さない)。
  実行が必要な場合はubuntu側で行う(`mise connect`等でEC2に入って作業する、またはユーザー自身が実行する)。
- bastion stackが複数存在する場合に一覧から選ぶ操作(`down-bastion`/`connect`タスクのfzf選択)は、
  AIからは対話操作できないため、awsコマンドで直接操作してよい。
  例: `aws cloudformation describe-stacks --query "Stacks[?starts_with(StackName, 'aws-bastion')].StackName" --output text`
  で一覧取得し、末尾のタイムスタンプが最大(一番新しい)ものを選ぶ。
