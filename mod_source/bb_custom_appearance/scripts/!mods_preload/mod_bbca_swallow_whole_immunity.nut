// Optional immunity to the vanilla Nachzehrer "Swallow Whole" skill.
// The hook extends the skill's real target-validity gate, which is consulted by
// both AI target selection and skill.use() before AP/fatigue are spent.

::mods_hookClass("skills/actives/swallow_whole_skill", function(o) {
    o.bbca_isTargetImmuneToSwallowWhole <- function( _targetTile )
    {
        if (_targetTile == null || !_targetTile.IsOccupiedByActor)
        {
            return false;
        }

        local target = _targetTile.getEntity();
        if (target == null)
        {
            return false;
        }

        local container = target.getSkills();
        if (container == null)
        {
            return false;
        }

        local aegis = container.getSkillByID("effects.bbca_negative_immunity");
        if (aegis == null || !("bbca_getBool" in aegis))
        {
            return false;
        }

        return aegis.bbca_getBool("ImmuneToSwallowWhole", false);
    }

    local bbca_origOnVerifyTarget = o.onVerifyTarget;
    o.onVerifyTarget = function( _originTile, _targetTile )
    {
        if (!bbca_origOnVerifyTarget.call(this, _originTile, _targetTile))
        {
            return false;
        }

        return !this.bbca_isTargetImmuneToSwallowWhole(_targetTile);
    }
});
