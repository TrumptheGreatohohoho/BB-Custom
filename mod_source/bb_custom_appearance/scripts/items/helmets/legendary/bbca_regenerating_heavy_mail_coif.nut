this.bbca_regenerating_heavy_mail_coif <- this.inherit("scripts/items/helmets/helmet", {
	m = {},

	function create()
	{
		this.helmet.create();
		this.m.ID = "armor.head.bbca_regenerating_heavy_mail_coif";
		this.m.Name = "自愈纹章尖顶盔";
		this.m.Description = "一顶以纹章尖顶盔为外形的奇异头盔。受损的护甲会在战斗中自行修复，战斗结束后则完全复原。";
		this.m.ShowOnCharacter = true;
		this.m.IsDroppedAsLoot = true;
		this.m.HideHair = true;
		this.m.HideBeard = false;
		this.m.IsIndestructible = true;
		this.m.Variant = 265;
		this.updateVariant();
		this.m.ImpactSound = this.Const.Sound.ArmorChainmailImpact;
		this.m.InventorySound = this.Const.Sound.ArmorChainmailImpact;
		this.m.Value = 20000;
		this.m.Condition = 270;
		this.m.ConditionMax = 270;
		this.m.StaminaModifier = -10;
		this.m.ItemType = this.m.ItemType | this.Const.Items.ItemType.Legendary;
	}

	function getTooltip()
	{
		local result = this.helmet.getTooltip();
		result.push({
			id = 7,
			type = "text",
			icon = "ui/icons/special.png",
			text = "每回合回复自身[color=" + this.Const.UI.Color.PositiveValue + "]90[/color]点耐久。"
		});
		return result;
	}

	function onTurnStart()
	{
		this.m.Condition = this.Math.minf(this.m.ConditionMax, this.m.Condition + 90.0);
		this.updateAppearance();
	}

	function onCombatFinished()
	{
		this.m.Condition = this.m.ConditionMax;
		this.updateAppearance();
	}

	function onDeserialize( _in )
	{
		this.helmet.onDeserialize(_in);
		// Existing copies serialized the previous Variant. Keep this custom
		// item on the requested blue-plumed Heraldic Bascinet after every load.
		this.m.Variant = 265;
		this.updateVariant();
		this.updateAppearance();
	}
});
