// __BBCA_CATALOG__

::BBCA_SkillCatalog <- [
    {
        ID = "actives.sb_shadowwalk_skill",
        Script = "scripts/skills/actives/sb_shadowwalk_skill",
        ConfigID = "effects.bbca_shadowwalk_config",
        ConfigScript = "scripts/skills/effects/bbca_shadowwalk_config_skill",
        Label = "Shadow Walk",
        Description = "暗影行走：传送至范围内的空地。可越过目标格的控制区；默认可在缠斗或定身时发动，也可在下方关闭这两项许可。",
        Parameters = [
            { Key = "ActionPointCost", Label = "行动点消耗 (AP)", Default = 4, Min = 0, Max = 9 },
            { Key = "FatigueCost", Label = "疲劳消耗", Default = 30, Min = 0, Max = 200 },
            { Key = "MinRange", Label = "最小距离", Default = 1, Min = 1, Max = 20 },
            { Key = "MaxRange", Label = "最大距离", Default = 6, Min = 1, Max = 20 },
            { Key = "MaxLevelDifference", Label = "最大高度差", Default = 1, Min = 0, Max = 10 },
            { Key = "Cooldown", Label = "冷却回合", Default = 9, Min = 0, Max = 99 },
            { Key = "AllowWhileEngaged", Label = "缠斗时可用", Type = "bool", Default = true },
            { Key = "AllowWhileRooted", Label = "定身时可用", Type = "bool", Default = true }
        ]
    },
    {
        ID = "actives.bbca_fire_grenade",
        Script = "scripts/skills/actives/bbca_fire_grenade_skill",
        Type = "active",
        ConfigID = "effects.bbca_fire_grenade_config",
        ConfigScript = "scripts/skills/effects/bbca_fire_grenade_config_skill",
        Label = "燃烧手雷 (Fire Grenade)",
        Description = "投掷一枚不会消耗物品的燃烧手雷，使目标格及可调半径内的地格燃烧。火焰会立即伤害格内单位，并在回合结束时继续伤害敌我双方。",
        Icons = ["skills/active_209.png", "skills/active_209_sw.png"],
        Effects = ["vanilla.fire_tile"],
        SerializationVersion = 2,
        MigrationNote = "v1 配置读取时将新增的燃烧半径设为默认值 2；保存参数后写入 v2。",
        Parameters = [
            { Key = "ActionPointCost", Label = "行动点消耗 (AP)", Default = 6, Min = 0, Max = 9 },
            { Key = "FatigueCost", Label = "疲劳消耗", Default = 35, Min = 0, Max = 200 },
            { Key = "MinRange", Label = "最小投掷距离", Default = 2, Min = 1, Max = 20 },
            { Key = "MaxRange", Label = "最大投掷距离", Default = 4, Min = 1, Max = 20 },
            { Key = "MaxLevelDifference", Label = "最大高度差", Default = 1, Min = 0, Max = 10 },
            { Key = "Cooldown", Label = "冷却回合", Default = 7, Min = 0, Max = 99 },
            { Key = "FireDuration", Label = "火焰持续回合", Default = 2, Min = 1, Max = 5 },
            { Key = "AreaRadius", Label = "燃烧半径", Default = 2, Min = 0, Max = 4 }
        ]
    },
    {
        ID = "actives.bbca_summon_zombie",
        Script = "scripts/skills/actives/bbca_summon_zombie_skill",
        Type = "active",
        ConfigID = "effects.bbca_summon_zombie_config",
        ConfigScript = "scripts/skills/effects/bbca_summon_zombie_config_skill",
        Label = "召唤装甲复生者 (Summon Zombie)",
        Description = "在附近可见空地召唤一个由友方 AI 控制的装甲复生者。召唤物禁止自动复活，战斗结束后消失；每名施法者默认最多同时维持 3 个。",
        Icons = ["ui/bbca_summon_zombie.png", "ui/bbca_summon_zombie_sw.png"],
        Entities = ["scripts/entity/tactical/enemies/zombie_yeoman"],
        SerializationVersion = 1,
        MigrationNote = "新技能；旧存档无同名配置。首次授予时创建 v1 配置。",
        Parameters = [
            { Key = "ActionPointCost", Label = "行动点消耗 (AP)", Default = 6, Min = 0, Max = 9 },
            { Key = "FatigueCost", Label = "疲劳消耗", Default = 25, Min = 0, Max = 200 },
            { Key = "MaxRange", Label = "最大召唤距离", Default = 3, Min = 1, Max = 10 },
            { Key = "MaxLevelDifference", Label = "最大高度差", Default = 1, Min = 0, Max = 10 },
            { Key = "Cooldown", Label = "冷却回合", Default = 5, Min = 0, Max = 99 },
            { Key = "MaxActiveSummons", Label = "最多维持数量", Default = 3, Min = 1, Max = 12 }
        ]
    },
    {
        ID = "effects.bbca_negative_immunity",
        Script = "scripts/skills/effects/bbca_negative_immunity_skill",
        Type = "passive",
        ConfigID = "effects.bbca_negative_immunity_config",
        ConfigScript = "scripts/skills/effects/bbca_negative_immunity_config_skill",
        Label = "异常免疫 (Aegis)",
        Description = "被动技能：按下方开关免疫常见负面效果。默认不在战斗状态栏显示，只作为隐藏被动生效。战斗内状态名显示为英文 Aegis（游戏战斗界面字体不含中文）。",
        Effects = ["vanilla.overwhelmed", "vanilla.distracted", "vanilla.swallow_whole"],
        SerializationVersion = 6,
        MigrationNote = "v1-v3 配置读取时新增的食尸鬼吞噬免疫默认为关闭；v1-v4 读取时眩晕穿透默认为关闭；v1-v5 读取时被动反击默认为关闭；保存参数后写入 v6。",
        Parameters = [
            { Key = "ShowStatusIcon", Label = "显示状态图标", Type = "bool", Default = false },
            { Key = "ImmuneToPoison", Label = "免疫中毒", Type = "bool", Default = true },
            { Key = "ImmuneToBleeding", Label = "免疫流血", Type = "bool", Default = true },
            { Key = "ImmuneToStun", Label = "免疫昏迷", Type = "bool", Default = true },
            { Key = "ImmuneToDaze", Label = "免疫茫然", Type = "bool", Default = true },
            { Key = "ImmuneToRoot", Label = "免疫定身/网", Type = "bool", Default = true },
            { Key = "ImmuneToKnockBackAndGrab", Label = "免疫击退/抓取", Type = "bool", Default = true },
            { Key = "ImmuneToDisarm", Label = "免疫缴械", Type = "bool", Default = true },
            { Key = "ImmuneToRotation", Label = "免疫换位", Type = "bool", Default = false },
            { Key = "ImmuneToFire", Label = "免疫火焰", Type = "bool", Default = false },
            { Key = "ImmuneToHeadshots", Label = "免疫爆头", Type = "bool", Default = false },
            { Key = "IgnoreInjuries", Label = "不受伤残影响", Type = "bool", Default = false },
            { Key = "ImmuneToOverwhelmed", Label = "免疫压制（Overwhelm减命中）", Type = "bool", Default = false },
            { Key = "ImmuneToDistracted", Label = "免疫分心（Distracted减伤/先攻）", Type = "bool", Default = false },
            { Key = "ImmuneToSwallowWhole", Label = "免疫吞噬（最高级食尸鬼）", Type = "bool", Default = false },
            { Key = "StunPiercer", Label = "眩晕穿透 (Stun Piercer)", Type = "bool", Default = false },
            { Key = "PassiveCounterattack", Label = "被动反击（移动触发攻击不反击）", Type = "bool", Default = false }
        ]
    },
    {
        ID = "effects.bbca_hard_chance",
        Script = "scripts/skills/effects/bbca_hard_chance_skill",
        Type = "passive",
        ConfigID = "effects.bbca_hard_chance_config",
        ConfigScript = "scripts/skills/effects/bbca_hard_chance_config_skill",
        Label = "Hard Chance",
        Description = "Passive skill: adds a flat final hit chance bonus when attacking, subtracts a flat final hit chance bonus from enemies attacking this character, and resets current fatigue to 0 at the start of each turn. The status icon is hidden by default.",
        SerializationVersion = 1,
        Parameters = [
            { Key = "ShowStatusIcon", Label = "Show Status Icon", Type = "bool", Default = false },
            { Key = "HardHitChance", Label = "Hard Hit Chance", Default = 50, Min = 0, Max = 100 },
            { Key = "HardEvasionChance", Label = "Hard Evasion", Default = 50, Min = 0, Max = 100 }
        ]
    }
];

