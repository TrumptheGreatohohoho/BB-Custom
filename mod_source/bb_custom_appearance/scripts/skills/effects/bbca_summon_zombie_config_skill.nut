this.bbca_summon_zombie_config_skill <- this.inherit("scripts/skills/skill", {
    m = {
        ActionPointCost = 6,
        FatigueCost = 25,
        MaxRange = 3,
        MaxLevelDifference = 1,
        Cooldown = 5,
        MaxActiveSummons = 3
    },

    function create()
    {
        this.m.ID = "effects.bbca_summon_zombie_config";
        this.m.Type = this.Const.SkillType.StatusEffect;
        this.m.IsActive = false;
        this.m.IsAttack = false;
        this.m.IsStacking = false;
        this.m.IsSerialized = true;
        this.m.IsHidden = true;
    }

    function onSerialize( _out )
    {
        this.skill.onSerialize(_out);
        _out.writeI32(1);
        _out.writeI32(this.m.ActionPointCost);
        _out.writeI32(this.m.FatigueCost);
        _out.writeI32(this.m.MaxRange);
        _out.writeI32(this.m.MaxLevelDifference);
        _out.writeI32(this.m.Cooldown);
        _out.writeI32(this.m.MaxActiveSummons);
    }

    function onDeserialize( _in )
    {
        this.skill.onDeserialize(_in);
        local version = _in.readI32();
        if (version >= 1)
        {
            this.m.ActionPointCost = _in.readI32();
            this.m.FatigueCost = _in.readI32();
            this.m.MaxRange = _in.readI32();
            this.m.MaxLevelDifference = _in.readI32();
            this.m.Cooldown = _in.readI32();
            this.m.MaxActiveSummons = _in.readI32();
        }
    }
});
