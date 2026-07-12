// Keep the current vanilla attack flow and only widen the 5-95 hit chance caps
// to 0-100. Queueing the hook makes this override older standalone copies.

::mods_registerMod("mod_bbca_hitchance", 1.0, "BBCA Hit Chance 0-100");

::BBCA_StunPiercer <- {
	AllowedSkillIDs = [
		"actives.knock_out",
		"actives.knock_over",
		"actives.strike_down",
		"actives.overhead_strike",
		"actives.pound",
		"actives.thresh"
	],
	ContextStack = [],
	MarkedStuns = [],

	function isAllowedSkill( _skillID )
	{
		return this.AllowedSkillIDs.find(_skillID) != null;
	},

	function isEnabledForUser( _user )
	{
		if (_user == null || !_user.isPlayerControlled())
		{
			return false;
		}

		local skills = _user.getSkills();
		if (skills == null || !skills.hasSkill("effects.bbca_negative_immunity"))
		{
			return false;
		}

		local config = skills.getSkillByID("effects.bbca_negative_immunity_config");
		return config != null && "StunPiercer" in config.m && config.m.StunPiercer;
	},

	function getTopContext()
	{
		return this.ContextStack.len() == 0 ? null : this.ContextStack.top();
	},

	function rememberProperties( _record, _properties )
	{
		foreach (properties in _record.TouchedProperties)
		{
			if (properties == _properties)
			{
				return;
			}
		}

		_record.TouchedProperties.push(_properties);
	},

	function applyRecord( _record )
	{
		try
		{
			local properties = _record.Target.getCurrentProperties();
			this.rememberProperties(_record, properties);
			properties.IsImmuneToStun = false;
		}
		catch (exception)
		{
		}
	},

	function restoreRecord( _record )
	{
		foreach (properties in _record.TouchedProperties)
		{
			try
			{
				properties.IsImmuneToStun = _record.OriginalIsImmuneToStun;
			}
			catch (exception)
			{
			}
		}

		try
		{
			_record.Target.getCurrentProperties().IsImmuneToStun = _record.OriginalIsImmuneToStun;
		}
		catch (exception)
		{
		}
	},

	function suspendContext( _context )
	{
		foreach (record in _context.Targets)
		{
			this.restoreRecord(record);
		}
	},

	function resumeContext( _context )
	{
		if (!_context.Enabled)
		{
			return;
		}

		foreach (record in _context.Targets)
		{
			this.applyRecord(record);
		}
	},

	function beginUse( _skill )
	{
		local parent = this.getTopContext();
		if (parent != null)
		{
			this.suspendContext(parent);
		}

		local context = {
			Skill = _skill,
			User = null,
			Enabled = false,
			Targets = []
		};
		this.ContextStack.push(context);

		try
		{
			if (!this.isAllowedSkill(_skill.getID()))
			{
				return context;
			}

			local container = _skill.getContainer();
			if (container == null)
			{
				return context;
			}

			local user = container.getActor();
			if (!this.isEnabledForUser(user))
			{
				return context;
			}

			context.User = user;
			context.Enabled = true;
		}
		catch (exception)
		{
			context.Enabled = false;
		}

		return context;
	},

	function finishUse( _context )
	{
		this.suspendContext(_context);

		if (this.ContextStack.len() != 0 && this.ContextStack.top() == _context)
		{
			this.ContextStack.pop();
		}
		else
		{
			for (local i = this.ContextStack.len() - 1; i >= 0; --i)
			{
				if (this.ContextStack[i] == _context)
				{
					this.ContextStack.remove(i);
					break;
				}
			}
		}

		local parent = this.getTopContext();
		if (parent != null)
		{
			this.resumeContext(parent);
		}
	},

	function canOpenTarget( _context, _target )
	{
		if (!_context.Enabled || _target == null)
		{
			return false;
		}

		if (!_target.isAlive() || _target.isDying() || !_target.isAttackable() || _target.isNonCombatant())
		{
			return false;
		}

		if (_context.User.isAlliedWith(_target))
		{
			return false;
		}

		local current = _target.getCurrentProperties();
		if (!current.IsImmuneToStun || !current.IsMovable)
		{
			return false;
		}

		local skills = _target.getSkills();
		if (skills == null || skills.hasSkill("effects.indomitable"))
		{
			return false;
		}

		return true;
	},

	function openTarget( _user, _skill, _target )
	{
		local context = this.getTopContext();
		if (context == null || context.Skill != _skill || context.User != _user || !this.canOpenTarget(context, _target))
		{
			return;
		}

		foreach (record in context.Targets)
		{
			if (record.Target == _target)
			{
				this.applyRecord(record);
				return;
			}
		}

		local properties = _target.getCurrentProperties();
		local record = {
			Target = _target,
			OriginalIsImmuneToStun = properties.IsImmuneToStun,
			TouchedProperties = [properties]
		};
		context.Targets.push(record);
		properties.IsImmuneToStun = false;
	},

	function isPiercingTarget( _target )
	{
		local context = this.getTopContext();
		if (context == null || !context.Enabled)
		{
			return false;
		}

		foreach (record in context.Targets)
		{
			if (record.Target == _target)
			{
				return true;
			}
		}

		return false;
	},

	function markStun( _effect )
	{
		foreach (effect in this.MarkedStuns)
		{
			if (effect == _effect)
			{
				return;
			}
		}

		this.MarkedStuns.push(_effect);
	},

	function isMarkedStun( _effect )
	{
		foreach (effect in this.MarkedStuns)
		{
			if (effect == _effect)
			{
				return true;
			}
		}

		return false;
	},

	function forgetStun( _effect )
	{
		for (local i = this.MarkedStuns.len() - 1; i >= 0; --i)
		{
			if (this.MarkedStuns[i] == _effect)
			{
				this.MarkedStuns.remove(i);
				return;
			}
		}
	}
};

