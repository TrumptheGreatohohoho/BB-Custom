this.bbca_negative_immunity_config_skill <- this.inherit("scripts/skills/skill", {
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
        this.m.ID = "effects.bbca_negative_immunity_config";
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
        _out.writeI32(6);
        this.bbca_writeBool(_out, this.m.ShowStatusIcon);
        this.bbca_writeBool(_out, this.m.ImmuneToPoison);
        this.bbca_writeBool(_out, this.m.ImmuneToBleeding);
        this.bbca_writeBool(_out, this.m.ImmuneToStun);
        this.bbca_writeBool(_out, this.m.ImmuneToDaze);
        this.bbca_writeBool(_out, this.m.ImmuneToRoot);
        this.bbca_writeBool(_out, this.m.ImmuneToKnockBackAndGrab);
        this.bbca_writeBool(_out, this.m.ImmuneToDisarm);
        this.bbca_writeBool(_out, this.m.ImmuneToRotation);
        this.bbca_writeBool(_out, this.m.ImmuneToFire);
        this.bbca_writeBool(_out, this.m.ImmuneToHeadshots);
        this.bbca_writeBool(_out, this.m.IgnoreInjuries);
        this.bbca_writeBool(_out, this.m.ImmuneToOverwhelmed);
        this.bbca_writeBool(_out, this.m.ImmuneToDistracted);
        this.bbca_writeBool(_out, this.m.ImmuneToSwallowWhole);
        this.bbca_writeBool(_out, this.m.StunPiercer);
        this.bbca_writeBool(_out, this.m.PassiveCounterattack);
    }

    function onDeserialize( _in )
    {
        this.skill.onDeserialize(_in);
        local version = _in.readI32();
        this.m.ShowStatusIcon = this.bbca_readBool(_in);
        this.m.ImmuneToPoison = this.bbca_readBool(_in);
        this.m.ImmuneToBleeding = this.bbca_readBool(_in);
        this.m.ImmuneToStun = this.bbca_readBool(_in);
        this.m.ImmuneToDaze = this.bbca_readBool(_in);
        this.m.ImmuneToRoot = this.bbca_readBool(_in);
        this.m.ImmuneToKnockBackAndGrab = this.bbca_readBool(_in);
        this.m.ImmuneToDisarm = this.bbca_readBool(_in);
        this.m.ImmuneToRotation = this.bbca_readBool(_in);
        this.m.ImmuneToFire = this.bbca_readBool(_in);
        this.m.ImmuneToHeadshots = this.bbca_readBool(_in);
        this.m.IgnoreInjuries = this.bbca_readBool(_in);
        if (version >= 2)
        {
            this.m.ImmuneToOverwhelmed = this.bbca_readBool(_in);
        }
        if (version >= 3)
        {
            this.m.ImmuneToDistracted = this.bbca_readBool(_in);
        }
        if (version >= 4)
        {
            this.m.ImmuneToSwallowWhole = this.bbca_readBool(_in);
        }
        if (version >= 5)
        {
            this.m.StunPiercer = this.bbca_readBool(_in);
        }
        if (version >= 6)
        {
            this.m.PassiveCounterattack = this.bbca_readBool(_in);
        }
    }
});

