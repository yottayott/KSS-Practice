# Kirby Super Star Practice Hack

[日本語](#日本語) | [English](#english)

---

# 日本語

星のカービィ スーパーデラックス（日本版 1.0）の Any% RTA 用のプラクティスハック。

元のプラクティスハック: https://github.com/bluebarker/KSS-Practice

## ビルド

1. このリポジトリをダウンロードする（緑の「Code」ボタン → Download ZIP など）。
2. [asar 2.0](https://github.com/RPGHacker/asar/tree/asar_2_beta)（`asar_2_beta` ブランチ）をビルドし、`asar.exe`（Unix では `asar`）をこのフォルダに置く。asar 1.x ではビルドできない。
3. 星のカービィ スーパーデラックスの **日本版 1.0** の ROM をこのフォルダに置き、名前を `original.sfc` にする。
4. 次のどちらかを実行する。

| 実行するもの                                               | できる ROM          | メニューの言語 |
| ---------------------------------------------------- | ---------------- | ------- |
| `make_file.bat`（Windows）/ `make_file.sh`（Unix）       | `patched.sfc`    | 日本語     |
| `make_file_en.bat`（Windows）/ `make_file_en.sh`（Unix） | `patched_en.sfc` | 英語      |

自己ベストの記録には SRAM 256KB が必要。

## ゲーム中の操作

| 操作                        | 内容                              |
| ------------------------- | ------------------------------- |
| R + Start                 | 練習メニューを開く / 閉じる                 |
| R + Select / L + Select   | ステートの保存 / 読み込み                  |
| R + X                     | 部屋をやり直す（部屋に入ったときの能力・体力・乱数などに戻す） |
| L + R + X                 | 今の状態を記録し直して部屋をやり直す              |
| L + R + B                 | 部屋ループのオン / オフ                   |
| Select + X                | 前回のワープをやり直す                     |
| L + R + Y                 | フリームーブ                          |
| A + L / A + R / A + L + R | 能力を出す / 切り替える                   |

## メニュー

| 項目        | 内容                                     |
| --------- | -------------------------------------- |
| ワープ メニュー  | 部屋へワープする（下の「ワープ」に詳細）                   |
| ワープ のうりょく | ワープのときにセットする能力                         |
| ワープ らんすう  | ワープのときにセットする乱数                         |
| げんざい らんすう | 今の乱数をすぐ変える                             |
| HUD       | HUD の切り替え（タイマー → らんすう → しょりおち → しょうさい） |
| タイトル とばす  | タイトル画面を飛ばす（下の「起動」に詳細）                  |
| ぎんが のうりょく | 銀河にねがいをの能力（初期値は Any%）                  |
| カービィ いろ   | カービィの色                                 |
| オーディオ     | ステレオ → モノラル → オフ                       |
| SA1       | SA-1 の調整                               |
| クレジット     | プラクティスハックのクレジット                        |

### ワープ

Any% のルート上の全128部屋にワープできる。区間の一覧には部屋ごとの自己ベストが出る。

| ボタン    | 区間の一覧での動作                  |
| ------ | -------------------------- |
| 左右     | 部屋を選ぶ                      |
| A      | ワープ のうりょく / らんすう をセットしてワープ |
| Y      | 何もセットせずにワープ                |
| L / R  | 前 / 次のサブゲームの一覧へ            |
| Select | 右に出ている部屋の自己ベストを消す          |

メタナイト戦は、直接ワープすると不具合が出るため、一つ前の部屋から入る。

### ワープ のうりょく / ワープ らんすう

- **のうりょく**: セットしない / すっぴん / ジェット / ハンマーと ウィリー / プラズマ / じぶんで きめる（カービィの能力・ヘルパー・ウィリーに乗るかを左右で選ぶ）
- **らんすう**: セットしない / 221 189（リセットあと）/ 118 013（クジラあと）/ 031 005（クラッシュあと）/ あたいで きめる / カウントで きめる

### げんざい らんすう

カウントで きめる（119 119 から何回進めたか）/ あたいで きめる / リセットあと / デモあと / 1・10・100 かい すすめる。

## HUD

洞窟・ダイナブレイド・メタナイト・銀河ではサブゲームごとに決まった場所、ほかのサブゲームでは残機欄に出る。

### タイマー

- 暗転が明けた最初のフレームから、部屋ごとのタイムを `SS cc`（秒・1/100秒、99.99 まで）で測る。
- 暗転が始まった瞬間のタイムを、明るくなってから1.5秒表示する。
- 処理落ちも含めた実時間。ポーズ中は止まらず、メニューを開いている間と、ボタン待ちのメタナイトのセリフの間は止まる。
- ステートをロードすると、セーブしたときのタイムに戻る。

### らんすう / しょりおち

- **らんすう**: 今の乱数とそのカウント。
- **しょりおち**: その部屋での処理落ちのフレーム数（999 まで）。

### しょうさい

HUD 全体を次の表示に置き換える。

```
 ####  TIME 0:12.34    RNG 221 189
 ####  PB   0:11.80        CNT 00001
 ####  X 01A3.80  VX +02.87
 ####  Y 00F0.00  VY -07.00
 ####  LAG 12                BOSS 120
（####：能力の絵）
```

- **X / Y**: カービィの座標（16進数、`.` の後ろはサブピクセル）。ウィリーに乗っている間はウィリーの値。
- **VX / VY**: 前のフレームから実際に動いた量の **2倍**（10進数、右・下がプラス）。例：1フレームに 4.906 ピクセル動くと `+09.81`。
- **BOSS**: ボスの体力（いなければ `-`）。
- メタナイトのセリフが HUD の場所に出ている間は、ゲームの HUD に戻る。

### RNGカウント

119 119 から乱数が何回進んだか（119 119 が 0、221 189 が 1、65534 でまた 119 119）。85 085 や 170 170 など、119 119 から届かない値では出ない。

### 自己ベスト

- 部屋ごとの自己ベストを記録し、タイマーのとなりの行と区間の一覧に出す。
- 記録するのは、ルートの入口から入り（R + X や部屋ループも含む）、ルートの次の部屋へ出たときだけ。ステージの最後の部屋は、ステージの終わりで記録する。
- フリームーブ・能力のホットキー・ステートのロードを使ったときと、カービィがやられたときは記録しない。

## 部屋ループ（L + R + B）

オンのときに扉に入ると、次の部屋へ行かずに、その部屋に入ったときの状態（能力・体力・乱数・位置）からやり直す。電源を入れたときはオフ。

## 前回のワープをやり直す（Select + X）

最後にワープした部屋へ、同じ設定でもう一度ワープする。

## 起動

- **タイトル とばす** がオンだと、電源を入れたときにタイトル画面を飛ばして、ファイル1のコルクボードから始まる。初期値はオフ。
- オンのとき、リセット後の乱数は 221 189（通常はタイトル画面を最速で飛ばしても乱数が1回進むため）。
- ファイル1は、電源を入れるたびに100%データになる（モードセレクトのカーソル位置は残る）。

## 元のハックからの変更

- **外したもの**: ボスを倒すときの点滅の切り替え、メニューの中での言語の切り替え（言語はビルドで選ぶ）、ボスワープ
- **直した不具合**:
  - ステートのロードで止まる不具合（ポーズ中・繰り返し・別のモードからのロード）
  - R + X のあとウィリーに乗っているときの動きの不具合
  - メニュー・銀河のマップ・SA-1 調整・部屋のやり直しまわりの細かい不具合
- **軽くしたもの**: ステートの保存 / 読み込み、毎フレームの処理
- **好みで変えたもの**:
  - メニューの背景と文字の色
  - 銀河にねがいをのポーズ画面で、1P / 2P のカーソルが点滅しない（画面焼け対策）

---

# English

A practice hack for Kirby Super Star (Japanese 1.0, *Hoshi no Kirby Super Deluxe*) Any% speedruns.

Original practice hack: https://github.com/bluebarker/KSS-Practice

## Building

1. Download this repository (green "Code" button → Download ZIP, for example).
2. Build [asar 2.0](https://github.com/RPGHacker/asar/tree/asar_2_beta) (the `asar_2_beta` branch) and put `asar.exe` (`asar` on Unix) in this folder. asar 1.x cannot build it.
3. Put a **Japanese 1.0** ROM of the game in this folder, named `original.sfc`.
4. Run one of these:

| Run                                                     | ROM              | Menu language |
| ------------------------------------------------------- | ---------------- | ------------- |
| `make_file.bat` (Windows) / `make_file.sh` (Unix)       | `patched.sfc`    | Japanese      |
| `make_file_en.bat` (Windows) / `make_file_en.sh` (Unix) | `patched_en.sfc` | English       |

The room PBs need 256KB of SRAM.

## Controls in game

| Buttons                   | Action                                                                       |
| ------------------------- | ---------------------------------------------------------------------------- |
| R + Start                 | Open / close the practice menu                                               |
| R + Select / L + Select   | Save / load state                                                            |
| R + X                     | Restart the room (back to the ability, health, RNG etc. it was entered with) |
| L + R + X                 | Record the current state and restart the room from it                        |
| L + R + B                 | Room loop on / off                                                           |
| Select + X                | Repeat the last warp                                                         |
| L + R + Y                 | Free movement                                                                |
| A + L / A + R / A + L + R | Give / change abilities                                                      |

## Menu

| Item            | What it does                                        |
| --------------- | --------------------------------------------------- |
| Warp Menu       | Warp to a room (see "Warps")                        |
| Warp Ability    | The ability set by a warp                           |
| Warp RNG        | The RNG set by a warp                               |
| RNG Now         | Change the current RNG right away                   |
| HUD             | Switch the HUD (Timer → RNG → Lag → Detail)         |
| Skip Title      | Skip the title screen (see "Power on")              |
| MWW Abilities   | The abilities of Milky Way Wishes (Any% by default) |
| Kirby Color     | Kirby's color                                       |
| Audio           | Stereo → Mono → Off                                 |
| SA-1 Adjustment | SA-1 adjustment                                     |
| Credits         | The credits of the practice hack                    |

### Warps

Warp to any of the 128 rooms on the Any% route. The segment lists show the PB of each room.

| Button       | In a segment list                     |
| ------------ | ------------------------------------- |
| Left / Right | Choose the room                       |
| A            | Warp, setting Warp Ability / Warp RNG |
| Y            | Warp without setting anything         |
| L / R        | Previous / next sub-game              |
| Select       | Clear the PB of the room shown        |

The Meta Knight fight is entered from the room before it, as warping straight to it causes problems.

### Warp Ability / Warp RNG

- **Ability**: Don't Set / Normal / Jet / Hammer + Wheelie / Plasma / Custom (Kirby's ability, the helper and riding the Wheelie, chosen with Left / Right)
- **RNG**: Don't Set / 221 189 Reset / 118 013 Whale / 031 005 Crash / By Value / By Count

### RNG Now

Set RNG Count (advances from 119 119) / Set RNG Value / After Reset RNG / After Demo RNG / Advance RNG x1, x10, x100.

## HUD

In Great Cave Offensive, Dyna Blade, Revenge of Meta Knight and Milky Way Wishes it is at a fixed place per sub-game; in the other sub-games it is in the lives box.

### Timer

- Times each room as `SS cc` (seconds, 1/100 s, up to 99.99) from the first frame after the fade.
- The time when a fade starts is shown for 1.5 s after the screen lights up.
- Real time, lag included. It does not stop on pause; it stops while the menu is open and during Meta Knight dialogues that wait for a button.
- Loading a state brings back the time of the save.

### RNG / Lag

- **RNG**: the current RNG and its count.
- **Lag**: lag frames in the room (up to 999).

### Detail

Replaces the whole HUD with this:

```
 ####  TIME 0:12.34    RNG 221 189
 ####  PB   0:11.80        CNT 00001
 ####  X 01A3.80  VX +02.87
 ####  Y 00F0.00  VY -07.00
 ####  LAG 12                BOSS 120
(####: the ability picture)
```

- **X / Y**: Kirby's position (hex, subpixels after the `.`). The Wheelie's while riding it.
- **VX / VY**: **twice** the distance actually moved since the last frame (decimal, right / down are plus). e.g. 4.906 pixels a frame shows `+09.81`.
- **BOSS**: the boss's health (`-` without a boss).
- While a Meta Knight dialogue is where the HUD is, the game's HUD comes back.

### RNG count

How many times the RNG advanced from 119 119 (119 119 is 0, 221 189 is 1, after 65534 it is 119 119 again). Values that cannot be reached from 119 119, such as 85 085 and 170 170, show no count.

### Room PBs

- The PB of each room, shown on the row next to the timer and in the segment lists.
- A time counts only when the room was entered from its route entrance (R + X and the room loop included) and left to the next room of the route. The last room of a stage counts at the end of the stage.
- Not counted: free movement, the ability hotkeys or a state load were used, or Kirby died.

## Room loop (L + R + B)

When it is on, a door restarts the room with the state it was entered with (ability, health, RNG, position) instead of going on. Off after power on.

## Repeat the last warp (Select + X)

Warps again to the room of the last warp with the same settings.

## Power on

- With **Skip Title** on, the game skips the title screen at power on and starts on the corkboard of file 1. Off by default.
- When it is on, the RNG after a reset is 221 189 (normally, skipping the title screen as fast as possible still advances it once).
- File 1 becomes a 100% file at every power on (the mode select cursor is kept).

## Changes from the original hack

- **Removed**: the boss screen flashing option, the language choice in the menu (the language is chosen when building), the boss warps
- **Bugs fixed**:
  - Freezes on state loads (while paused, repeated loads, loads from another mode)
  - Wrong Wheelie riding movement after R + X
  - Small bugs in the menu, the Milky Way Wishes map, the SA-1 adjustment and room restarts
- **Lighter**: state saves / loads, the work done every frame
- **Changed**:
  - The menu background and text colors
  - The 1P / 2P cursors on the Milky Way Wishes pause screen do not blink (personal burn-in prevention)
