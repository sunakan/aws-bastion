priority: 9

# webapp(Go)のビルドとsystemd化(70-webapp-go.sh) 【マイルストーンA】

## 目的

Ansibleの`roles/webapp/tasks/go.yaml`相当を再現し、Goアプリを実際に動く状態にする。ここまでできれば、nginx/frontendなしでもベンチのPrepare(初期化+初期データ検証)まで到達できるはず。

## やること

- `go build -o /home/isuren/webapp/go/isuride -ldflags "-s -w"` を実行する(cwd: `/home/isuren/webapp/go`)
- `isuride-go.service`をisuren版(User/Group/WorkingDirectory/EnvironmentFileのパスを`/home/isuren/...`に変更、サービス名・ExecStartは据え置き)として`/etc/systemd/system/`に配置する
- `WorkingDirectory=/home/isuren/webapp/go`を必ず設定する(`/api/initialize`が相対パス`../sql/init.sh`を呼ぶため、ここがずれると失敗する)
- `systemctl daemon-reload && systemctl enable --now isuride-go`

## 完了条件

`cd isucon14/bench && go run . run --target http://localhost:8080 -s -t 0` が成功すること

## 関連

- docs/isuren-kakomon-strategy.md
