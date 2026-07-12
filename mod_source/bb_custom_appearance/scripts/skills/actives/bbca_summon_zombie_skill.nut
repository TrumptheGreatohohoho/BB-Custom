this.bbca_summon_zombie_skill <- this.inherit("scripts/skills/skill", {
    m = {
        Cooldown = 5,
        Skillcool = 5,
        MaxActiveSummons = 3,
        SummonedEntities = []
    },

    function create()
    {
        this.m.ID = "actives.bbca_summon_zombie";
        this.m.Name = "Summon Armored Wiederganger";
        this.m.Description = "Summon an AI-controlled Armored Wiederganger to fight for your side until the battle ends.";
        this.m.Icon = "ui/bbca_summon_zombie.png";
        this.m.IconDisabled = "ui/bbca_summon_zombie_sw.png";
        this.m.SoundOnUse = [
            "sounds/enemies/necromancer_01.wav",
            "sounds/enemies/necromancer_02.wav",
            "sounds/enemies/necromancer_03.wav"
        ];
        this.m.SoundVolume = 1.2;
        this.m.Type = this.Const.SkillType.Active;
        this.m.Order = this.Const.SkillOrder.UtilityTargeted;
        this.m.Delay = 0;
        this.m.IsSerialized = true;
        this.m.IsActive = true;
        this.m.IsTargeted = true;
        this.m.IsTargetingActor = false;
        this.m.IsVisibleTileNeeded = true;
        this.m.IsStacking = false;
        this.m.IsAttack = false;
        this.m.IsIgnoredAsAOO = true;
        this.m.ActionPointCost = 6;
        this.m.FatigueCost = 25;
        this.m.MinRange = 1;
        this.m.MaxRange = 3;
        this.m.MaxLevelDifference = 1;
        this.m.SummonedEntities = [];
    }

    function bbca_getConfig()
    {
        local container = this.getContainer();
        if (container == null)
        {
            return null;
        }

        return container.getSkillByID("effects.bbca_summon_zombie_config");
    }

    function bbca_getNumber( _key, _fallback )
    {
        local config = this.bbca_getConfig();
        if (config != null && _key in config.m)
        {
            return config.m[_key];
        }

        return _fallback;
    }

    function getActionPointCost()
    {
        return this.bbca_getNumber("ActionPointCost", this.m.ActionPointCost);
    }

    function getFatigueCost()
    {
        return this.bbca_getNumber("FatigueCost", this.m.FatigueCost);
    }

    function getMaxRange()
    {
        return this.bbca_getNumber("MaxRange", this.m.MaxRange);
    }

    function getMaxLevelDifference()
    {
        return this.bbca_getNumber("MaxLevelDifference", this.m.MaxLevelDifference);
    }

    function bbca_getCooldown()
    {
        return this.bbca_getNumber("Cooldown", this.m.Cooldown);
    }

    function bbca_getMaxActiveSummons()
    {
        return this.bbca_getNumber("MaxActiveSummons", this.m.MaxActiveSummons);
    }

    function bbca_refreshSummonedEntities()
    {
        local living = [];
        foreach (entity in this.m.SummonedEntities)
        {
            if (entity == null)
            {
                continue;
            }

            local isLivingActor = false;
            try
            {
                isLivingActor = entity.isAlive() && !entity.isDying();
            }
            catch (exception)
            {
                isLivingActor = false;
            }

            if (!isLivingActor)
            {
                continue;
            }

            living.push(entity);
        }

        this.m.SummonedEntities = living;
        return living.len();
    }

    function bbca_hasSummonCapacity()
    {
        return this.bbca_refreshSummonedEntities() < this.bbca_getMaxActiveSummons();
    }

    function getTooltip()
    {
        local ret = this.getDefaultUtilityTooltip();
        ret.push({
            id = 4,
            type = "text",
            icon = "ui/icons/vision.png",
            text = "Summons on an empty visible tile up to " + this.getMaxRange() + " spaces away"
        });
        ret.push({
            id = 5,
            type = "text",
            icon = "ui/icons/special.png",
            text = "Active summons: " + this.bbca_refreshSummonedEntities() + " / " + this.bbca_getMaxActiveSummons()
        });
        ret.push({
            id = 6,
            type = "text",
            icon = "ui/icons/special.png",
            text = "The Armored Wiederganger is controlled by allied AI, can not automatically resurrect, and disappears when the battle ends"
        });
        ret.push({
            id = 7,
            type = "text",
            icon = "ui/icons/special.png",
            text = "Cooldown: " + this.bbca_getCooldown() + " rounds. Cooldown left: [color=" + this.Const.UI.Color.NegativeValue + "]" + this.Math.max(0, this.bbca_getCooldown() - this.m.Skillcool) + "[/color]"
        });
        return ret;
    }

    function onVerifyTarget( _originTile, _targetTile )
    {
        if (!this.skill.onVerifyTarget(_originTile, _targetTile))
        {
            return false;
        }

        if (!this.bbca_hasSummonCapacity())
        {
            return false;
        }

        if (!_targetTile.IsEmpty)
        {
            return false;
        }

        return this.Math.abs(_originTile.Level - _targetTile.Level) <= this.getMaxLevelDifference();
    }

    function onTargetSelected( _targetTile )
    {
        this.Tactical.getHighlighter().addOverlayIcon(this.Const.Tactical.Settings.AreaOfEffectIcon, _targetTile, _targetTile.Pos.X, _targetTile.Pos.Y);
    }

    function onUse( _user, _targetTile )
    {
        if (!this.bbca_hasSummonCapacity())
        {
            return false;
        }

        local entity = this.Tactical.spawnEntity("scripts/entity/tactical/enemies/zombie_yeoman", _targetTile.Coords.X, _targetTile.Coords.Y);
        if (entity == null)
        {
            return false;
        }

        entity.setFaction(this.Const.Faction.PlayerAnimals);
        entity.m.ResurrectionChance = 0;
        entity.assignRandomEquipment();
        entity.setName("Summoned " + entity.getName());
        entity.getFlags().add("bbca_summoned_zombie");
        entity.getSprite("socket").setBrush(_user.getSprite("socket").getBrush().Name);
        this.m.SummonedEntities.push(entity);
        this.m.Skillcool = 0;

        if (_targetTile.IsVisibleForPlayer)
        {
            for (local i = 0; i < this.Const.Tactical.RaiseUndeadParticles.len(); i = ++i)
            {
                this.Tactical.spawnParticleEffect(true, this.Const.Tactical.RaiseUndeadParticles[i].Brushes, _targetTile, this.Const.Tactical.RaiseUndeadParticles[i].Delay, this.Const.Tactical.RaiseUndeadParticles[i].Quantity, this.Const.Tactical.RaiseUndeadParticles[i].LifeTimeQuantity, this.Const.Tactical.RaiseUndeadParticles[i].SpawnRate, this.Const.Tactical.RaiseUndeadParticles[i].Stages);
            }
        }

        this.Tactical.EventLog.log(this.Const.UI.getColorizedEntityName(_user) + " summons " + this.Const.UI.getColorizedEntityName(entity));
        return true;
    }

    function isUsable()
    {
        return this.skill.isUsable()
            && this.m.Skillcool >= this.bbca_getCooldown()
            && this.bbca_hasSummonCapacity();
    }

    function onTurnStart()
    {
        this.m.Skillcool = this.Math.min(this.m.Skillcool + 1, this.bbca_getCooldown());
        this.bbca_refreshSummonedEntities();
    }

    function onCombatStarted()
    {
        this.m.SummonedEntities = [];
        this.m.Skillcool = this.bbca_getCooldown();
    }

    function onCombatFinished()
    {
        this.m.SummonedEntities = [];
        this.m.Skillcool = this.bbca_getCooldown();
    }
});

