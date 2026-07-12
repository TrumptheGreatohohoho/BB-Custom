this.bbca_fire_grenade_config_skill <- this.inherit("scripts/skills/skill", {
    m = {
        ActionPointCost = 6,
        FatigueCost = 35,
        MinRange = 2,
        MaxRange = 4,
        MaxLevelDifference = 1,
        Cooldown = 7,
        FireDuration = 2,
        AreaRadius = 2
    },

    function create()
    {
        this.m.ID = "effects.bbca_fire_grenade_config";
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
        _out.writeI32(2);
        _out.writeI32(this.m.ActionPointCost);
        _out.writeI32(this.m.FatigueCost);
        _out.writeI32(this.m.MinRange);
        _out.writeI32(this.m.MaxRange);
        _out.writeI32(this.m.MaxLevelDifference);
        _out.writeI32(this.m.Cooldown);
        _out.writeI32(this.m.FireDuration);
        _out.writeI32(this.m.AreaRadius);
    }

    function onDeserialize( _in )
    {
        this.skill.onDeserialize(_in);
        local version = _in.readI32();
        if (version >= 1)
        {
            this.m.ActionPointCost = _in.readI32();
            this.m.FatigueCost = _in.readI32();
            this.m.MinRange = _in.readI32();
            this.m.MaxRange = _in.readI32();
            this.m.MaxLevelDifference = _in.readI32();
            this.m.Cooldown = _in.readI32();
            this.m.FireDuration = _in.readI32();
        }
        if (version >= 2)
        {
            this.m.AreaRadius = _in.readI32();
        }
    }
});
