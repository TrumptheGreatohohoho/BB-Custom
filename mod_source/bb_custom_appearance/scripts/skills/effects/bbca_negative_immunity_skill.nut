this.bbca_negative_immunity_skill <- this.inherit("scripts/skills/skill", {
    m = {
        ShowStatusIcon = false,
        ImmuneToPoison = true,
        ImmuneToBleeding = true,
        ImmuneToStun = true,
        ImmuneToDaze = true,
        ImmuneToRoot = true,
        ImmuneToKnockBackAndGrab = true,
        ImmuneToDisarm = true,
        ImmuneToRotation = false,
        ImmuneToFire = false,
        ImmuneToHeadshots = false,
        IgnoreInjuries = false,
        ImmuneToOverwhelmed = false,
        ImmuneToDistracted = false,
        ImmuneToSwallowWhole = false,
        StunPiercer = false,
        PassiveCounterattack = false
    },

    function create()
    {
        this.m.ID = "effects.bbca_negative_immunity";
        this.m.Name = "Aegis";
        this.m.Description = "Wards off the configured negative effects while active.";
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
        return container.getSkillByID("effects.bbca_negative_immunity_config");
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

    function bbca_addTooltipLine( _ret, _id, _label, _enabled )
    {
        _ret.push({
            id = _id,
            type = "text",
            icon = _enabled ? "ui/icons/special.png" : "ui/icons/cancel.png",
            text = (_enabled ? "[color=" + this.Const.UI.Color.PositiveValue + "]ON[/color] " : "[color=" + this.Const.UI.Color.NegativeValue + "]OFF[/color] ") + _label
        });
    }

    function getTooltip()
    {
        local ret = [
            {
                id = 1,
                type = "title",
                text = this.getName()
            },
            {
                id = 2,
                type = "description",
                text = this.getDescription()
            }
        ];

        this.bbca_addTooltipLine(ret, 11, "Immune to Poison", this.bbca_getBool("ImmuneToPoison", true));
        this.bbca_addTooltipLine(ret, 12, "Immune to Bleeding", this.bbca_getBool("ImmuneToBleeding", true));
        this.bbca_addTooltipLine(ret, 13, "Immune to Stun", this.bbca_getBool("ImmuneToStun", true));
        this.bbca_addTooltipLine(ret, 14, "Immune to Daze", this.bbca_getBool("ImmuneToDaze", true));
        this.bbca_addTooltipLine(ret, 15, "Immune to Root/Net", this.bbca_getBool("ImmuneToRoot", true));
        this.bbca_addTooltipLine(ret, 16, "Immune to Knockback/Grab", this.bbca_getBool("ImmuneToKnockBackAndGrab", true));
        this.bbca_addTooltipLine(ret, 17, "Immune to Disarm", this.bbca_getBool("ImmuneToDisarm", true));
        this.bbca_addTooltipLine(ret, 18, "Immune to Rotation", this.bbca_getBool("ImmuneToRotation", false));
        this.bbca_addTooltipLine(ret, 19, "Immune to Fire", this.bbca_getBool("ImmuneToFire", false));
        this.bbca_addTooltipLine(ret, 20, "Immune to Headshots", this.bbca_getBool("ImmuneToHeadshots", false));
        this.bbca_addTooltipLine(ret, 21, "Ignore Injuries", this.bbca_getBool("IgnoreInjuries", false));
        this.bbca_addTooltipLine(ret, 22, "Immune to Overwhelmed", this.bbca_getBool("ImmuneToOverwhelmed", false));
        this.bbca_addTooltipLine(ret, 23, "Immune to Distracted", this.bbca_getBool("ImmuneToDistracted", false));
        this.bbca_addTooltipLine(ret, 24, "Immune to Swallow Whole", this.bbca_getBool("ImmuneToSwallowWhole", false));
        this.bbca_addTooltipLine(ret, 25, "Stun Piercer", this.bbca_getBool("StunPiercer", false));
        this.bbca_addTooltipLine(ret, 26, "Passive Counterattack (not vs. movement attacks)", this.bbca_getBool("PassiveCounterattack", false));
        return ret;
    }

    function bbca_canCounterattack( _attacker, _incomingSkill )
    {
        if (!this.bbca_getBool("PassiveCounterattack", false) || _attacker == null || _incomingSkill == null)
        {
            return false;
        }

        // A zone-of-control attack is executed with the attacker's ordinary
        // melee skill, so the skill alone cannot identify it. The actor hook
        // marks only the synchronous vanilla onAttackOfOpportunity call.
        if (("BBCA_PassiveCounterattack" in getroottable())
            && ::BBCA_PassiveCounterattack.isMovementAttack())
        {
            return false;
        }

        local container = this.getContainer();
        if (container == null)
        {
            return false;
        }

        local defender = container.getActor();
        if (defender == null)
        {
            return false;
        }

        try
        {
            return defender.isAlive()
                && defender.isPlacedOnMap()
                && _attacker.isAlive()
                && _attacker.isPlacedOnMap()
                && !_attacker.isAlliedWith(defender)
                && _attacker.getTile().getDistanceTo(defender.getTile()) == 1
                && _incomingSkill.isAttack()
                && !_incomingSkill.isIgnoringRiposte();
        }
        catch (exception)
        {
            return false;
        }
    }

    function bbca_scheduleCounterattack( _attacker, _incomingSkill )
    {
        if (!this.bbca_canCounterattack(_attacker, _incomingSkill))
        {
            return;
        }

        this.Time.scheduleEvent(this.TimeUnit.Virtual, this.Const.Combat.RiposteDelay, this.bbca_executeCounterattack.bindenv(this), {
            Attacker = _attacker
        });
    }

    function bbca_executeCounterattack( _info )
    {
        if (!this.bbca_getBool("PassiveCounterattack", false) || _info == null || !("Attacker" in _info))
        {
            return;
        }

        local container = this.getContainer();
        if (container == null)
        {
            return;
        }

        local defender = container.getActor();
        local attacker = _info.Attacker;
        if (defender == null || attacker == null)
        {
            return;
        }

        try
        {
            if (!defender.isAlive()
                || !defender.isPlacedOnMap()
                || !attacker.isAlive()
                || !attacker.isPlacedOnMap()
                || attacker.isAlliedWith(defender)
                || attacker.getTile().getDistanceTo(defender.getTile()) != 1)
            {
                return;
            }

            local counterSkill = defender.getSkills().getAttackOfOpportunity();
            if (counterSkill == null)
            {
                return;
            }

            // Reuse the vanilla Riposte execution guard and free-use path. The
            // actor-level SkillCounter permits at most one counter per incoming
            // skill execution and prevents two countering actors from looping.
            defender.onRiposte({
                User = defender,
                Skill = counterSkill,
                TargetTile = attacker.getTile()
            });
        }
        catch (exception)
        {
        }
    }

    function onMissed( _attacker, _skill )
    {
        this.bbca_scheduleCounterattack(_attacker, _skill);
    }

    function onBeforeDamageReceived( _attacker, _skill, _hitInfo, _properties )
    {
        this.bbca_scheduleCounterattack(_attacker, _skill);
    }

    function onUpdate( _properties )
    {
        this.m.IsHidden = !this.bbca_getBool("ShowStatusIcon", false);

        if (this.bbca_getBool("ImmuneToPoison", true))
        {
            _properties.IsImmuneToPoison = true;
        }
        if (this.bbca_getBool("ImmuneToBleeding", true))
        {
            _properties.IsImmuneToBleeding = true;
        }
        if (this.bbca_getBool("ImmuneToStun", true))
        {
            _properties.IsImmuneToStun = true;
        }
        if (this.bbca_getBool("ImmuneToDaze", true))
        {
            _properties.IsImmuneToDaze = true;
        }
        if (this.bbca_getBool("ImmuneToRoot", true))
        {
            _properties.IsImmuneToRoot = true;
        }
        if (this.bbca_getBool("ImmuneToKnockBackAndGrab", true))
        {
            _properties.IsImmuneToKnockBackAndGrab = true;
        }
        if (this.bbca_getBool("ImmuneToDisarm", true))
        {
            _properties.IsImmuneToDisarm = true;
        }
        if (this.bbca_getBool("ImmuneToRotation", false))
        {
            _properties.IsImmuneToRotation = true;
        }
        if (this.bbca_getBool("ImmuneToFire", false))
        {
            _properties.IsImmuneToFire = true;
        }
        if (this.bbca_getBool("ImmuneToHeadshots", false))
        {
            _properties.IsImmuneToHeadshots = true;
        }
        if (this.bbca_getBool("IgnoreInjuries", false))
        {
            _properties.IsAffectedByInjuries = false;
            _properties.IsAffectedByFreshInjuries = false;
        }
    }
});
