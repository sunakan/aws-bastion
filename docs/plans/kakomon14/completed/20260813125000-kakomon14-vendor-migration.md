priority: 1

# kakomon14をvendor構成に移行(50-source.shのgit clone方式を廃止)

## 目的

現状`kakomon14/provisioning/50-source.sh`は、AMI焼き(provisioning)のたびに本家isucon14リポジトリを
特定コミットでgit cloneしている。isuren-mondai側で決めた設計
(過去問ごとに`vendor/<取り込み元リポジトリ名>/`を置き、コードを常設でgit管理する)に合わせて移行する。
AGENTS.mdに追記した「過去問コードの取り込み(vendor)方針」の実装フェーズ。

## やること

- `kakomon14/vendor/isucon14/`を作成し、以下を取り込む(vendor時点のcommit: `53f8b627e040c30ebec600457c6c97da008b84b0`)
  - `webapp/go`
  - `webapp/sql`
  - `webapp/payment_mock`
  - `webapp/openapi.yaml`
  - `frontend`
- `kakomon14/vendor/isucon14/LICENSE`に本家のLICENSE(MIT, Copyright (c) 2024 ISUCON14 Contributors)をそのままコピーする
- `kakomon14/vendor/isucon14/NOTICE.md`に取り込み元URL・commit hash・持ち込んだ範囲(他言語ディレクトリ・bench等は含まない)を記録する
- `provisioning/50-source.sh`をgit clone方式から、vendorされたコードをisurenユーザーのホームに配置する方式に置き換える
  - 現行はシンボリックリンク(`~/webapp -> ~/isucon14/webapp`)方式。vendorはisuren-mondaiのgit管理下にあり、
    frontendビルド成果物(`webapp/public/`)の書き込み先としても使われるため、書き込み可能な配置方法を検討する

## 完了条件

- `kakomon14/vendor/isucon14/`配下にwebapp(go/sql/payment_mock/openapi.yaml)とfrontendが揃っている
- `mise build-kakomon14`でAMIビルドが成功し、外部ネットワーク(本家isucon14リポジトリへのgit clone)に
  依存せずvendorされたコードだけでisuride-goが起動する
- ベンチマーク(`go run . run --target ... -t 60`)が`pass=true`になる

## 関連

- AGENTS.md「過去問コードの取り込み(vendor)方針」
- docs/isuren-mondai-strategy.md
- docs/plans/kakomon14/completed/20260812181650-source-checkout.md(旧: git clone方式の元実装)
- docs/plans/kakomon14/completed/20260812182050-frontend-build.md
- docs/plans/kakomon14/completed/20260813125100-payment-mock-wiring.md

## 決定事項

方針は「編集する可能性があるもの(go/frontend/payment_mock/bench)はvendorして自分で管理する、
読み取り専用データ(webapp/sql・frontend/public)は本家からsparse-checkoutで直接取得する」に決定。
実装・検証の過程で以下の問題を発見し、修正した。

- **取得方式はcurl+tarではなくgit sparse-checkout(cone mode)を採用**。GitHubのcodeload
  archiveエンドポイントはリポジトリ全体のtarballしか生成できずサブパスで絞れないため、
  過去問が増えるほど転送量が増える。git sparse-checkout(`--filter=blob:none`)なら
  必要なサブツリーだけ転送できる
- **mise.tomlの誤混入**: cone modeはリポジトリルート直下のファイルも自動的に含むため、
  isuren-mondai自身をvendor取得元にすると`mise.toml`(無関係なPacker/AWSタスク定義)も
  一緒に取得されてしまい、miseの「untrusted config」エラーでAMIビルドが失敗した。
  取得後に明示的に除去するステップを追加して解決
- **gitignore衝突による19ファイルの欠落**: (1)macOSのグローバルgitignore(`Icon`ルール)が
  大文字小文字を区別しないファイルシステム上で`frontend/app/components/icon/`と衝突、
  (2)vendorした`bench/.gitignore`自身の`bench`ルールが`services/bench/`という無関係な
  ディレクトリと衝突。どちらも`git add`時に静かに無視され、frontendビルドが
  `Could not resolve "../../icon/chair"`で失敗して発覚した。本家ツリーとの`diff`/`comm`による
  突き合わせ確認で発見し、無視ルールを無効化して追加した
- **symlinkの相対パス解決バグ**: 当初`~/webapp`を実ディレクトリにして子要素ごと
  (go/payment_mock/openapi.yaml/sql)に個別symlinkを張る設計にしたが、systemdの
  `WorkingDirectory=~/webapp/go`はsymlinkの実体側パスにchdirするため、webapp/goプロセスから見た
  相対パス`../sql`はvendorツリー内の(存在しない)webapp/sqlに解決され、`/api/initialize`が
  `fork/exec ../sql/init.sh: no such file or directory`で失敗した。`~/webapp`を単一symlinkに戻し、
  sqlはvendorツリーの内側(webapp/goと同じ実ディレクトリ)にsymlinkを差し込む方式に変更して解決
  (frontend/publicと同じ方式に統一)
- **payment_mockのsystemd化は不要と判明**: 当初「payment_gateway_urlの配線が必要」と懸念していたが、
  `bench/cmd/run.go`の`--payment-bind-port`(デフォルト12345)から、bench自体が実行時に
  自分のプロセス内で決済モックサーバーをbindする設計と分かった。vendorした`webapp/payment_mock`は
  別用途(スタンドアロンのローカル開発用)で、bench経由の実行では使われない
- 最終的にAMI(`ami-03b12197eea38f286`, 検証インスタンス m8g.large)でベンチマークを実行し、
  `pass=true スコア=3240 種別エラー数=map[]`を確認して完了条件を満たした
