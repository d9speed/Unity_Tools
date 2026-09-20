# D9speed Unity Tools

D9speedの公開Unity Editor拡張の案内ページとVPM一覧です。

- 案内ページ: https://d9speed.github.io/Unity_Tools/
- VCC / ALCOMの登録URL: https://d9speed.github.io/Unity_Tools/index.json
- パッケージのソース: https://github.com/d9speed/unity_editor_tools

## 構成

- `index.html` / `styles.css`: 黒背景・白文字の案内ページ。パッケージ名とツール名から説明へ移動できます。JavaScriptや外部ライブラリ、ビルド処理は不要です。
- `index.json`: 公開パッケージ一覧。
- `tools/build_listing.ps1`: 配布ZIPから一覧を生成するPowerShell 7用スクリプト。

GitHub Pagesは`main`ブランチのルートを配信します。認証なしで利用する公開パッケージのみを収録します。

## 更新手順

1. `unity_editor_tools`側でバージョンと配布URLを更新し、ZIPを生成・検証します。
2. 対応するタグのGitHub ReleaseへZIPを公開します。
3. `tools/build_listing.ps1 -artifacts_path <ZIPとpackage_artifacts.jsonのフォルダ>`を実行します。ソースリポジトリが隣にない場合は`-package_repo_path`で指定します。
4. 一覧の差分を確認し、`index.json`を更新します。
5. 公開URLで一覧とZIPを取得し、VCC / ALCOMで導入を確認します。

既存バージョンのダウンロードURLとZIPは維持します。同じバージョンのZIPハッシュが変わる場合、一覧生成スクリプトは停止します。新しいパッケージを追加するときは`public_package_ids`と案内ページのツール一覧を明示的に更新してください。

VPM一覧の仕様は[VRChat公式ドキュメント](https://vcc.docs.vrchat.com/vpm/repos/)、リポジトリ登録方法は[Community Repositories](https://vcc.docs.vrchat.com/guides/community-repositories/)を参照してください。

## ライセンス・連絡先

[MIT License](LICENSE)

d09pseed@gmail.com
