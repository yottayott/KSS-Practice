# Kirby Super Star Practice Hack

[日本語](#日本語) | [English](#english)

---

# 日本語

星のカービィ スーパーデラックス（日本版 1.0）の Any% RTA のための練習ハックです。
ルート上の128部屋に直接ワープして、部屋ごとのタイム・乱数・自己ベストを見ながら反復練習できます。

元の練習ハック: https://github.com/bluebarker/KSS-Practice

## ビルド

1. このリポジトリをダウンロードします（緑の「Code」ボタン → Download ZIP など）。
2. [asar](https://github.com/RPGHacker/asar) を用意して、`asar.exe`（Unix では `asar`）をこのフォルダに置きます。
3. 星のカービィ スーパーデラックスの **日本版 1.0** の ROM をこのフォルダに置き、`original.sfc` という名前にします。
4. 次のどちらかを実行します。

| 実行するもの                                               | できる ROM          | メニューの言語 |
| ---------------------------------------------------- | ---------------- | ------- |
| `make_file.bat`（Windows）/ `make_file.sh`（Unix）       | `patched.sfc`    | 日本語     |
| `make_file_en.bat`（Windows）/ `make_file_en.sh`（Unix） | `patched_en.sfc` | 英語      |

PowerShell で直接ビルドする場合:

```powershell
Copy-Item -Force original.sfc patched.sfc
.\asar.exe patch.asm patched.sfc
# 英語メニュー
Copy-Item -Force original.sfc patched_en.sfc
.\asar.exe -Dmenu_english=1 patch.asm patched_en.sfc
```

- 日本版 1.0 以外の ROM では動きません。ROM は同梱していません。
- 自己ベストの記録には SRAM 256KB が必要です（使えない環境では自己ベストだけが動きません）。

## ゲーム中の操作

| 操作                        | 内容                              |
| ------------------------- | ------------------------------- |
| R + Start                 | 練習メニューを開く / 閉じる（X でどの階層からでも閉じる） |
| R + Select / L + Select   | ステートの保存 / 読み込み                  |
| R + X                     | 部屋をやり直す（部屋に入ったときの能力・体力・乱数などに戻す） |
| L + R + X                 | 今の状態を記録し直して部屋をやり直す              |
| L + R + B                 | 部屋ループのオン / オフ                   |
| Select + X                | 前回のワープをやり直す                     |
| L + R + Y                 | フリームーブ                          |
| A + L / A + R / A + L + R | 能力を出す / 切り替える                   |

## メニュー

メインメニューの並び:

| 項目        | 内容                              |
| --------- | ------------------------------- |
| ワープ メニュー  | 部屋へワープする（下の「ワープ」）               |
| ワープ のうりょく | ワープのときにセットする能力                  |
| ワープ らんすう  | ワープのときにセットする乱数                  |
| げんざい らんすう | 今の乱数をすぐ変える                      |
| HUD       | A で タイマー → らんすう → しょりおち → しょうさい |
| タイトル とばす  | A で オフ ⇔ オン（下の「起動」）             |
| ぎんが のうりょく | 銀河にねがいをの能力（初期値は Any%）           |
| カービィ いろ   | カービィの色                          |
| オーディオ     | A で ステレオ → モノラル → オフ            |
| SA1       | SA-1 の調整                        |
| クレジット     | 元の練習ハックのクレジット                   |

- 「ワープ のうりょく」「ワープ らんすう」「HUD」「タイトル とばす」「オーディオ」は、右に今の値が出ます。
- 設定は電源を切っても残ります。

### ワープ

- ワープ メニュー → サブゲーム（洞窟・ダイナブレイド・メタナイト・銀河）→ 区間（洞窟3・ダイナ5・メタナイト7・銀河8）と選びます。Any% のルート上の128部屋に、ルート順にワープできます。
- 区間の一覧では、区間の右に部屋（へや 1〜N）と、その部屋の自己ベストが出ます。

| ボタン    | 区間の一覧での動作                            |
| ------ | ------------------------------------ |
| 左右     | 部屋を選ぶ（区間ごとに覚えています。電源を切ると へや 1 に戻ります） |
| A      | ワープ のうりょく / らんすう をセットしてワープ           |
| Y      | 何もセットせずにワープ                          |
| L / R  | 前 / 次のサブゲームの一覧へ                      |
| Select | 右に出ている部屋の自己ベストを消す                    |

- 一度ワープしたあとは、前回の区間にカーソルがある状態で一覧が開きます。次の部屋は 右 → A、次の区間は 下 → A です。
- メタナイト戦の部屋には直接ワープできないので、1つ前の部屋から入ってください。
- メタナイトへのワープでは見たセリフの記録を消すので、先の部屋から戻ってもセリフが出ます。

### ワープ のうりょく / ワープ らんすう

ワープ（A）のときにセットするものです。ステートをロードしても変わりません。

- **のうりょく**: セットしない / すっぴん / ジェット / ハンマーと ウィリー / プラズマ / じぶんで きめる（カービィの能力・ヘルパー・ウィリーに乗るかを左右で選ぶ）
- **らんすう**: セットしない / 221 189（リセットあと）/ 118 013（クジラあと）/ 031 005（クラッシュあと）/ あたいで きめる / カウントで きめる
- 乱数は、ワープの暗転が明けた最初のフレームでセットします。R + X でも同じ乱数に戻ります。

### げんざい らんすう

今のゲームの乱数をすぐ変えます: カウントで きめる（119 119 から何回進めたか）/ あたいで きめる / リセットあと / デモあと / 1・10・100 かい すすめる。

## HUD

洞窟・ダイナブレイド・メタナイト・銀河では、ヘルパーやボス戦に関係なく、サブゲームごとに決まった場所に出ます。ほかのサブゲームでは残機欄に出ます。

### タイマー

- ワープ・扉・R + X・部屋ループのどれでも、暗転が明けた最初のフレームから部屋ごとのタイムを `SS cc`（秒・1/100秒、99.99 まで）で測ります。
- 暗転が始まった瞬間のタイムを、明るくなってから1.5秒表示します。
- 処理落ちのフレームも含めた実時間です。ポーズでは止まらず、メニューを開いている間と、ボタンを押すまで止まるメタナイトのセリフの間は止まります。
- ステートをロードすると、セーブした瞬間のタイムに戻ります。

### らんすう / しょりおち

- **らんすう**: 今の乱数を `xxx xxx` で表示します。
- **しょりおち**: 部屋の処理落ちのフレーム数（999 まで）を表示します。部屋に入ると0に戻ります。

### しょうさい

HUD 全体を作り替えて、次のものを表示します。能力の絵は左端に残ります。

```
 ####  TIME 0:12.34    RNG 221 189
 ####  PB   0:11.80        CNT 00001
 ####  X 01A3.80  VX +02.87
 ####  Y 00F0.00  VY -07.00
 ####  LAG 12                BOSS 120
（####：能力の絵）
```

- **X / Y**: カービィの座標（16進数、`.` の後ろはサブピクセル）。ウィリーに乗っている間はウィリーの値です。
- **VX / VY**: 前のフレームから実際に動いた量の **2倍**（10進数、右・下がプラス）。例：1フレームに 4.906 ピクセル動くと `+09.81`。
- **BOSS**: ボスの体力（いなければ `-`）。
- メタナイトのセリフが HUD の場所に出ている間はゲームの HUD に戻ります。

### RNGカウント

らんすう と しょうさい の HUD に、119 119 から乱数が何回進んだかが出ます（119 119 が 0、221 189 が 1、65534 でまた 119 119）。85 085 と 170 170 は 119 119 から届かない値なので出ません。

### 自己ベスト

- ルートの128部屋それぞれの自己ベストを記録し、タイマーのとなりの行（洞窟は上、ほかは下）・しょうさい・区間の一覧に出します。電源を切っても残ります。
- 記録されるのは、ルートの入口から入り（ワープ・ルートどおりの扉・そこからの R + X や部屋ループ）、ルートの次の部屋へ出たときだけです。ステージの最後の部屋は、ステージの終わりで記録します。
- フリームーブ・能力のホットキー・ステートのロードを使ったときと、カービィがやられたときは記録しません。
- 消すのは区間の一覧の Select です。

## 部屋ループ（L + R + B）

- オンのときに扉に入ると、次の部屋へ行かずに、その部屋に入ったときの状態（能力・体力・乱数・位置）からやり直します。オンとオフで効果音が違い、電源を入れたときはオフです。
- ステージの終わりの扉・ワープスター・ボスを倒したときもループします。ステージの最初の部屋では登場演出からやり直します。

## 前回のワープをやり直す（Select + X）

最後にワープした部屋へ、同じやり方（A ならワープ設定あり、Y ならなし）でもう一度ワープします。まだワープしていないときは何も起きません。

## 起動

- **タイトル とばす** をオンにすると、電源を入れたときにタイトル画面を飛ばして、ファイル1のモードセレクトから始まります。初期値はオフです。
- オンのとき、リセット後の乱数は 221 189 です（本番ではタイトル画面を最速で飛ばしても乱数が1回進むため）。オフのときはもとのゲームと同じ 119 119 です。
- ファイル1は、電源を入れるたびに100%データになります（モードセレクトのカーソル位置は残ります）。
- モードセレクトで新しいカードの登場演出は出ません。

## 元のハックからの変更

- **外したもの**: ボスを倒すときの点滅の切り替え、メニューの中での言語の切り替え（言語はビルドで選びます）、ボスワープ。
- **直した不具合**:
  - ステートのロードで止まる不具合（ポーズ中・繰り返し・別のモードからのロード）
  - 実機のダイナブレイド1で、まれに画面がちらつく不具合
  - 新しい SRAM（snes9x など）で起動するとコルクボードで止まる不具合
  - R + X のあとウィリーに乗っているときの動きの不具合
  - メニュー・銀河のマップ・SA-1 調整・部屋のやり直しまわりの細かい不具合
- **軽くしたもの**: ステートの保存 / 読み込みを速くし、毎フレームの処理を減らしました。追加した表示の計算は、なるべく SA-1 の待ち時間に行います。
- 銀河にねがいをのポーズ画面で、1P / 2P のカーソルが点滅しないようにしました（画面焼け対策）。
- メニューは深い青の背景に白い文字です。

---

# English

A practice hack for Kirby Super Star (Japanese 1.0, *Hoshi no Kirby Super Deluxe*) Any% speedruns.
Warp straight to any of the 128 rooms on the route, and practice each room with its time, RNG and personal best on the HUD.

Original practice hack: https://github.com/bluebarker/KSS-Practice

## Building

1. Download this repository (green "Code" button → Download ZIP, for example).
2. Get [asar](https://github.com/RPGHacker/asar) and put `asar.exe` (`asar` on Unix) in this folder.
3. Put a **Japanese 1.0** ROM of the game in this folder, named `original.sfc`.
4. Run one of these:

| Run                                                     | ROM              | Menu language |
| ------------------------------------------------------- | ---------------- | ------------- |
| `make_file_en.bat` (Windows) / `make_file_en.sh` (Unix) | `patched_en.sfc` | English       |
| `make_file.bat` (Windows) / `make_file.sh` (Unix)       | `patched.sfc`    | Japanese      |

With PowerShell:

```powershell
Copy-Item -Force original.sfc patched_en.sfc
.\asar.exe -Dmenu_english=1 patch.asm patched_en.sfc
```

- Other ROM versions do not work. No ROM is included.
- The room PBs need 256KB of SRAM (where it is not available, only the PBs do not work).

## Controls in game

| Buttons                   | Action                                                               |
| ------------------------- | -------------------------------------------------------------------- |
| R + Start                 | Open / close the practice menu (X closes it from any screen)         |
| R + Select / L + Select   | Save / load state                                                    |
| R + X                     | Restart the room (the ability, health, RNG etc. it was entered with) |
| L + R + X                 | Record the current state and restart the room from it                |
| L + R + B                 | Room loop on / off                                                   |
| Select + X                | Repeat the last warp                                                 |
| L + R + Y                 | Free movement                                                        |
| A + L / A + R / A + L + R | Give / change abilities                                              |

## Menu

Main menu:

| Item            | What it does                                        |
| --------------- | --------------------------------------------------- |
| Warp Menu       | Warp to a room (see "Warps")                        |
| Warp Ability    | The ability set by a warp                           |
| Warp RNG        | The RNG set by a warp                               |
| RNG Now         | Change the RNG of the game now                      |
| HUD             | A: Timer → RNG → Lag → Detail                       |
| Skip Title      | A: Off ⇔ On (see "Power on")                        |
| MWW Abilities   | The abilities of Milky Way Wishes (Any% by default) |
| Kirby Color     | Kirby's color                                       |
| Audio           | A: Stereo → Mono → Off                              |
| SA-1 Adjustment | SA-1 timing adjustment                              |
| Credits         | The credits of the original practice hack           |

- Warp Ability, Warp RNG, HUD, Skip Title and Audio show their current value on the right.
- The settings are kept after power off.

### Warps

- Warp Menu → sub-game (Great Cave Offensive, Dyna Blade, Revenge of Meta Knight, Milky Way Wishes) → segment (Cave 3, Dyna Blade 5, Meta Knight 7, Milky Way 8). All 128 rooms of the Any% route, in route order.
- Each segment in the list shows a room (Room 1 to N) and that room's PB on the right.

| Button       | In a segment list                                  |
| ------------ | -------------------------------------------------- |
| Left / Right | Choose the room (kept per segment until power off) |
| A            | Warp, setting Warp Ability / Warp RNG              |
| Y            | Warp without setting anything                      |
| L / R        | Previous / next sub-game                           |
| Select       | Clear the PB of the room shown                     |

- After a warp, the menu opens on the list of the last warp, on its segment: Right → A for the next room, Down → A for the next segment.
- The Meta Knight fight room cannot be warped to directly: enter it from the room before.
- Warps to Revenge of Meta Knight clear the record of seen dialogues, so they show again.

### Warp Ability / Warp RNG

What a warp with A sets. Loading a state does not change them.

- **Ability**: Don't Set / Normal / Jet / Hammer + Wheelie / Plasma / Custom (Kirby's ability, the helper and riding the Wheelie, chosen with Left / Right)
- **RNG**: Don't Set / 221 189 Reset / 118 013 Whale / 031 005 Crash / By Value / By Count
- The RNG is set on the first frame after the warp's fade, and R + X goes back to it.

### RNG Now

Changes the RNG right away: Set RNG Count (advances from 119 119) / Set RNG Value / After Reset RNG / After Demo RNG / Advance RNG x1, x10, x100.

## HUD

In Great Cave Offensive, Dyna Blade, Revenge of Meta Knight and Milky Way Wishes the HUD is at a fixed place per sub-game, with or without a helper or a boss. In the other sub-games it is in the lives box.

### Timer

- Times each room as `SS cc` (seconds, 1/100 s, up to 99.99) from the first frame after the fade of a warp, a door, R + X or the room loop.
- The time when a fade starts stays on screen for 1.5 s after it.
- Real time, lag frames included. It does not stop on pause; it stops while the menu is open and during Meta Knight dialogues that wait for a button.
- Loading a state brings back the time of the save.

### RNG / Lag

- **RNG**: the current RNG as `xxx xxx`.
- **Lag**: lag frames in the room (up to 999), reset when a room is entered.

### Detail

A whole new HUD (the ability picture stays on the left):

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

The RNG and Detail HUDs show how many times the RNG advanced from 119 119 (119 119 is 0, 221 189 is 1, after 65534 it is 119 119 again). 85 085 and 170 170 cannot be reached from 119 119 and show no count.

### Room PBs

- The PB of each of the 128 rooms, shown on the row next to the timer (above it in Great Cave Offensive, below elsewhere), on the Detail HUD and in the segment lists. Kept after power off.
- A time counts only when the room was entered from its route entrance (a warp, the route door, R + X or the room loop from them) and left to the next room of the route. The last room of a stage counts at the end of the stage.
- Not counted: free movement, the ability hotkeys or a state load were used, or Kirby died.
- Clear one with Select in a segment list.

## Room loop (L + R + B)

- When it is on, a door restarts the room with the state it was entered with (ability, health, RNG, position) instead of going on. On and off have different sounds; it is off after power on.
- Stage end doors, warp stars and boss defeats loop too. In the first room of a stage it restarts from the stage's intro.

## Repeat the last warp (Select + X)

Warps again to the room of the last warp, the same way (A: with the warp settings, Y: without). Nothing happens before the first warp.

## Power on

- With **Skip Title** on, the game skips the title screen and starts on the mode select of file 1. It is off by default.
- When it is on, the RNG after a reset is 221 189 (in a real run, skipping the title screen as fast as possible advances it once). When it is off, it is 119 119 as in the original game.
- File 1 becomes a 100% file at every power on (the mode select cursor is kept).
- The new card show on the mode select is skipped.

## Changes from the original hack

- **Removed**: the boss screen flashing option, the language choice in the menu (the language is chosen when building), the boss warps.
- **Bugs fixed**:
  - Freezes on state loads (while paused, repeated loads, loads from another mode)
  - Rare screen flicker in Dyna Blade 1 on real hardware
  - The corkboard hanging on a new SRAM (snes9x and others)
  - Wrong Wheelie riding movement after R + X
  - Small bugs in the menu, the Milky Way Wishes map, the SA-1 adjustment and room restarts
- **Faster**: state saves / loads are faster and less is done every frame. What the added displays compute runs in the SA-1's idle time where possible.
- The 1P / 2P cursors on the Milky Way Wishes pause screen no longer blink (screen burn-in).
- The menu is white text on deep blue.
