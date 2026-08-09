# 码头风云 · 早期剧情文案审阅包

> 自动导出自 `docs/tables/packs/core/l10n/zh_CN.csv`
> 按线分组，便于朋友按规矩改，不要整包糊成一团。

## 规矩（给审稿人）

1. 一句一事，少用抽象隐喻（刀/钉/潮+野心）。
2. 人名场景要能对上：少霆、晚晴、宏远、码头。
3. `|||` 是分段，保留；缺段不要空着糊弄。
4. 改完回传时请保留左侧 **key**。

## 开场 / Day1

- `ui.prologue.body`:
  - 潮起潮落，这座港靠力与算计吃饭。货轮靠岸、账房拨算盘，谁先站稳，谁就能往上爬。
  - 你是林阿海——周记洋行装卸组长。码头上喊一声「阿海」，半个货仓都听得见。
  - 苦干这些年，升职几乎板上钉钉，未婚妻苏晚晴也开始跟你谈婚事。你以为，日子终于往上走了。
  - 今早你顺路去副理办公室，想问一句升职——门还没敲，里面先传来少霆的笑声，还有她压低的应声。
- `events.ev_day1_intro.title`:
  - 顺风里的异响
- `events.ev_day1_intro.body`:
  - 今天风顺。你路过副理办公室，本想顺路问一句升职的事——
  - 门缝里传来少霆的笑声，还有晚晴压低的应声。像早就约好了似的。
  - 茶杯盖一合。升职的话堵在喉头：里面这两个人，已经把你要问的事谈完了。
- `event_choices.ch_intro_ok.label`:
  - 先把今天看清楚

## 码头日常

- `actions.dock_work.name`:
  - 搬货打工
- `actions.dock_work.result`:
  - 号子砸在肩上。工钱到手，汗还没干。工头远远哼了一声，没再多话。
- `dialogue_lines.dlg_dock_work_l01.text`:
  - 号子一声接一声。盐潮味钻进领口。
- `dialogue_lines.dlg_dock_work_l02.text`:
  - 再扛两趟……工钱总算是自己的。
- `dialogue_lines.dlg_dock_work_l03.text`:
  - 肩头火辣。工友递过一碗凉茶，喊你：「阿海，歇口气。」
- `actions.dock_chat.result`:
  - 工人把烟头一摁：夜班的单，有人做了手脚。别大声。
- `actions.dock_watch_manifest.result`:
  - 你把船名和吨位记牢。这数字，回头也许用得上。
- `dialogue_lines.dlg_dock_manifest_l03.text`:
  - 你把吨位和船名默记两遍，才抬脚走开。

## 出租屋

- `actions.home_organize.result`:
  - 纸边对齐。这屋里的安静，比办公室的茶盖更让人清醒。
- `dialogue_lines.dlg_home_organize_l02.text`:
  - 先把桌上的纸理齐。乱成一团时，别人进门一眼就能看出你慌。
- `actions.home_plan.result`:
  - 纸上写了又划。明天能做的，其实只有一件：先去码头或公司露个面。
- `dialogue_lines.dlg_home_plan_l01.text`:
  - 灯芯噼啪。纸上写着：码头、公司、家里。
- `dialogue_lines.dlg_home_plan_l02.text`:
  - 先忍着？还是找人打听？还是去交易所碰运气？
- `dialogue_lines.dlg_home_plan_l03.text`:
  - 你划掉两行，只留下明天早上要去的地方。
- `dialogue_lines.dlg_home_rest_l01.text`:
  - 床板吱呀。潮声一下一下，把肩上的酸意慢慢冲淡。
- `idle_chatter.chatter_home_01.text`:
  - 窗外潮声一下一下，数着你还没睡稳的夜。

## 公司 / 少霆 / 晚晴

- `actions.co_work.result`:
  - 毛笔写到手指发僵。茶盖轻叩——今天又安稳过了一格。
- `dialogue_lines.dlg_co_work_l02.text`:
  - 字迹端正。至少今天没人挑你的错。
- `dialogue_lines.dlg_co_work_l03.text`:
  - 墨迹干了。你把公文叠好，起身倒茶。
- `actions.co_eavesdrop.result`:
  - 屏风后两个人压低声音。你听清了船期和人名——够回去慢慢嚼。
- `dialogue_lines.dlg_co_eavesdrop_l03.text`:
  - 你把听来的人名和船期对上号。先不声张，留着有用。
- `actions.co_meet_su.result`:
  - 走廊里目光一碰，她先躲开。袖口那点香，不是家里常用的那种。
- `actions.co_meet_son.result`:
  - 少霆靠着廊柱笑你。文员们低头走过，没人敢接他的话。
- `actions.co_pass_rumor.description`:
  - 借少霆的嘴，把半真半假的船期递出去
- `dialogue_lines.dlg_son_rumor_l01.text`:
  - 你压低声音，把半真半假的船期说给少霆听。他眉毛一挑，没立刻回你。
- `dialogue_lines.dlg_su_guide_l01.text`:
  - 灯芯噼啪。你压低声音：要是她再随口提账目，你就顺着问一句。

## Day4–7 主线节点

- `events.ev_d4_salary.body`:
  - 工钱比预想薄。有人骂主管，有人骂行情。你把银元握热，心里仍空了一截。
- `events.ev_day3_son_notice.body`:
  - 周少霆巡查码头时多看了晚晴两眼。
  - 他笑得很轻，像在打量一件可以随手拿走的东西。
- `events.ev_day5_promotion_stolen.body`:
  - 公示栏上的名字不是你。老板亲信空降货仓主管。
  - 周鸿业把你叫去，语气平静得像谈天气：「阿海，夜班更需要你。」
- `events.ev_day6_su_distance.body`:
  - 晚晴从副理办公室出来，袖口多了块洋布手帕——绣着「霆」字。
  - 她看见你，先把帕子藏进掌心，又挤出一句「没什么」。你一直以为她站在你这边。这一秒，裂缝终于露出了边。
- `events.ev_day7_choice.body`:
  - 夜里睡不着。你反复问自己：还要再忍多久？
  - 三条路仍在——在宏远隐忍周旋、投向通洋另起炉灶、去证券行搏一把。也可以先不选，回去挣钱、升职、把日子过稳。
- `event_choices.ch_d7_finance.label`:
  - 去证券行，靠行情翻本
- `events.ev_flag_su_gifts.title`:
  - 礼物收进柜
- `events.ev_flag_su_gifts.body`:
  - 你看见洋纱盒不再放门口，而进了柜子。晚晴说「退不掉」。少霆的影子，已经进了你家的门缝。
- `event_choices.ch_ev_flag_su_gifts_confront.label`:
  - 冷着脸问清楚
- `event_choices.ch_ev_flag_su_gifts_use.label`:
  - 假装大度，记作把柄

_缺失 key 数：0_
