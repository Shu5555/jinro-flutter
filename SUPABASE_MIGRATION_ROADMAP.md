### Supabase移行ロードマップ

**目標:** `jsonbin.io`から`Supabase`へデータ管理を移行し、役職データと参加者データをデータベースで管理・参照できるようにする。

**フェーズ1: SupabaseプロジェクトのセットアップとFlutterへの統合**
1.  **ユーザー作業:** まず、Supabaseプロジェクトを作成し、**プロジェクトのAPI URL**と**Anon Public Key**を提供してください。
2.  Flutterプロジェクトに`supabase_flutter`パッケージを追加します。
3.  `main.dart`でSupabaseクライアントを初期化します。

**フェーズ2: データベーススキーマの定義**
1.  `roles`テーブルのスキーマを定義します（例: `role_name`, `faction`, `category`, `ability`, `fortune_telling_result`など）。
2.  `assignments`テーブルのスキーマを定義します（例: `bin_id` (共有ID), `player_name`, `role_id`, `password`, `created_at`）。

**フェーズ3: 役職データの管理**
*   **相談:** 現在のJSONファイルにある役職データをSupabaseデータベースに移行するか、引き続きローカルアセットとして使用するかを決定する必要があります。
    *   **私の推奨:** 役職データもSupabaseの`roles`テーブルに移行することをお勧めします。これにより、役職データの一元管理が可能になり、以前の問題であった`分類`フィールドの欠落もデータベース側で修正・管理できるようになります。

**フェーズ4: 参加者割り当てデータの管理**
1.  `JsonBinService`を`SupabaseService`に置き換え、`PlayerAssignment`データをSupabaseに保存・ロードするようにリファクタリングします。
2.  `GmToolScreen`と`PlayerScreen`を更新し、共有機能に`SupabaseService`を使用するように変更します。

**フェーズ5: UIの調整**
1.  データロード/保存の変更を反映するために、UIコンポーネントを調整します。

---

**次のステップ:**

このロードマップで進めてよろしいでしょうか？特に、**フェーズ1のSupabase API URLとAnon Keyの提供**、および**フェーズ3の役職データをSupabaseに移行するかどうか**について、ご意見をお聞かせください。