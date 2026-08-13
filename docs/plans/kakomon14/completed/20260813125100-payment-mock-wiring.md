priority: 1

# payment_mockサービスの配線

## 目的

`webapp/go/app_handlers.go`はDBの`settings`テーブルから`payment_gateway_url`を読み込み、
決済APIとして呼び出す実装になっている。現状の`provisioning/`にはpayment_mockサービスを
ビルド・起動する処理が存在せず、決済フローが正しく検証できていない可能性が高い。

## やること

- vendorした`kakomon14/vendor/isucon14/webapp/payment_mock`をビルドし、systemdサービス化する
  (`70-webapp-go.sh`と同様、mise経由の`go build` + 専用systemdユニット)
- `webapp/sql`配下(`2-master-data.sql`または`3-initial-data.sql.gz`)の`payment_gateway_url`初期値を確認し、
  payment_mockサービスの待受先(例: `http://127.0.0.1:12345`)と一致させる
- `env.sh`等、追加で必要な環境変数があれば設定する

## 完了条件

- payment_mockサービスがsystemdで起動していることを確認する
- `/api/initialize`後、ライドの決済フローがエラーなく完了することを確認する
  (ベンチマークの`pass=true`で間接的に確認可)

## 関連

- docs/plans/kakomon14/todo/20260813125000-kakomon14-vendor-migration.md(vendor化が前提)
- docs/plans/kakomon14/completed/20260812181850-webapp-go-build-and-service.md

## 決定事項

- **当初の懸念は誤りだった**: `bench/cmd/run.go`を確認したところ、`--payment-bind-port`の
  デフォルトが`12345`になっており、**bench自体が実行時に自分のプロセス内で決済モックサーバーを
  bindする**設計だった。`webapp/payment_mock`(vendor済み)は別用途(単体でのローカル開発時等)の
  スタンドアロン版で、bench経由のベンチマーク実行では使われない
- 実際にvendor移行後のAMI(`ami-03b12197eea38f286`, m8g.large)でベンチマークを実行し、
  payment_mockサービスを一切配線せずに`pass=true スコア=3240 種別エラー数=map[]`
  (オーナーごとの売上も正常に計上)を確認した。決済フローは追加対応なしで動作する
- 結論として、payment_mockのsystemd化・配線作業は**不要**。タスクをクローズする
