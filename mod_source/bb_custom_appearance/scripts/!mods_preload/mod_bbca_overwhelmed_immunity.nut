// Optional immunity to the vanilla "Overwhelmed" effect (effects.overwhelmed) — the
// stacking surround penalty that lowers Melee/Ranged Skill by 10% per stack toward zero.
// Gated per-brother by Aegis (effects.bbca_negative_immunity) via its ImmuneToOverwhelmed
// flag. Ships inside mod_bb_custom_appearance.zip; needs no separate runtime archive.

::mods_hookClass("skills/effects/overwhelmed_effect", function(o) {
    o.bbca_isOverwhelmImmune <- function()
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
        return aegis.bbca_getBool("ImmuneToOverwhelmed", false);
    }

    local bbca_origOnUpdate = o.onUpdate;
    o.onUpdate = function( _properties )
    {
        if (this.bbca_isOverwhelmImmune())
        {
            // Immune: skip the Melee/Ranged Skill reduction and keep the icon hidden.
            this.m.IsHidden = true;
            return;
        }
        bbca_origOnUpdate.call(this, _properties);
    }

    local bbca_origOnRefresh = o.onRefresh;
    o.onRefresh = function()
    {
        if (this.bbca_isOverwhelmImmune())
        {
            // Immune: do not accumulate stacks or spawn the floating icon.
            return;
        }
        bbca_origOnRefresh.call(this);
    }
});