::BBCA_HardChance <- {
	function getSettings( _actor )
	{
		if (_actor == null)
		{
			return null;
		}

		try
		{
			local skills = _actor.getSkills();
			if (skills == null)
			{
				return null;
			}

			local effect = skills.getSkillByID("effects.bbca_hard_chance");
			if (effect == null)
			{
				return null;
			}

			local config = skills.getSkillByID("effects.bbca_hard_chance_config");
			return config == null ? effect : config;
		}
		catch (exception)
		{
			return null;
		}
	},

	function getNumber( _actor, _key )
	{
		local settings = this.getSettings(_actor);
		if (settings == null || !(_key in settings.m))
		{
			return 0;
		}

		local value = settings.m[_key].tointeger();
		if (value < 0)
		{
			return 0;
		}
		if (value > 100)
		{
			return 100;
		}
		return value;
	},

	function hasAbsoluteHit( _actor )
	{
		return this.getNumber(_actor, "HardHitChance") >= 100;
	},

	function hasAbsoluteEvasion( _actor )
	{
		return this.getNumber(_actor, "HardEvasionChance") >= 100;
	},

	function apply( _toHit, _user, _target )
	{
		// A configured value of 100 is a hard outcome rather than another
		// additive modifier. Evasion wins if both actors have an absolute
		// setting so HardEvasionChance = 100 always means a true dodge.
		if (this.hasAbsoluteEvasion(_target))
		{
			return 0;
		}

		if (this.hasAbsoluteHit(_user))
		{
			return 100;
		}

		return _toHit + this.getNumber(_user, "HardHitChance") - this.getNumber(_target, "HardEvasionChance");
	}
};

