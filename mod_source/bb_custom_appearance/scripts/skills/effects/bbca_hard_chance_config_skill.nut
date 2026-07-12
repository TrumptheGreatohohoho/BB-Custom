this.bbca_hard_chance_config_skill <- this.inherit("scripts/skills/skill", {
    m = {
        ShowStatusIcon = false,
        HardHitChance = 50,
        HardEvasionChance = 50
    },

    function create()
    {
        this.m.ID = "effects.bbca_hard_chance_config";
        this.m.Type = this.Const.SkillType.StatusEffect;
        this.m.IsActive = false;
        this.m.IsAttack = false;
        this.m.IsStacking = false;
        this.m.IsSerialized = true;
        this.m.IsHidden = true;
    }

    function bbca_writeBool( _out, _value )
    {
        _out.writeU8(_value ? 1 : 0);
    }

    function bbca_readBool( _in )
    {
        return _in.readU8() != 0;
    }

    function onSerialize( _out )
    {
        this.skill.onSerialize(_out);
        _out.writeI32(1);
        this.bbca_writeBool(_out, this.m.ShowStatusIcon);
        _out.writeI32(this.m.HardHitChance);
        _out.writeI32(this.m.HardEvasionChance);
    }

    function onDeserialize( _in )
    {
        this.skill.onDeserialize(_in);
        local version = _in.readI32();

        if (version >= 1)
        {
            this.m.ShowStatusIcon = this.bbca_readBool(_in);
            this.m.HardHitChance = _in.readI32();
            this.m.HardEvasionChance = _in.readI32();
        }
    }
});

