// Minimal Chinese UI compatibility helpers. These globals must load before UI
// controls that call them; otherwise the Battle Brothers main menu black-screens.

var TranslatePopupDialog = function(text)
{
	text = text.replace("Unlock Perk", "解锁特技");
	text = text.replace("Dismiss", "解雇");
	text = text.replace("Change Name & Title", "更改名称和头衔");
	text = text.replace("Leveled Up", "升级");
	text = text.replace("Level Up", "升级");
	text = text.replace("Retire", "退休");
	text = text.replace("Delete", "删除");
	text = text.replace("Enter Name", "输入名称");

	return text;
}

var TranslateDialog = function(text)
{
	text = text.replace("Load Campaign", "载入战役");
	text = text.replace("New Campaign", "新战役");
	text = text.replace("Save Campaign", "保存战役");
	text = text.replace("Choose a Scenario", "选择一个场景");
	text = text.replace("Options", "选项");

	return text;
}

var TranslateButtons = function(text)
{
	text = text.replace("New Campaign", "新战役");
	text = text.replace("Load Campaign", "载入战役");
	text = text.replace("Tutorial Videos", "教程视频");
	text = text.replace("Save Campaign", "保存战役");
	text = text.replace("Save & Quit", "保存并退出");
	text = text.replace("Statistics", "结果统计");
	text = text.replace("Options", "选项");
	text = text.replace("Audio", "音频");
	text = text.replace("Controls", "控制");
	text = text.replace("Gameplay", "游戏性");
	text = text.replace("Ok", "确定");
	text = text.replace("Apply", "应用");
	text = text.replace("Cancel", "取消");
	text = text.replace("Perks", "特技");
	text = text.replace("Stash", "仓库");
	text = text.replace("Ground", "地面");
	text = text.replace("Try out", "测验");
	text = text.replace("Hire", "雇佣");
	text = text.replace("Pay", "付款");
	text = text.replace("Leave", "离开");
	text = text.replace("Retreat!", "撤退！");
	text = text.replace("Retreat", "撤退");
	text = text.replace("It's over", "结束了");
	text = text.replace("Run them down!", "追击！");
	text = text.replace("Accept", "接受");
	text = text.replace("Craft", "制作");
	text = text.replace("Delete", "删除");
	text = text.replace("Next", "下一步");
	text = text.replace("Start Battle", "开始战斗");
	text = text.replace("Start", "开始");
	text = text.replace("Play", "开玩");
	text = text.replace("Previous", "上一步");
	text = text.replace("Save", "保存");
	text = text.replace("Load", "载入");
	text = text.replace("Scenarios", "场景");
	text = text.replace("Video", "视频");
	text = text.replace("Credits", "制作组");
	text = text.replace("Quit", "退出");
	text = text.replace("Resume", "返回游戏");
	text = text.replace("Retire", "退休");
	text = text.replace("Loot", "战利品");
	text = text.replace("Yes", "是");
	text = text.replace("No", "否");
	text = text.replace("Close", "关闭");
	text = text.replace("Travel", "旅行");
	text = text.replace("Engage!", "开战！");
	text = text.replace("Flee!", "逃走！");
	text = text.replace("To Arms!", "拿起武器！");
	text = text.replace("Fall back!", "撤退！");
	text = text.replace("Continue", "继续");

	return text;
}

var TranslateSLCampaignMenuModule = function(text)
{
	text = text.replace("- Incompatible Version or DLC Missing -", "- 版本不兼容或缺少DLC -");
	text = text.replace("- Incompatible Version -", "- 版本不兼容 -");
	text = text.replace("New Savegame", "新存档");
	text = text.replace(/Day (.*?) \((.*?)\/(.*?) (.*?)\)/, "第$1天 （$2\/$3 $4）");
	text = text.replace(/Day (.*?) \((.*?)\/(.*?)\)/, "第$1天 （$2\/$3）");
	text = text.replace("Ironman", "铁人模式");
	text = text.replace(/(.*?)\.(.*?)\.(.*?) /, "$3年$2月$1日 ");
	text = text.replace("Beginner", "初学者");
	text = text.replace("Veteran", "老兵");
	text = text.replace("Normal", "老兵");
	text = text.replace("Expert", "专家");
	text = text.replace("\/Beginner", "\/初学者");
	text = text.replace("\/Veteran", "\/老兵");
	text = text.replace("\/Normal", "\/老兵");
	text = text.replace("\/Expert", "\/专家");

	return text;
}

// The installed Chinese compatibility archive supplies the full world-name
// translations in world_names.js. Keep no-op fallbacks so an absent optional
// archive never freezes the UI while a tooltip or world-event is created.
if (typeof TranslateAllWorldNames === "undefined")
{
	var TranslateAllWorldNames = function(text) { return text; }
	var TranslateActiveContract = function(text) { return text; }
	var TranslateTownScreenNames = function(text) { return text; }
	var TranslateTooltips = function(text) { return text; }
	var TranslateWorldEntityNames = function(text) { return text; }
	var TranslateMercenaryCompanyNames = function(text) { return text; }
	var TranslateCityStateNames = function(text) { return text; }
	var TranslateSettlementNames = function(text) { return text; }
	var TranslateRegionNames = function(text) { return text; }
}