::mods_queue("mod_bbca_hitchance", null, function() {
::mods_hookClass("skills/skill", function(o) {
	local bbca_useClass = o;
	while (!("use" in bbca_useClass)) bbca_useClass = bbca_useClass[bbca_useClass.SuperName];
	if (!("bbca_stun_piercer_use_hook" in bbca_useClass))
	{
		bbca_useClass.bbca_stun_piercer_use_hook <- true;
		local bbca_originalUse = bbca_useClass.use;
		bbca_useClass.use = function( _targetTile, _forFree = false )
		{
			local context = ::BBCA_StunPiercer.beginUse(this);

			try
			{
				local result = bbca_originalUse.call(this, _targetTile, _forFree);
				::BBCA_StunPiercer.finishUse(context);
				return result;
			}
			catch (exception)
			{
				::BBCA_StunPiercer.finishUse(context);
				throw exception;
			}
		}
	}

	while (!("attackEntity" in o)) o = o[o.SuperName];
	o.attackEntity = function( _user, _targetEntity, _allowDiversion = true )
	{
		if (_targetEntity != null && !_targetEntity.isAlive())
		{
			return false;
		}

		local properties = this.m.Container.buildPropertiesForUse(this, _targetEntity);
		local userTile = _user.getTile();
		local astray = false;

		if (_allowDiversion && this.m.IsRanged && userTile.getDistanceTo(_targetEntity.getTile()) > 1)
		{
			local blockedTiles = this.Const.Tactical.Common.getBlockedTiles(userTile, _targetEntity.getTile(), _user.getFaction());

			if (blockedTiles.len() != 0 && this.Math.rand(1, 100) <= this.Math.ceil(this.Const.Combat.RangedAttackBlockedChance * properties.RangedAttackBlockedChanceMult * 100))
			{
				_allowDiversion = false;
				astray = true;
				_targetEntity = blockedTiles[this.Math.rand(0, blockedTiles.len() - 1)].getEntity();
			}
		}

		if (!_targetEntity.isAttackable())
		{
			if (this.m.IsShowingProjectile && this.m.ProjectileType != 0)
			{
				local flip = !this.m.IsProjectileRotated && _targetEntity.getPos().X > _user.getPos().X;

				if (_user.getTile().getDistanceTo(_targetEntity.getTile()) >= this.Const.Combat.SpawnProjectileMinDist)
				{
					this.Tactical.spawnProjectileEffect(this.Const.ProjectileSprite[this.m.ProjectileType], _user.getTile(), _targetEntity.getTile(), 1.0, this.m.ProjectileTimeScale, this.m.IsProjectileRotated, flip);
				}
			}

			return false;
		}

		local defenderProperties = _targetEntity.getSkills().buildPropertiesForDefense(_user, this);
		local defense = _targetEntity.getDefense(_user, this, defenderProperties);
		local levelDifference = _targetEntity.getTile().Level - _user.getTile().Level;
		local distanceToTarget = _user.getTile().getDistanceTo(_targetEntity.getTile());
		local toHit = 0;
		local skill = this.m.IsRanged ? properties.RangedSkill * properties.RangedSkillMult : properties.MeleeSkill * properties.MeleeSkillMult;
		toHit = toHit + skill;
		toHit = toHit - defense;

		if (this.m.IsRanged)
		{
			toHit = toHit + (distanceToTarget - this.m.MinRange) * properties.HitChanceAdditionalWithEachTile * properties.HitChanceWithEachTileMult;
		}

		if (levelDifference < 0)
		{
			toHit = toHit + this.Const.Combat.LevelDifferenceToHitBonus;
		}
		else
		{
			toHit = toHit + this.Const.Combat.LevelDifferenceToHitMalus * levelDifference;
		}

		local shieldBonus = 0;
		local shield = _targetEntity.getItems().getItemAtSlot(this.Const.ItemSlot.Offhand);

		if (shield != null && shield.isItemType(this.Const.Items.ItemType.Shield))
		{
			shieldBonus = (this.m.IsRanged ? shield.getRangedDefense() : shield.getMeleeDefense()) * (_targetEntity.getCurrentProperties().IsSpecializedInShields ? 1.25 : 1.0);

			if (_targetEntity.getSkills().hasSkill("effects.shieldwall"))
			{
				shieldBonus = shieldBonus * 2;
			}
		}

		toHit = toHit * properties.TotalAttackToHitMult;
		toHit = toHit + this.Math.max(0, 100 - toHit) * (1.0 - defenderProperties.TotalDefenseToHitMult);

		if (this.m.IsRanged && !_allowDiversion && this.m.IsShowingProjectile)
		{
			toHit = toHit + properties.HitChanceOnDiversion;
			properties.DamageTotalMult *= properties.DamageTotalOnDiversionMult;
		}

		if (defense > -100 && skill > -100)
		{
			toHit = ::BBCA_HardChance.apply(toHit, _user, _targetEntity);
			toHit = this.Math.max(0, this.Math.min(100, toHit));
		}

		_targetEntity.onAttacked(_user);

		if (this.m.IsDoingAttackMove && !_user.isHiddenToPlayer() && !_targetEntity.isHiddenToPlayer())
		{
			this.Tactical.getShaker().cancel(_user);

			if (this.m.IsDoingForwardMove)
			{
				this.Tactical.getShaker().shake(_user, _targetEntity.getTile(), 5);
			}
			else
			{
				local otherDir = _targetEntity.getTile().getDirectionTo(_user.getTile());

				if (_user.getTile().hasNextTile(otherDir))
				{
					this.Tactical.getShaker().shake(_user, _user.getTile().getNextTile(otherDir), 6);
				}
			}
		}

		if (!_targetEntity.isAbleToDie() && _targetEntity.getHitpoints() == 1)
		{
			toHit = 0;
		}

		if (!this.isUsingHitchance())
		{
			toHit = 100;
		}

		// isUsingHitchance() == false normally forces 100 after the regular
		// Hard Chance calculation. Keep absolute evasion as the final word.
		if (::BBCA_HardChance.hasAbsoluteEvasion(_targetEntity))
		{
			toHit = 0;
		}

		local r = this.Math.rand(1, 100);

		if (("Assets" in this.World) && this.World.Assets != null && this.World.Assets.getCombatDifficulty() == 0)
		{
			if (_user.isPlayerControlled())
			{
				r = this.Math.max(1, r - 5);
			}
			else if (_targetEntity.isPlayerControlled())
			{
				r = this.Math.min(100, r + 5);
			}
		}

		local isHit = r <= toHit;

		if (!_user.isHiddenToPlayer() && !_targetEntity.isHiddenToPlayer())
		{
			local rolled = r;
			this.Tactical.EventLog.log_newline();

			if (astray)
			{
				if (this.isUsingHitchance())
				{
					if (isHit)
					{
						this.Tactical.EventLog.logEx(this.Const.UI.getColorizedEntityName(_user) + " uses " + this.getName() + " and the shot goes astray and hits " + this.Const.UI.getColorizedEntityName(_targetEntity) + " (Chance: " + this.Math.min(100, this.Math.max(0, toHit)) + ", Rolled: " + rolled + ")");
					}
					else
					{
						this.Tactical.EventLog.logEx(this.Const.UI.getColorizedEntityName(_user) + " uses " + this.getName() + " and the shot goes astray and misses " + this.Const.UI.getColorizedEntityName(_targetEntity) + " (Chance: " + this.Math.min(100, this.Math.max(0, toHit)) + ", Rolled: " + rolled + ")");
					}
				}
				else
				{
					this.Tactical.EventLog.logEx(this.Const.UI.getColorizedEntityName(_user) + " uses " + this.getName() + " and the shot goes astray and hits " + this.Const.UI.getColorizedEntityName(_targetEntity));
				}
			}
			else if (this.isUsingHitchance())
			{
				if (isHit)
				{
					this.Tactical.EventLog.logEx(this.Const.UI.getColorizedEntityName(_user) + " uses " + this.getName() + " and hits " + this.Const.UI.getColorizedEntityName(_targetEntity) + " (Chance: " + this.Math.min(100, this.Math.max(0, toHit)) + ", Rolled: " + rolled + ")");
				}
				else
				{
					this.Tactical.EventLog.logEx(this.Const.UI.getColorizedEntityName(_user) + " uses " + this.getName() + " and misses " + this.Const.UI.getColorizedEntityName(_targetEntity) + " (Chance: " + this.Math.min(100, this.Math.max(0, toHit)) + ", Rolled: " + rolled + ")");
				}
			}
			else
			{
				this.Tactical.EventLog.logEx(this.Const.UI.getColorizedEntityName(_user) + " uses " + this.getName() + " and hits " + this.Const.UI.getColorizedEntityName(_targetEntity));
			}
		}

		if (isHit && this.Math.rand(1, 100) <= _targetEntity.getCurrentProperties().RerollDefenseChance)
		{
			r = this.Math.rand(1, 100);
			isHit = r <= toHit;
		}

		if (isHit)
		{
			this.getContainer().setBusy(true);
			local info = {
				Skill = this,
				Container = this.getContainer(),
				User = _user,
				TargetEntity = _targetEntity,
				Properties = properties,
				DistanceToTarget = distanceToTarget
			};

			if (this.m.IsShowingProjectile && this.m.ProjectileType != 0 && _user.getTile().getDistanceTo(_targetEntity.getTile()) >= this.Const.Combat.SpawnProjectileMinDist && (!_user.isHiddenToPlayer() || !_targetEntity.isHiddenToPlayer()))
			{
				local flip = !this.m.IsProjectileRotated && _targetEntity.getPos().X > _user.getPos().X;
				local time = this.Tactical.spawnProjectileEffect(this.Const.ProjectileSprite[this.m.ProjectileType], _user.getTile(), _targetEntity.getTile(), 1.0, this.m.ProjectileTimeScale, this.m.IsProjectileRotated, flip);
				this.Time.scheduleEvent(this.TimeUnit.Virtual, time, this.onScheduledTargetHit, info);

				if (this.m.SoundOnHit.len() != 0)
				{
					this.Time.scheduleEvent(this.TimeUnit.Virtual, time + this.m.SoundOnHitDelay, this.onPlayHitSound.bindenv(this), {
						Sound = this.m.SoundOnHit[this.Math.rand(0, this.m.SoundOnHit.len() - 1)],
						Pos = _targetEntity.getPos()
					});
				}
			}
			else
			{
				if (this.m.SoundOnHit.len() != 0)
				{
					this.Sound.play(this.m.SoundOnHit[this.Math.rand(0, this.m.SoundOnHit.len() - 1)], this.Const.Sound.Volume.Skill * this.m.SoundVolume, _targetEntity.getPos());
				}

				if (this.Tactical.State.getStrategicProperties() != null && this.Tactical.State.getStrategicProperties().IsArenaMode && toHit <= 15)
				{
					this.Sound.play(this.Const.Sound.ArenaShock[this.Math.rand(0, this.Const.Sound.ArenaShock.len() - 1)], this.Const.Sound.Volume.Tactical * this.Const.Sound.Volume.Arena);
				}

				this.onScheduledTargetHit(info);
				::BBCA_StunPiercer.openTarget(_user, this, _targetEntity);
			}

			return true;
		}
		else
		{
			local distanceToTarget = _user.getTile().getDistanceTo(_targetEntity.getTile());
			_targetEntity.onMissed(_user, this, this.m.IsShieldRelevant && shield != null && r <= toHit + shieldBonus * 2);
			this.m.Container.onTargetMissed(this, _targetEntity);
			local prohibitDiversion = false;

			if (_allowDiversion && this.m.IsRanged && !_user.isPlayerControlled() && this.Math.rand(1, 100) <= 25 && distanceToTarget > 2)
			{
				local targetTile = _targetEntity.getTile();

				for (local i = 0; i < this.Const.Direction.COUNT; i = ++i)
				{
					if (!targetTile.hasNextTile(i))
					{
					}
					else
					{
						local tile = targetTile.getNextTile(i);

						if (tile.IsEmpty)
						{
						}
						else if (tile.IsOccupiedByActor && tile.getEntity().isAlliedWith(_user))
						{
							prohibitDiversion = true;
							break;
						}
					}
				}
			}

			if (_allowDiversion && this.m.IsRanged && !(this.m.IsShieldRelevant && shield != null && r <= toHit + shieldBonus * 2) && !prohibitDiversion && distanceToTarget > 2)
			{
				this.divertAttack(_user, _targetEntity);
			}
			else if (this.m.IsShieldRelevant && shield != null && r <= toHit + shieldBonus * 2)
			{
				local info = {
					Skill = this,
					User = _user,
					TargetEntity = _targetEntity,
					Shield = shield
				};

				if (this.m.IsShowingProjectile && this.m.ProjectileType != 0)
				{
					local divertTile = _targetEntity.getTile();
					local flip = !this.m.IsProjectileRotated && _targetEntity.getPos().X > _user.getPos().X;
					local time = 0;

					if (_user.getTile().getDistanceTo(divertTile) >= this.Const.Combat.SpawnProjectileMinDist)
					{
						time = this.Tactical.spawnProjectileEffect(this.Const.ProjectileSprite[this.m.ProjectileType], _user.getTile(), divertTile, 1.0, this.m.ProjectileTimeScale, this.m.IsProjectileRotated, flip);
					}

					this.Time.scheduleEvent(this.TimeUnit.Virtual, time, this.onShieldHit, info);
				}
				else
				{
					this.onShieldHit(info);
				}
			}
			else
			{
				if (this.m.SoundOnMiss.len() != 0)
				{
					this.Sound.play(this.m.SoundOnMiss[this.Math.rand(0, this.m.SoundOnMiss.len() - 1)], this.Const.Sound.Volume.Skill * this.m.SoundVolume, _targetEntity.getPos());
				}

				if (this.m.IsShowingProjectile && this.m.ProjectileType != 0)
				{
					local divertTile = _targetEntity.getTile();
					local flip = !this.m.IsProjectileRotated && _targetEntity.getPos().X > _user.getPos().X;

					if (_user.getTile().getDistanceTo(divertTile) >= this.Const.Combat.SpawnProjectileMinDist)
					{
						this.Tactical.spawnProjectileEffect(this.Const.ProjectileSprite[this.m.ProjectileType], _user.getTile(), divertTile, 1.0, this.m.ProjectileTimeScale, this.m.IsProjectileRotated, flip);
					}
				}

				if (this.Tactical.State.getStrategicProperties() != null && this.Tactical.State.getStrategicProperties().IsArenaMode)
				{
					if (toHit >= 90 || _targetEntity.getHitpointsPct() <= 0.1)
					{
						this.Sound.play(this.Const.Sound.ArenaMiss[this.Math.rand(0, this.Const.Sound.ArenaBigMiss.len() - 1)], this.Const.Sound.Volume.Tactical * this.Const.Sound.Volume.Arena);
					}
					else if (this.Math.rand(1, 100) <= 20)
					{
						this.Sound.play(this.Const.Sound.ArenaMiss[this.Math.rand(0, this.Const.Sound.ArenaMiss.len() - 1)], this.Const.Sound.Volume.Tactical * this.Const.Sound.Volume.Arena);
					}
				}
			}

			return false;
		}
	}

	while (!("getHitchance" in o)) o = o[o.SuperName];
	if (!("hitchance_caps" in o))
	{
		o.hitchance_caps <- true;
		o.getHitchance = function( _targetEntity )
		{
			if (!_targetEntity.isAttackable())
			{
				return 0;
			}

			local user = this.m.Container.getActor();
			local properties = this.m.Container.buildPropertiesForUse(this, _targetEntity);

			if (!this.isUsingHitchance())
			{
				return ::BBCA_HardChance.hasAbsoluteEvasion(_targetEntity) ? 0 : 100;
			}

			local allowDiversion = this.m.IsRanged && this.m.MaxRangeBonus > 1;
			local defenderProperties = _targetEntity.getSkills().buildPropertiesForDefense(user, this);
			local skill = this.m.IsRanged ? properties.RangedSkill * properties.RangedSkillMult : properties.MeleeSkill * properties.MeleeSkillMult;
			local defense = _targetEntity.getDefense(user, this, defenderProperties);
			local levelDifference = _targetEntity.getTile().Level - user.getTile().Level;
			local distanceToTarget = user.getTile().getDistanceTo(_targetEntity.getTile());
			local toHit = skill - defense;

			if (this.m.IsRanged)
			{
				toHit = toHit + (distanceToTarget - this.m.MinRange) * properties.HitChanceAdditionalWithEachTile * properties.HitChanceWithEachTileMult;
			}

			if (levelDifference < 0)
			{
				toHit = toHit + this.Const.Combat.LevelDifferenceToHitBonus;
			}
			else
			{
				toHit = toHit + this.Const.Combat.LevelDifferenceToHitMalus * levelDifference;
			}

			toHit = toHit * properties.TotalAttackToHitMult;
			toHit = toHit + this.Math.max(0, 100 - toHit) * (1.0 - defenderProperties.TotalDefenseToHitMult);
			local userTile = user.getTile();

			if (allowDiversion && this.m.IsRanged && userTile.getDistanceTo(_targetEntity.getTile()) > 1)
			{
				local blockedTiles = this.Const.Tactical.Common.getBlockedTiles(userTile, _targetEntity.getTile(), user.getFaction(), true);

				if (blockedTiles.len() != 0)
				{
					local blockChance = this.Const.Combat.RangedAttackBlockedChance * properties.RangedAttackBlockedChanceMult;
					toHit = this.Math.floor(toHit * (1.0 - blockChance));
				}
			}

			toHit = ::BBCA_HardChance.apply(toHit, user, _targetEntity);
			return this.Math.max(0, this.Math.min(100, toHit));
		}
	}
});

::mods_hookClass("skills/effects/stunned_effect", function(o) {
	local bbca_originalOnAdded = o.onAdded;
	o.onAdded = function()
	{
		local actor = this.getContainer().getActor();
		if (!::BBCA_StunPiercer.isMarkedStun(this) && ::BBCA_StunPiercer.isPiercingTarget(actor))
		{
			::BBCA_StunPiercer.markStun(this);
		}

		if (!::BBCA_StunPiercer.isMarkedStun(this))
		{
			return bbca_originalOnAdded.call(this);
		}

		local properties = actor.getCurrentProperties();
		local originalIsImmuneToStun = properties.IsImmuneToStun;
		properties.IsImmuneToStun = false;

		try
		{
			local result = bbca_originalOnAdded.call(this);
			properties.IsImmuneToStun = originalIsImmuneToStun;
			return result;
		}
		catch (exception)
		{
			properties.IsImmuneToStun = originalIsImmuneToStun;
			throw exception;
		}
	}

	local bbca_originalOnUpdate = o.onUpdate;
	o.onUpdate = function( _properties )
	{
		if (!::BBCA_StunPiercer.isMarkedStun(this))
		{
			return bbca_originalOnUpdate.call(this, _properties);
		}

		local actor = this.getContainer().getActor();
		local current = actor.getCurrentProperties();
		local originalIsImmuneToStun = current.IsImmuneToStun;
		current.IsImmuneToStun = false;

		try
		{
			local result = bbca_originalOnUpdate.call(this, _properties);
			current.IsImmuneToStun = originalIsImmuneToStun;
			return result;
		}
		catch (exception)
		{
			current.IsImmuneToStun = originalIsImmuneToStun;
			throw exception;
		}
	}

	local bbca_originalOnRemoved = o.onRemoved;
	o.onRemoved = function()
	{
		::BBCA_StunPiercer.forgetStun(this);
		return bbca_originalOnRemoved.call(this);
	}
});
});

