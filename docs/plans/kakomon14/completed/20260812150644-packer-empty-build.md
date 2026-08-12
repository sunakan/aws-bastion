priority: 8

# Packerでほぼ空の状態で1周させる

## 目的

AMI化→起動のパイプラインが通ることを早期に確認する。
後で問題が起きたときに「ビルド基盤の問題」か「プロビジョニング内容の問題」かを切り分けやすくするため。

## やること

- `provisioning/packer` (isucon14側)の中身を確認し、構成を把握する
- ほぼ何もしない(base AMIのままpackerでAMI化するだけ)状態で最小構成のPacker定義を作る
- 1回ビルドを通す
- 生成されたAMIから実際にEC2を起動し、起動できることを確認する

## 関連

- docs/isuren-kakomon-strategy.md
