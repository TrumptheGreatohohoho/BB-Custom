this.bbca_shadowwalk_config_skill <- this.inherit("scripts/skills/skill", {
    m = {
        ActionPointCost = 4,
        FatigueCost = 30,
        MinRange = 1,
        MaxRange = 6,
        MaxLevelDifference = 1,
        Cooldown = 9,
        AllowWhileEngaged = true,
        AllowWhileRooted = true
    },

    function create()
    {
        this.m.ID = "effects.bbca_shadowwalk_config";
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
        _out.writeI32(this.m.ActionPointCost);
        _out.writeI32(this.m.FatigueCost);
        _out.writeI32(this.m.MinRange);
        _out.writeI32(this.m.MaxRange);
        _out.writeI32(this.m.MaxLevelDifference);
        _out.writeI32(this.m.Cooldown);
        _out.writeU8(this.m.AllowWhileEngaged ? 1 : 0);
        _out.writeU8(this.m.AllowWhileRooted ? 1 : 0);
    }

    function onDeserialize( _in )
    {
        this.skill.onDeserialize(_in);
        this.m.ActionPointCost = _in.readI32();
        this.m.FatigueCost = _in.readI32();
        this.m.MinRange = _in.readI32();
        this.m.MaxRange = _in.readI32();
        this.m.MaxLevelDifference = _in.readI32();
        this.m.Cooldown = _in.readI32();
        this.m.AllowWhileEngaged = _in.readU8() != 0;
        this.m.AllowWhileRooted = _in.readU8() != 0;
    }
});
