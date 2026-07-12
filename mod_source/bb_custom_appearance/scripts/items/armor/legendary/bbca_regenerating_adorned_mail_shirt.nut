this.bbca_regenerating_adorned_mail_shirt <- this.inherit("scripts/items/armor/armor", {
	m = {},

	function create()
	{
		this.armor.create();
		this.m.ID = "armor.body.bbca_regenerating_adorned_mail_shirt";
		this.m.Name = "自愈圣饰链甲衫";
		this.m.Description = "一件以圣饰链甲衫为外形的奇异战甲。受损的甲环会在战斗中自行弥合，战斗结束后则完全复原。";
		this.m.SlotType = this.Const.ItemSlot.Body;
		this.m.IsDroppedAsLoot = true;
		this.m.ShowOnCharacter = true;
		this.m.IsIndestructible = true;
		this.m.Variant = 107;
		this.updateVariant();
		this.m.ImpactSound = this.Const.Sound.ArmorChainmailImpact;
		this.m.InventorySound = this.Const.Sound.ArmorChainmailImpact;
		this.m.Value = 20000;
		this.m.Condition = 270;
		this.m.ConditionMax = 270;
		this.m.StaminaModifier = -18;
		this.m.ItemType = this.m.ItemType | this.Const.Items.ItemType.Legendary;
	}

	function getTooltip()
	{
		local result = this.armor.getTooltip();
		result.push({
			id = 6,
			type = "text",
			icon = "ui/icons/special.png",
			text = "每回合回复自身[color=" + this.Const.UI.Color.PositiveValue + "]90[/color]点耐久。"
		});
		return result;
	}

	function onTurnStart()
	{
		this.armor.onTurnStart();
		this.m.Condition = this.Math.minf(this.m.ConditionMax, this.m.Condition + 90.0);
		this.updateAppearance();
	}

	function onCombatFinished()
	{
		this.armor.onCombatFinished();
		this.m.Condition = this.m.ConditionMax;
		this.updateAppearance();
	}
});

