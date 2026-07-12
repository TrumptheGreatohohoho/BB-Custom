this.bbca_fire_grenade_skill <- this.inherit("scripts/skills/skill", {
    m = {
        Cooldown = 7,
        Skillcool = 7,
        AreaRadius = 2,
        FireDuration = 2
    },

    function create()
    {
        this.m.ID = "actives.bbca_fire_grenade";
        this.m.Name = "Fire Grenade";
        this.m.Description = "Throw a reusable incendiary grenade that sets a wide area ablaze. The flames harm friend and foe alike.";
        this.m.Icon = "skills/active_209.png";
        this.m.IconDisabled = "skills/active_209_sw.png";
        this.m.Overlay = "active_209";
        this.m.SoundOnUse = [
            "sounds/combat/throw_ball_01.wav",
            "sounds/combat/throw_ball_02.wav",
            "sounds/combat/throw_ball_03.wav"
        ];
        this.m.SoundOnHit = [
            "sounds/combat/dlc6/fire_pot_01.wav",
            "sounds/combat/dlc6/fire_pot_02.wav",
            "sounds/combat/dlc6/fire_pot_03.wav",
            "sounds/combat/dlc6/fire_pot_04.wav"
        ];
        this.m.SoundOnHitDelay = 0;
        this.m.Type = this.Const.SkillType.Active;
        this.m.Order = this.Const.SkillOrder.UtilityTargeted;
        this.m.Delay = 0;
        this.m.IsSerialized = true;
        this.m.IsActive = true;
        this.m.IsTargeted = true;
        this.m.IsTargetingActor = false;
        this.m.IsStacking = false;
        this.m.IsAttack = true;
        this.m.IsRanged = false;
        this.m.IsIgnoredAsAOO = true;
        this.m.IsShowingProjectile = true;
        this.m.IsUsingHitchance = false;
        this.m.IsDoingForwardMove = true;
        this.m.ActionPointCost = 6;
        this.m.FatigueCost = 35;
        this.m.MinRange = 2;
        this.m.MaxRange = 4;
        this.m.MaxLevelDifference = 1;
        this.m.ProjectileType = this.Const.ProjectileType.Bomb1;
        this.m.ProjectileTimeScale = 1.5;
        this.m.IsProjectileRotated = false;
    }

    function bbca_getConfig()
    {
        local container = this.getContainer();
        if (container == null)
        {
            return null;
        }

        return container.getSkillByID("effects.bbca_fire_grenade_config");
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

    function getMinRange()
    {
        return this.bbca_getNumber("MinRange", this.m.MinRange);
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

    function bbca_getFireDuration()
    {
        return this.bbca_getNumber("FireDuration", this.m.FireDuration);
    }

    function bbca_getAreaRadius()
    {
        return this.bbca_getNumber("AreaRadius", this.m.AreaRadius);
    }

    function getTooltip()
    {
        local ret = this.getDefaultUtilityTooltip();
        local radius = this.bbca_getAreaRadius();
        local maximumTiles = 1 + 3 * radius * (radius + 1);
        ret.push({
            id = 4,
            type = "text",
            icon = "ui/icons/vision.png",
            text = "Can be thrown " + this.getMinRange() + " to " + this.getMaxRange() + " tiles"
        });
        ret.push({
            id = 5,
            type = "text",
            icon = "ui/icons/special.png",
            text = "Sets the target tile and all tiles within " + radius + " spaces ablaze, up to " + maximumTiles + " tiles in total"
        });
        ret.push({
            id = 6,
            type = "text",
            icon = "ui/icons/special.png",
            text = "Fire lasts for " + this.bbca_getFireDuration() + " rounds, deals 15 to 30 damage, and harms friend and foe alike"
        });
        ret.push({
            id = 7,
            type = "text",
            icon = "ui/icons/special.png",
            text = "Water and other non-flammable terrain can not remain ablaze; existing tile effects such as Smoke or Miasma are replaced"
        });
        ret.push({
            id = 8,
            type = "text",
            icon = "ui/icons/special.png",
            text = "Cooldown: " + this.bbca_getCooldown() + " rounds. Cooldown left: [color=" + this.Const.UI.Color.NegativeValue + "]" + this.Math.max(0, this.bbca_getCooldown() - this.m.Skillcool) + "[/color]"
        });
        return ret;
    }

    function getAffectedTiles( _targetTile )
    {
        local affectedTiles = [_targetTile];
        local frontier = [_targetTile];
        local seenTileIDs = [_targetTile.ID];

        for (local distance = 0; distance < this.bbca_getAreaRadius(); distance = ++distance)
        {
            local nextFrontier = [];
            foreach (originTile in frontier)
            {
                for (local direction = 0; direction != 6; direction = ++direction)
                {
                    if (!originTile.hasNextTile(direction))
                    {
                        continue;
                    }

                    local tile = originTile.getNextTile(direction);
                    if (seenTileIDs.find(tile.ID) != null)
                    {
                        continue;
                    }

                    seenTileIDs.push(tile.ID);
                    affectedTiles.push(tile);
                    nextFrontier.push(tile);
                }
            }
            frontier = nextFrontier;
        }

        return affectedTiles;
    }

    function onVerifyTarget( _originTile, _targetTile )
    {
        if (!this.skill.onVerifyTarget(_originTile, _targetTile))
        {
            return false;
        }

        return this.Math.abs(_originTile.Level - _targetTile.Level) <= this.getMaxLevelDifference();
    }

    function onTargetSelected( _targetTile )
    {
        foreach (tile in this.getAffectedTiles(_targetTile))
        {
            this.Tactical.getHighlighter().addOverlayIcon(this.Const.Tactical.Settings.AreaOfEffectIcon, tile, tile.Pos.X, tile.Pos.Y);
        }
    }

    function onAfterUpdate( _properties )
    {
        this.m.FatigueCostMult = _properties.IsSpecializedInThrowing ? this.Const.Combat.WeaponSpecFatigueMult : 1.0;
    }

    function onUse( _user, _targetTile )
    {
        this.m.Skillcool = 0;

        if (this.m.IsShowingProjectile && this.m.ProjectileType != 0)
        {
            local flip = !this.m.IsProjectileRotated && _targetTile.Pos.X > _user.getPos().X;
            if (_user.getTile().getDistanceTo(_targetTile) >= this.Const.Combat.SpawnProjectileMinDist)
            {
                this.Tactical.spawnProjectileEffect(this.Const.ProjectileSprite[this.m.ProjectileType], _user.getTile(), _targetTile, 1.0, this.m.ProjectileTimeScale, this.m.IsProjectileRotated, flip);
            }
        }

        this.Time.scheduleEvent(this.TimeUnit.Real, 250, this.onApply.bindenv(this), {
            IsByPlayer = _user.isPlayerControlled(),
            TargetTile = _targetTile,
            Tiles = this.getAffectedTiles(_targetTile),
            FireDuration = this.bbca_getFireDuration()
        });
        return true;
    }

    function onApply( _data )
    {
        if (!this.Tactical.isActive() || _data.TargetTile == null)
        {
            return;
        }

        if (this.m.SoundOnHit.len() != 0)
        {
            this.Sound.play(this.m.SoundOnHit[this.Math.rand(0, this.m.SoundOnHit.len() - 1)], this.Const.Sound.Volume.Skill, _data.TargetTile.Pos);
        }

        foreach (tile in _data.Tiles)
        {
            if (tile != null)
            {
                this.Tactical.State.spawnFireOnTile(tile, _data.IsByPlayer, true, _data.FireDuration);
            }
        }
    }

    function isUsable()
    {
        return this.skill.isUsable() && this.m.Skillcool >= this.bbca_getCooldown();
    }

    function onTurnStart()
    {
        this.m.Skillcool = this.Math.min(this.m.Skillcool + 1, this.bbca_getCooldown());
    }

    function onCombatFinished()
    {
        this.m.Skillcool = this.bbca_getCooldown();
    }
});
