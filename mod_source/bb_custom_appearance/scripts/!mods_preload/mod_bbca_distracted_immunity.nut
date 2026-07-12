// Optional immunity to the vanilla "Distracted" effect (effects.distracted) — the
// "dirty trick" debuff that cuts the target's Damage and Initiative by 35% for a turn.
// Gated per-brother by Aegis (effects.bbca_negative_immunity) via its ImmuneToDistracted
// flag. Ships inside mod_bb_custom_appearance.zip; needs no separate runtime archive.

::mods_hookClass("skills/effects/distracted_effect", function(o) {
    o.bbca_isDistractImmune <- function()
    {
        local container = this.getContainer();
        if (container == null)
        {
            return false;
        }
        local aegis = container.getSkillByID("effects.bbca_negative_immunity");
        if (aegis == null || !("bbca_getBool" in aegis))
        {
            return false;
        }
        return aegis.bbca_getBool("ImmuneToDistracted", false);
    }

    local bbca_origOnAdded = o.onAdded;
    o.onAdded = function()
    {
        if (this.bbca_isDistractImmune())
        {
            // Immune: drop the effect immediately, exactly like the vanilla resist path.
            this.removeSelf();
            return;
        }
        bbca_origOnAdded.call(this);
    }

    local bbca_origOnUpdate = o.onUpdate;
    o.onUpdate = function( _properties )
    {
        if (this.bbca_isDistractImmune())
        {
            // Safety net if the effect somehow persists: skip the damage/initiative cut.
            this.m.IsHidden = true;
            return;
        }
        bbca_origOnUpdate.call(this, _properties);
    }
});
