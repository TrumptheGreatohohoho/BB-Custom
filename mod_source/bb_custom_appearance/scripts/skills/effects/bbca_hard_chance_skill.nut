this.bbca_hard_chance_skill <- this.inherit("scripts/skills/skill", {
    m = {
        ShowStatusIcon = false,
        HardHitChance = 50,
        HardEvasionChance = 50
    },

    function create()
    {
        this.m.ID = "effects.bbca_hard_chance";
        this.m.Name = "Hard Chance";
        this.m.Description = "Adds a flat final hit chance bonus when attacking, subtracts a flat final hit chance bonus from enemies attacking this character, and resets fatigue at the start of each turn. A value of 100 is absolute; absolute evasion takes priority over absolute hit.";
        this.m.Icon = "skills/status_effect_146.png";
        this.m.IconMini = "status_effect_146_mini";
        this.m.Overlay = "status_effect_146";
        this.m.Type = this.Const.SkillType.StatusEffect | this.Const.SkillType.Perk;
        this.m.Order = this.Const.SkillOrder.Perk;
        this.m.IsActive = false;
        this.m.IsAttack = false;
        this.m.IsStacking = false;
        this.m.IsSerialized = true;
        this.m.IsHidden = true;
    }

    function bbca_getConfig()
    {
        local container = this.getContainer();
        if (container == null)
        {
            return null;
        }

        return container.getSkillByID("effects.bbca_hard_chance_config");
    }

    function bbca_getBool( _key, _fallback )
    {
        local config = this.bbca_getConfig();
        if (config != null && _key in config.m)
        {
            return config.m[_key];
        }

        return _key in this.m ? this.m[_key] : _fallback;
    }

    function bbca_getNumber( _key, _fallback )
    {
        local config = this.bbca_getConfig();
        if (config != null && _key in config.m)
        {
            return config.m[_key];
        }

        return _key in this.m ? this.m[_key] : _fallback;
    }

    function getTooltip()
    {
        return [
            {
                id = 1,
                type = "title",
                text = this.getName()
            },
            {
                id = 2,
                type = "description",
                text = this.getDescription()
            },
            {
                id = 3,
                type = "text",
                icon = "ui/icons/chance_to_hit_head.png",
                text = "Final hit chance when attacking: [color=" + this.Const.UI.Color.PositiveValue + "]+" + this.bbca_getNumber("HardHitChance", 50) + "%[/color]"
            },
            {
                id = 4,
                type = "text",
                icon = "ui/icons/melee_defense.png",
                text = "Enemy final hit chance against this character: [color=" + this.Const.UI.Color.PositiveValue + "]-" + this.bbca_getNumber("HardEvasionChance", 50) + "%[/color]. At 100, attacks have a final hit chance of 0%."
            },
            {
                id = 5,
                type = "text",
                icon = "ui/icons/fatigue.png",
                text = "Current fatigue is reset to [color=" + this.Const.UI.Color.PositiveValue + "]0[/color] at the start of each turn."
            }
        ];
    }

    function bbca_resetFatigue()
    {
        local container = this.getContainer();
        if (container == null)
        {
            return;
        }

        local actor = container.getActor();
        if (actor == null)
        {
            return;
        }

        try
        {
            actor.setFatigue(0);
        }
        catch (exception)
        {
        }
    }

    function onTurnStart()
    {
        this.bbca_resetFatigue();
    }

    function onUpdate( _properties )
    {
        this.m.IsHidden = !this.bbca_getBool("ShowStatusIcon", false);

        // Compatibility with fatigue recovery mods that wrap actor.onTurnStart()
        // outside the skill container. Some implementations save old fatigue,
        // call the vanilla turn start (where this skill has already set fatigue
        // to 0), then restore old fatigue and apply their own recovery formula.
        // Raising the recovery rate for this actor makes those later formulas
        // still resolve the start-of-turn fatigue to 0 without relying on ZIP
        // load order or editing another mod.
        local forcedRecovery = this.Math.max(1000, _properties.Stamina + 100);
        _properties.FatigueRecoveryRate = this.Math.max(_properties.FatigueRecoveryRate, forcedRecovery);

        if (_properties.FatigueRecoveryRateMult < 1.0)
        {
            _properties.FatigueRecoveryRateMult = 1.0;
        }
    }
});

