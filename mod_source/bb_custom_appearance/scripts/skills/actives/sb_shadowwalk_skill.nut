this.sb_shadowwalk_skill <- this.inherit("scripts/skills/skill", {
	m = {
		Cooldown = 9,
		Skillcool = 9,
		AllowWhileEngaged = true,
		AllowWhileRooted = true
	},
	function create()
	{
		this.m.ID = "actives.sb_shadowwalk_skill";
		this.m.Name = "Shadow Walk";
		this.m.Description = "Ignore zone of control and teleports to the target tile.";
		this.m.Icon = "ui/xx3.png";
		this.m.IconDisabled = "ui/xx3_sw.png";
		this.m.Overlay = "active_28";
		this.m.SoundOnUse = [
			"sounds/enemies/vampire_takeoff_01.wav",
			"sounds/enemies/vampire_takeoff_02.wav",
			"sounds/enemies/vampire_takeoff_03.wav"
		];
		this.m.SoundOnHit = [
			"sounds/enemies/vampire_landing_01.wav",
			"sounds/enemies/vampire_landing_02.wav",
			"sounds/enemies/vampire_landing_03.wav"
		];
		this.m.Type = this.Const.SkillType.Active;
		this.m.Order = this.Const.SkillOrder.OffensiveTargeted + 223;
		this.m.IsSerialized = true;
		this.m.IsActive = true;
		this.m.IsTargeted = true;
		this.m.IsTargetingActor = false;
		this.m.IsVisibleTileNeeded = false;
		this.m.IsStacking = false;
		this.m.IsAttack = false;
		this.m.IsIgnoredAsAOO = true;
		this.m.ActionPointCost = 4;
		this.m.FatigueCost = 30;
		this.m.MinRange = 1;
		this.m.MaxRange = 6;
		this.m.MaxLevelDifference = 1;
	}

	function bbca_getConfig()
	{
		local container = this.getContainer();
		if (container == null)
		{
			return null;
		}
		return container.getSkillByID("effects.bbca_shadowwalk_config");
	}

	function bbca_getNumber( _key, _fallback )
	{
		local config = this.bbca_getConfig();
		return config == null ? _fallback : config.m[_key];
	}

	function bbca_getBool( _key, _fallback )
	{
		local config = this.bbca_getConfig();
		return config == null ? _fallback : config.m[_key];
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

	function getTooltip()
	{
		local ret = this.getDefaultUtilityTooltip();
		ret.push({
			id = 4,
			type = "text",
			icon = "ui/icons/vision.png",
			text = "Has a range of " + this.getMaxRange() + " tiles"
		});
		ret.push({
			id = 5,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Cooldown: " + this.bbca_getNumber("Cooldown", this.m.Cooldown) + " turn \nCooldown left: [color=#8f1e1e]" + this.Math.max(0, (this.bbca_getNumber("Cooldown", this.m.Cooldown) - this.m.Skillcool)) + "[/color] turn"
		});
		if (!this.bbca_getBool("AllowWhileEngaged", this.m.AllowWhileEngaged) && this.Tactical.isActive() && this.getContainer().getActor().getTile().hasZoneOfControlOtherThan(this.getContainer().getActor().getAlliedFactions()))
		{
			ret.push({
				id = 9,
				type = "text",
				icon = "ui/tooltips/warning.png",
				text = "[color=" + this.Const.UI.Color.NegativeValue + "]Can not be used because this character is engaged in melee[/color]"
			});
		}
		return ret;
	}

	function onVerifyTarget( _originTile, _targetTile )
	{
		if (!_targetTile.IsEmpty)
		{
			return false;
		}

		return true;
	}

	function onUse( _user, _targetTile )
	{
		this.m.Skillcool = 0;
		local tag = {
			Skill = this,
			User = _user,
			TargetTile = _targetTile,
			OnDone = this.onTeleportDone,
			OnFadeIn = this.onFadeIn,
			OnFadeDone = this.onFadeDone,
			OnTeleportStart = this.onTeleportStart,
			IgnoreColors = false
		};

		if (!_user.isHiddenToPlayer() || _targetTile.IsVisibleForPlayer)
		{
			this.Tactical.EventLog.log(this.Const.UI.getColorizedEntityName(_user) + " uses Darkflight");
		}

		if (_user.getTile().IsVisibleForPlayer)
		{
			if (this.Const.Tactical.DarkflightStartParticles.len() != 0)
			{
				for( local i = 0; i < this.Const.Tactical.DarkflightStartParticles.len(); i = ++i )
				{
					this.Tactical.spawnParticleEffect(false, this.Const.Tactical.DarkflightStartParticles[i].Brushes, _user.getTile(), this.Const.Tactical.DarkflightStartParticles[i].Delay, this.Const.Tactical.DarkflightStartParticles[i].Quantity, this.Const.Tactical.DarkflightStartParticles[i].LifeTimeQuantity, this.Const.Tactical.DarkflightStartParticles[i].SpawnRate, this.Const.Tactical.DarkflightStartParticles[i].Stages);
				}
			}

			_user.storeSpriteColors();
			_user.fadeTo(this.createColor("00000000"), 400);
			this.Time.scheduleEvent(this.TimeUnit.Virtual, 400, this.onTeleportStart, tag);
		}
		else if (_targetTile.IsVisibleForPlayer)
		{
			_user.storeSpriteColors();
			_user.fadeTo(this.createColor("00000000"), 0);
			this.onTeleportStart(tag);
		}
		else
		{
			tag.IgnoreColors = true;
			this.onTeleportStart(tag);
		}

		return true;
	}

	function onTeleportStart( _tag )
	{

		this.Tactical.getNavigator().teleport(_tag.User, _tag.TargetTile, _tag.OnDone, _tag, false, 2.0);
	}

	function onTeleportDone( _entity, _tag )
	{
		if (!_entity.isHiddenToPlayer())
		{
			if (this.Const.Tactical.DarkflightEndParticles.len() != 0)
			{
				for( local i = 0; i < this.Const.Tactical.DarkflightEndParticles.len(); i = ++i )
				{
					this.Tactical.spawnParticleEffect(false, this.Const.Tactical.DarkflightEndParticles[i].Brushes, _entity.getTile(), this.Const.Tactical.DarkflightEndParticles[i].Delay, this.Const.Tactical.DarkflightEndParticles[i].Quantity, this.Const.Tactical.DarkflightEndParticles[i].LifeTimeQuantity, this.Const.Tactical.DarkflightEndParticles[i].SpawnRate, this.Const.Tactical.DarkflightEndParticles[i].Stages);
				}
			}

			this.Time.scheduleEvent(this.TimeUnit.Virtual, 800, _tag.OnFadeIn, _tag);

			if (_entity.getTile().IsVisibleForPlayer && _tag.Skill.m.SoundOnHit.len() > 0)
			{
				this.Sound.play(_tag.Skill.m.SoundOnHit[this.Math.rand(0, _tag.Skill.m.SoundOnHit.len() - 1)], this.Const.Sound.Volume.Skill, _entity.getPos());
			}

			if (this.Time.getRound() == 777)
			{
				this.Tactical.CameraDirector.addMoveSlowlyToTileEvent(1, _tag.TargetTile);
			}
			else
			{
				this.Tactical.CameraDirector.addMoveToTileEvent(1, _tag.TargetTile);
			}
			this.Tactical.CameraDirector.addDelay(0.5);
		}
		else
		{
			_tag.OnFadeIn(_tag);
		}
	}

	function onFadeIn( _tag )
	{
		if (!_tag.IgnoreColors)
		{
			if (_tag.User.isHiddenToPlayer())
			{
				_tag.User.restoreSpriteColors();
			}
			else
			{
				_tag.User.fadeToStoredColors(500);
				this.Time.scheduleEvent(this.TimeUnit.Virtual, 500, _tag.OnFadeDone, _tag);
			}
		}
	}

	function onFadeDone( _tag )
	{
		_tag.User.restoreSpriteColors();
	}

	function isUsable()
	{
		if (!this.skill.isUsable())
		{
			return false;
		}
		else
		if (this.m.Skillcool < this.bbca_getNumber("Cooldown", this.m.Cooldown))
		{
			return false;
		}
		else
		if (!this.bbca_getBool("AllowWhileEngaged", this.m.AllowWhileEngaged) && this.getContainer().getActor().getTile().hasZoneOfControlOtherThan(this.getContainer().getActor().getAlliedFactions()))
		{
			return false;
		}
		else
		if (!this.bbca_getBool("AllowWhileRooted", this.m.AllowWhileRooted) && this.getContainer().getActor().getCurrentProperties().IsRooted)
		{
			return false;
		}

		return true;
	}

	function onTurnStart()
	{
		this.m.Skillcool = this.m.Skillcool + 1;
	}

	function onCombatFinished()
	{
		this.m.Skillcool = this.bbca_getNumber("Cooldown", this.m.Cooldown);
	}

});