::BBCA_EquipmentCatalog <- [
    {
        ID = "armor.body.bbca_regenerating_adorned_mail_shirt",
        Script = "scripts/items/armor/legendary/bbca_regenerating_adorned_mail_shirt",
        Type = "armor",
        Label = "自愈圣饰链甲衫",
        AppearanceSource = "scripts/items/armor/adorned_mail_shirt",
        RepairPerTurn = 90,
        ConditionMax = 270,
        StaminaModifier = -18
    },
    {
        ID = "armor.head.bbca_regenerating_heavy_mail_coif",
        Script = "scripts/items/helmets/legendary/bbca_regenerating_heavy_mail_coif",
        Type = "helmet",
        Label = "自愈重型链甲头罩",
        AppearanceSource = "scripts/items/helmets/heavy_mail_coif",
        RepairPerTurn = 90,
        ConditionMax = 270,
        StaminaModifier = -10
    }
];

::mods_registerMod("mod_bb_custom_appearance", 0.1, "Custom Appearance");

::mods_queue("mod_bb_custom_appearance", "mod_breditor", function() {
    ::mods_hookNewObjectOnce("ui/screens/world/world_breditor_screen", function(o) {
        local bbca_originalPrepareNI = o.prepareNI;
        o.prepareNI = function()
        {
            local result = bbca_originalPrepareNI.call(this);
            local legendary = result.Items.Legendary.List;
            foreach (definition in ::BBCA_EquipmentCatalog)
            {
                if (legendary.find(definition.Script) == null)
                {
                    legendary.insert(0, definition.Script);
                }
            }
            return result;
        };

        o.getCustomAppearanceCatalog <- function()
        {
            return ::BBCA_Catalog;
        };

        o.getCustomAppearance <- function(_result)
        {
            foreach (bro in this.World.getPlayerRoster().getAll())
            {
                if (bro.getID() == _result.BroId)
                {
                    return {
                        BroId = bro.getID(),
                        ImagePath = bro.getImagePath(),
                        Appearance = this.bbca_getAppearance(bro)
                    };
                }
            }

            return null;
        };

        o.applyCustomAppearance <- function(_result)
        {
            if (_result == null || !("BroId" in _result) || !("Role" in _result) || !("BrushId" in _result))
            {
                return { Error = "Invalid appearance request." };
            }

            local isNoBeard = _result.Role == "beard" && _result.BrushId == "";
            if (!isNoBeard && !this.bbca_isCatalogBrush(_result.Role, _result.BrushId))
            {
                return { Error = "The selected brush is not in the custom appearance catalog." };
            }

            foreach (bro in this.World.getPlayerRoster().getAll())
            {
                if (bro.getID() != _result.BroId)
                {
                    continue;
                }

                if (isNoBeard)
                {
                    if (bro.getSprite("beard").HasBrush)
                    {
                        bro.getSprite("beard").resetBrush();
                    }
                }
                else if (_result.Role == "body")
                {
                    bro.m.Body = _result.BrushId;
                    bro.getSprite("body").setBrush(_result.BrushId);
                }
                else
                {
                    bro.getSprite(_result.Role).setBrush(_result.BrushId);
                }

                if (_result.Role == "beard" && bro.getSprite("beard_top").HasBrush)
                {
                    bro.getSprite("beard_top").resetBrush();
                }

                bro.getSkills().update();
                return {
                    BroId = bro.getID(),
                    ImagePath = bro.getImagePath(),
                    Appearance = this.bbca_getAppearance(bro)
                };
            }

            return { Error = "Brother was not found in the player roster." };
        };

        o.getCustomSkillCatalog <- function()
        {
            return ::BBCA_SkillCatalog;
        };

        o.getCustomSkillState <- function(_result)
        {
            if (_result == null || !("BroId" in _result))
            {
                return { Error = "Invalid brother selection." };
            }

            local bro = this.bbca_findBrother(_result.BroId);
            if (bro == null)
            {
                return { Error = "Brother was not found in the player roster." };
            }

            local skills = [];
            foreach (definition in ::BBCA_SkillCatalog)
            {
                local container = bro.getSkills();
                local hasSkill = container.hasSkill(definition.ID);
                local skill = hasSkill ? container.getSkillByID(definition.ID) : null;
                local config = ("ConfigID" in definition) ? container.getSkillByID(definition.ConfigID) : null;
                skills.push({
                    ID = definition.ID,
                    HasSkill = hasSkill,
                    Settings = this.bbca_getCustomSkillSettings(definition, config == null ? skill : config)
                });
            }

            return { BroId = bro.getID(), Skills = skills };
        };

        o.applyCustomSkill <- function(_result)
        {
            if (_result == null || !("BroId" in _result) || !("SkillId" in _result) || !("Settings" in _result))
            {
                return { Error = "Invalid skill request." };
            }

            local definition = this.bbca_getCustomSkillDefinition(_result.SkillId);
            if (definition == null)
            {
                return { Error = "The selected skill is not in the custom skill catalog." };
            }

            local bro = this.bbca_findBrother(_result.BroId);
            if (bro == null)
            {
                return { Error = "Brother was not found in the player roster." };
            }

            local settings = this.bbca_validateCustomSkillSettings(definition, _result.Settings);
            if ("Error" in settings)
            {
                return settings;
            }

            local container = bro.getSkills();
            local wasAlreadyGranted = container.hasSkill(definition.ID);
            local skill = wasAlreadyGranted ? container.getSkillByID(definition.ID) : null;
            local isNewSkill = skill == null;
            if (isNewSkill)
            {
                if (wasAlreadyGranted)
                {
                    container.removeByID(definition.ID);
                }
                skill = this.new(definition.Script);
                container.add(skill);
            }

            local config = null;
            if ("ConfigID" in definition && "ConfigScript" in definition)
            {
                config = container.getSkillByID(definition.ConfigID);
                if (config == null)
                {
                    config = this.new(definition.ConfigScript);
                    container.add(config);
                }
                foreach (parameter in definition.Parameters)
                {
                    config.m[parameter.Key] = settings[parameter.Key];
                }
            }

            if (config == null)
            {
                foreach (parameter in definition.Parameters)
                {
                    skill.m[parameter.Key] = settings[parameter.Key];
                }
            }

            if ("Cooldown" in skill.m && "Skillcool" in skill.m)
            {
                local configuredCooldown = "Cooldown" in settings ? settings.Cooldown : skill.m.Cooldown;
                if (isNewSkill)
                {
                    skill.m.Skillcool = configuredCooldown;
                }
                else if (skill.m.Skillcool > configuredCooldown)
                {
                    skill.m.Skillcool = configuredCooldown;
                }
            }

            container.update();

            return {
                BroId = bro.getID(),
                SkillId = definition.ID,
                HasSkill = true,
                WasAlreadyGranted = wasAlreadyGranted,
                Settings = this.bbca_getCustomSkillSettings(definition, config == null ? skill : config)
            };
        };

        o.bbca_findBrother <- function(_broId)
        {
            foreach (bro in this.World.getPlayerRoster().getAll())
            {
                if (bro.getID() == _broId)
                {
                    return bro;
                }
            }
            return null;
        };

        o.bbca_getCustomSkillDefinition <- function(_skillId)
        {
            foreach (definition in ::BBCA_SkillCatalog)
            {
                if (definition.ID == _skillId)
                {
                    return definition;
                }
            }
            return null;
        };

        o.bbca_getCustomSkillSettings <- function(_definition, _skill)
        {
            local settings = {};
            foreach (parameter in _definition.Parameters)
            {
                settings[parameter.Key] <- _skill == null || !(parameter.Key in _skill.m) ? parameter.Default : _skill.m[parameter.Key];
            }
            return settings;
        };

        o.bbca_validateCustomSkillSettings <- function(_definition, _requestedSettings)
        {
            local settings = {};
            foreach (parameter in _definition.Parameters)
            {
                if (!(parameter.Key in _requestedSettings))
                {
                    return { Error = "Missing value for " + parameter.Key + "." };
                }

                local rawValue = _requestedSettings[parameter.Key];
                if ("Type" in parameter && parameter.Type == "bool")
                {
                    if (typeof rawValue != "bool")
                    {
                        return { Error = "Invalid value for " + parameter.Key + "." };
                    }
                    settings[parameter.Key] <- rawValue;
                    continue;
                }
                if (typeof rawValue != "integer" && typeof rawValue != "float")
                {
                    return { Error = "Invalid value for " + parameter.Key + "." };
                }

                local value = rawValue.tointeger();
                if (value < parameter.Min || value > parameter.Max)
                {
                    return { Error = parameter.Key + " must be between " + parameter.Min + " and " + parameter.Max + "." };
                }
                settings[parameter.Key] <- value;
            }

            if ("MinRange" in settings && "MaxRange" in settings && settings.MinRange > settings.MaxRange)
            {
                return { Error = "MinRange cannot exceed MaxRange." };
            }
            return settings;
        };

        o.bbca_getAppearance <- function(_bro)
        {
            local result = { };
            foreach (slot in ["body", "head", "hair", "beard", "tattoo_head", "tattoo_body"])
            {
                result[slot] <- _bro.getSprite(slot).HasBrush ? _bro.getSprite(slot).getBrush().Name : "";
            }
            return result;
        };

        o.bbca_isCatalogBrush <- function(_role, _brushId)
        {
            foreach (entry in ::BBCA_Catalog)
            {
                if (entry.Role == _role && entry.ID == _brushId)
                {
                    return true;
                }
            }
            return false;
        };
    });
});
