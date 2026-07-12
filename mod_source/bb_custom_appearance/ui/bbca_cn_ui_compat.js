// Safety-only fallbacks. The managed Breditor archive loads the complete
// Chinese ui.js and world_names.js before this file. Never override them.

if (typeof TranslatePopupDialog === "undefined")
{
	var TranslatePopupDialog = function(text) { return text; }
}

if (typeof TranslateDialog === "undefined")
{
	var TranslateDialog = function(text) { return text; }
}

if (typeof TranslateButtons === "undefined")
{
	var TranslateButtons = function(text) { return text; }
}

if (typeof TranslateSLCampaignMenuModule === "undefined")
{
	var TranslateSLCampaignMenuModule = function(text) { return text; }
}

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
